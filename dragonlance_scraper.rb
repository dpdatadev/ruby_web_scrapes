#!/usr/bin/env ruby
# frozen_string_literal: true

# Dragonlance Wiki browser for the command line.
# Same idea as the WoT scraper: talk to the Fandom MediaWiki API, pull the
# parsed HTML for a page, then use Nokogiri for the summary and infobox.
#
# Usage:
#   ruby dragonlance_scraper.rb                       # interactive mode
#   ruby dragonlance_scraper.rb page "Raistlin Majere"
#   ruby dragonlance_scraper.rb search "Tower of High Sorcery"
#   ruby dragonlance_scraper.rb categories Dragon      # find category names
#   ruby dragonlance_scraper.rb list Characters 20     # list a category's pages
#   ruby dragonlance_scraper.rb dump Characters 5      # JSON dump, like the WoT script
#   ruby dragonlance_scraper.rb random
#
# Requires: gem install nokogiri

require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'

class DragonlanceApiScraper
  BASE_URL   = 'https://dragonlance.fandom.com/api.php'
  WIKI_URL   = 'https://dragonlance.fandom.com/wiki/'
  USER_AGENT = 'DragonlanceCLI/1.0 (personal command-line browser)'
  DELAY      = 0.5 # seconds between API calls, to be polite

  # 1. Fetch page data: summary, infobox, categories, sections
  def get_page_data(title)
    response = make_request(
      action: 'parse',
      page: title,
      prop: 'text|categories|sections',
      redirects: true
    )
    return nil unless response && response['parse']

    parse = response['parse']
    doc = Nokogiri::HTML(parse['text']['*'])

    {
      title: parse['title'],
      url: WIKI_URL + URI.encode_www_form_component(parse['title'].tr(' ', '_')),
      summary: extract_summary(doc),
      infobox: extract_infobox(doc),
      sections: parse['sections'].map { |s| s['line'] },
      # Fandom tags maintenance categories as hidden; leave those out
      categories: parse['categories'].reject { |c| c.key?('hidden') }.map { |c| c['*'] }
    }
  end

  # 2. Fetch members of a category, following pagination past 500
  def get_category_members(category_name, limit = 50)
    members = []
    params = {
      action: 'query',
      list: 'categorymembers',
      cmtitle: "Category:#{category_name.sub(/\ACategory:/i, '')}",
      cmnamespace: 0, # articles only, skip subcategories/files/templates
      cmlimit: [limit, 500].min
    }

    loop do
      response = make_request(params)
      break unless response && response['query']

      members.concat(response['query']['categorymembers'].map { |m| m['title'] })
      break if members.size >= limit || !response['continue']

      params = params.merge(cmcontinue: response['continue']['cmcontinue'])
      sleep DELAY
    end

    members.first(limit)
  end

  # 3. Full-text search across the wiki
  def search(query, limit = 10)
    response = make_request(action: 'query', list: 'search', srsearch: query, srlimit: limit)
    return [] unless response && response['query']

    response['query']['search'].map do |r|
      { title: r['title'], snippet: Nokogiri::HTML(r['snippet']).text.strip }
    end
  end

  # 4. Discover category names (handy since every wiki names them differently)
  def find_categories(prefix = nil, limit = 50)
    params = { action: 'query', list: 'allcategories', aclimit: limit, acprop: 'size', acmin: 1 }
    params[:acprefix] = prefix if prefix && !prefix.empty?

    response = make_request(params)
    return [] unless response && response['query']

    response['query']['allcategories']
      .map { |c| { name: c['*'], pages: c['pages'] } }
      .sort_by { |c| -c[:pages] }
  end

  # 5. A random article, for wandering around Krynn
  def random_page
    response = make_request(action: 'query', list: 'random', rnnamespace: 0, rnlimit: 1)
    response && response.dig('query', 'random', 0, 'title')
  end

  # Main entry point for dumping info on a category (same as the WoT version)
  def dump_info_on(category, count = 3)
    puts "Fetching list of #{category} from the API..."
    titles = get_category_members(category, count)

    results = titles.map do |title|
      puts "Retrieving API data for: #{title}"
      data = get_page_data(title)
      sleep DELAY
      data
    end.compact

    puts JSON.pretty_generate(results)
  end

  private

  def make_request(params)
    url = URI(BASE_URL)
    url.query = URI.encode_www_form(params.merge(format: 'json'))

    request = Net::HTTP::Get.new(url)
    request['User-Agent'] = USER_AGENT

    response = Net::HTTP.start(url.host, url.port, use_ssl: true,
                               open_timeout: 10, read_timeout: 20) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      warn "API Error: HTTP #{response.code}"
      return nil
    end

    json = JSON.parse(response.body)
    if json['error']
      warn "API Error: #{json['error']['info']}"
      return nil
    end
    json
  rescue StandardError => e
    warn "API Error: #{e.message}"
    nil
  end

  def extract_summary(doc)
    # First two real paragraphs of the article body (skip empty/infobox ones)
    doc.css('.mw-parser-output > p')
       .map { |p| clean(p.text) }
       .reject(&:empty?)
       .first(2)
       .join("\n\n")
  end

  def extract_infobox(doc)
    data = {}

    # Modern Fandom "portable" infobox
    doc.css('.portable-infobox .pi-item.pi-data').each do |item|
      label = item.at_css('.pi-data-label')&.text&.strip&.delete_suffix(':')
      value = item.at_css('.pi-data-value')
      data[label] = infobox_value(value) if label && value
    end

    # Fallback: older table-style infoboxes
    if data.empty?
      doc.css('table.infobox tr').each do |row|
        label = row.at_css('th')&.text&.strip&.delete_suffix(':')
        value = row.at_css('td')
        data[label] = infobox_value(value) if label && value && !label.empty?
      end
    end

    data
  end

  # Keep line breaks inside multi-value fields (e.g. several aliases) readable
  def infobox_value(node)
    node.css('br').each { |br| br.replace(', ') }
    node.css('li').each { |li| li.add_next_sibling(', ') }
    clean(node.text).sub(/,\s*\z/, '').gsub(/(,\s*){2,}/, ', ')
  end

  def clean(text)
    text.gsub(/\[\d+\]/, '').gsub(/[ \t]+/, ' ').strip
  end
end

# ---------------------------------------------------------------------------
# Command-line browser
# ---------------------------------------------------------------------------
class DragonlanceCLI
  WIDTH = 80

  def initialize(scraper = DragonlanceApiScraper.new)
    @scraper = scraper
    @last_results = [] # numbered list from the last search/list, for "open N"
  end

  def run(argv)
    return interactive if argv.empty?

    command, *args = argv
    dispatch(command, args.join(' '))
  end

  private

  def dispatch(command, arg)
    case command.downcase
    when 'page', 'p', 'open', 'o' then show_page(resolve(arg))
    when 'search', 's'            then show_search(arg)
    when 'categories', 'cats', 'c' then show_categories(arg)
    when 'list', 'l'              then show_list(arg)
    when 'dump', 'd'              then dump(arg)
    when 'random', 'r'            then show_page(@scraper.random_page)
    when 'help', 'h', '?'         then help
    else
      # Anything unrecognised is treated as a page title
      show_page([command, arg].reject(&:empty?).join(' '))
    end
  end

  def interactive
    puts banner
    help
    loop do
      print "\ndragonlance> "
      line = $stdin.gets
      break if line.nil?

      line = line.strip
      next if line.empty?
      break if %w[quit exit q].include?(line.downcase)

      command, arg = line.split(' ', 2)
      dispatch(command, arg.to_s)
    end
    puts 'Farewell, traveler. May Paladine watch over you.'
  end

  # "open 3" picks the 3rd item from the last search or list
  def resolve(arg)
    if arg =~ /\A\d+\z/ && @last_results[arg.to_i - 1]
      @last_results[arg.to_i - 1]
    else
      arg
    end
  end

  def show_page(title)
    return puts('Give a page title, e.g.: page Raistlin Majere') if title.nil? || title.empty?

    data = @scraper.get_page_data(title)
    unless data
      puts "No page found for \"#{title}\". Try: search #{title}"
      return
    end

    puts rule('=')
    puts data[:title].upcase
    puts data[:url]
    puts rule('=')

    unless data[:infobox].empty?
      pad = data[:infobox].keys.map(&:length).max
      data[:infobox].each { |k, v| puts "  #{k.ljust(pad)} : #{v}" }
      puts rule
    end

    puts wrap(data[:summary].empty? ? '(No summary text found.)' : data[:summary])

    unless data[:sections].empty?
      puts rule
      puts "Sections: #{data[:sections].join(' | ')}"
    end
    unless data[:categories].empty?
      puts "Categories: #{data[:categories].map { |c| c.tr('_', ' ') }.join(', ')}"
    end
  end

  def show_search(query)
    return puts('Usage: search <words>') if query.empty?

    results = @scraper.search(query)
    return puts("Nothing found for \"#{query}\".") if results.empty?

    @last_results = results.map { |r| r[:title] }
    results.each_with_index do |r, i|
      puts "#{(i + 1).to_s.rjust(2)}. #{r[:title]}"
      puts "    #{r[:snippet][0, WIDTH - 4]}..." unless r[:snippet].empty?
    end
    puts "\nType 'open <number>' to read one."
  end

  def show_categories(prefix)
    cats = @scraper.find_categories(prefix.empty? ? nil : prefix)
    return puts("No categories found#{" starting with \"#{prefix}\"" unless prefix.empty?}.") if cats.empty?

    cats.each { |c| puts "  #{c[:name].ljust(45)} #{c[:pages]} pages" }
    puts "\nType 'list <category>' to see its pages."
  end

  def show_list(arg)
    category, count = split_count(arg, 25)
    return puts('Usage: list <category> [count]') if category.empty?

    titles = @scraper.get_category_members(category, count)
    if titles.empty?
      puts "No pages in Category:#{category}. Try: categories #{category.split.first}"
      return
    end

    @last_results = titles
    titles.each_with_index { |t, i| puts "#{(i + 1).to_s.rjust(3)}. #{t}" }
    puts "\nType 'open <number>' to read one."
  end

  def dump(arg)
    category, count = split_count(arg, 3)
    return puts('Usage: dump <category> [count]') if category.empty?

    @scraper.dump_info_on(category, count)
  end

  # "Characters 10" -> ["Characters", 10]; multi-word categories still work
  def split_count(arg, default)
    words = arg.split
    if words.last =~ /\A\d+\z/
      [words[0..-2].join(' '), words.last.to_i]
    else
      [arg.strip, default]
    end
  end

  def help
    puts <<~HELP
      Commands:
        page <title>           Show a page (or just type the title)
        search <words>         Full-text search the wiki
        open <n>               Open result n from the last search/list
        categories [prefix]    Find category names (e.g. categories Dragon)
        list <category> [n]    List pages in a category
        dump <category> [n]    JSON dump of n pages, like the WoT script
        random                 A random page
        help / quit
    HELP
  end

  def banner
    <<~ART
      #{rule('=')}
        DRAGONLANCE WIKI BROWSER  -  dragonlance.fandom.com
      #{rule('=')}
    ART
  end

  def rule(char = '-')
    char * WIDTH
  end

  def wrap(text)
    text.split("\n\n").map do |para|
      para.gsub(/(.{1,#{WIDTH}})(\s+|\z)/, "\\1\n").rstrip
    end.join("\n\n")
  end
end

DragonlanceCLI.new.run(ARGV) if $PROGRAM_NAME == __FILE__
