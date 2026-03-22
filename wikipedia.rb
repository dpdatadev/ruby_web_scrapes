require 'open-uri'
require 'nokogiri'
require 'uri'
require 'json' # For pretty printing output

class WikipediaScraper
  attr_reader :language, :base_url

  def initialize(language: 'en')
    @language = language
    @base_url = "https://#{language}.wikipedia.org/wiki/"
  end

  # Scrapes a Wikipedia page by its title
  # @param page_title [String] The title of the Wikipedia page (e.g., "Ruby_(programming_language)")
  # @return [Hash, nil] A hash containing the scraped data, or nil if the page couldn't be found
  def scrape_page(page_title)
    encoded_title = URI.encode_www_form_component(page_title.gsub(' ', '_'))
    full_url = "#{base_url}#{encoded_title}"

    puts "Attempting to scrape: #{full_url}"

    begin
      html = URI.parse(full_url).open
      doc = Nokogiri::HTML(html)

      data = {
        url: full_url,
        title: extract_title(doc),
        intro_content: extract_intro_content(doc),
        infobox: extract_infobox(doc),
        links: extract_links(doc),
        categories: extract_categories(doc)
      }

      puts "Successfully scraped '#{data[:title]}'"
      data
    rescue OpenURI::HTTPError => e
      puts "Error fetching page '#{page_title}': #{e.message}"
      puts "URL attempted: #{full_url}"
      nil
    rescue StandardError => e
      puts "An unexpected error occurred for '#{page_title}': #{e.message}"
      puts e.backtrace.join("\n")
      nil
    end
  end

  private

  # Extracts the main title of the page
  def extract_title(doc)
    doc.at_css('#firstHeading')&.text&.strip
  end

  # Extracts the introductory paragraphs before the first major heading or table of contents
  def extract_intro_content(doc)
    content_paragraphs = []
    # Wikipedia's main content is usually within #mw-content-text > .mw-parser-output
    parser_output = doc.at_css('.mw-parser-output')

    return [] unless parser_output

    parser_output.children.each do |node|
      # Stop if we hit a major heading or the table of contents
      break if node.name == 'h2' || node['id'] == 'toc' || node.matches?('.mw-disambig')

      if node.name == 'p'
        text = node.text.strip
        # Exclude common disambiguation/hatnote messages
        unless text.empty? || text.start_with?("This article is about") || text.start_with?("For other uses")
          content_paragraphs << text
        end
      end
    end
    content_paragraphs.join("\n\n")
  end

  # Extracts data from the infobox (if present)
  def extract_infobox(doc)
    infobox_data = {}
    infobox_table = doc.at_css('table.infobox')

    return infobox_data unless infobox_table

    infobox_table.css('tr').each do |row|
      header = row.at_css('th')
      data = row.at_css('td')

      if header && data
        key = header.text.strip.gsub(/[\u0080-\uFFFF]/, '').gsub(/\[.*?\]/, '').strip # Remove non-ASCII and [edit] tags
        value = data.text.strip.gsub(/[\u0080-\uFFFF]/, '').gsub(/\[.*?\]/, '').strip
        infobox_data[key] = value unless key.empty?
      elsif header && !data # Sometimes a header might be a standalone item (e.g., "Part of a series on...")
        key = header.text.strip.gsub(/[\u0080-\uFFFF]/, '').gsub(/\[.*?\]/, '').strip
        infobox_data[key] = true unless key.empty? # Indicate presence
      end
    end
    infobox_data
  end

  # Extracts internal Wikipedia links from the main content area
  def extract_links(doc)
    links = []
    # Target links within the main content area that point to other wiki pages
    doc.css('#mw-content-text a[href^="/wiki/"]').each do |link|
      href = link['href']
      # Exclude links to special pages, files, categories, etc.
      unless href.include?(':') || href.include?('#') || href.end_with?('(disambiguation)')
        # Get the title attribute if available, otherwise use the link text
        link_text = link['title'] || link.text
        links << { text: link_text.strip, href: href }
      end
    end
    links.uniq { |l| l[:href] } # Remove duplicate links based on href
  end

  # Extracts categories associated with the page
  def extract_categories(doc)
    categories = []
    doc.css('#mw-normal-catlinks ul li a').each do |category_link|
      categories << category_link.text.strip
    end
    categories.uniq
  end
end


# --- Example Usage ---
if __FILE__ == $0
  scraper = WikipediaScraper.new(language: 'en')

  puts "--- Scraping 'Ruby (programming language)' ---"
  ruby_page = scraper.scrape_page("Ruby (programming language)")
  if ruby_page
    puts JSON.pretty_generate(ruby_page)
  end

  puts "\n--- Scraping 'Artificial intelligence' ---"
  ai_page = scraper.scrape_page("Artificial intelligence")
  if ai_page
    puts JSON.pretty_generate(ai_page)
  end

  puts "\n--- Scraping 'Computer Science' ---"
  ai_page = scraper.scrape_page("Computer Science")
  if ai_page
    puts JSON.pretty_generate(ai_page)
  end

  puts "\n--- Scraping 'Calculus' (Calculus Wikipedia) ---"
  ai_page = scraper.scrape_page("Computer Science")
  if ai_page
    puts JSON.pretty_generate(ai_page)
  end
end