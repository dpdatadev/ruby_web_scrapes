require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'

class WotApiScraper
  BASE_URL = "https://wot.fandom.com/api.php"

  # 1. Fetch basic page data and intro text
  def get_page_data(title)
    params = {
      action: 'parse',
      page: title,
      format: 'json',
      prop: 'text|categories|links',
      redirects: true
    }
    
    response = make_request(params)
    return nil unless response && response['parse']

    html_content = response['parse']['text']['*']
    doc = Nokogiri::HTML(html_content)

    {
      title: response['parse']['title'],
      url: "https://wot.fandom.com/wiki/#{response['parse']['title'].gsub(' ', '_')}",
      summary: extract_summary(doc),
      infobox: extract_infobox(doc),
      categories: response['parse']['categories'].map { |c| c['*'] }
    }
  end

  # 2. Fetch all members of a category (e.g., "Category:Characters")
  def get_category_members(category_name)
    params = {
      action: 'query',
      list: 'categorymembers',
      cmtitle: "Category:#{category_name}",
      cmlimit: 50, # Max 500
      format: 'json'
    }

    response = make_request(params)
    return [] unless response && response['query']

    response['query']['categorymembers'].map { |m| m['title'] }
  end

  private

  def make_request(params)
    url = URI(BASE_URL)
    url.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(url) #TODO, replace with HTTParty
    JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
  rescue => e
    puts "API Error: #{e.message}"
    nil
  end

  def extract_summary(doc)
    # The API returns the full HTML, we still use Nokogiri to grab the first <p>
    doc.css('p').first(2).map { |p| p.text.gsub(/\[\d+\]/, '').strip }.join("\n\n")
  end

  #The API returns full HTML here
  def extract_infobox(doc)
    data = {}
    doc.css('.portable-infobox .pi-item.pi-data').each do |item|
      label = item.at_css('.pi-data-label')&.text&.strip&.delete_suffix(':')
      value = item.at_css('.pi-data-value')&.text&.strip&.gsub(/\[\d+\]/, '')
      data[label] = value if label
    end
    data
  end
end

# --- Execution ---
scraper = WotApiScraper.new
=begin 
Useful Category Names for WoT:
You can replace "Cities" in the script with these to get more data:
Characters
Major_Characters
Aes_Sedai
Countries
Unique_Objects (for keywords/artifacts like Angreal)
Old_Tongue_words (for keywords)
=end

# Step 1: Find titles in a category (e.g., aes_sedai in WoT)
puts "Fetching list of Aes Sedia..."
cities = scraper.get_category_members("Aes_Sedai")

# Step 2: Get detailed data for the first 3 aes_sedai found
results = cities.first(3).map do |aes_sedai|
  puts "Retrieving API data for: #{aes_sedai}"
  data = scraper.get_page_data(aes_sedai)
  sleep 0.5 # API safety delay
  data
end

puts JSON.pretty_generate(results)