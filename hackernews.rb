require 'net/http'
require 'json'
require 'uri'
require 'time' # For parsing timestamps

# Base URL for the Hacker News API
BASE_API_URL = 'https://hacker-news.firebaseio.com/v0/'

# Function to fetch JSON from a given API endpoint
def fetch_json(endpoint)
  uri = URI.parse("#{BASE_API_URL}#{endpoint}")
  response = Net::HTTP.get_response(uri)

  unless response.is_a?(Net::HTTPSuccess)
    puts "Error fetching #{uri}: #{response.code} #{response.message}"
    return nil
  end

  JSON.parse(response.body)
rescue JSON::ParserError => e
  puts "Error parsing JSON from #{uri}: #{e.message}"
  nil
rescue StandardError => e
  puts "An unexpected error occurred while fetching #{uri}: #{e.message}"
  nil
end

# Function to scrape and display Hacker News stories
def scrape_hacker_news(num_stories = 20)
  puts "Fetching top story IDs from Hacker News API..."
  top_story_ids = fetch_json('topstories.json')

  unless top_story_ids
    puts "Could not retrieve top story IDs. Exiting."
    return
  end

  puts "Found #{top_story_ids.length} top stories. Fetching details for the first #{num_stories}..."

  stories = []
  # Iterate through the first 'num_stories' IDs
  top_story_ids.first(num_stories).each_with_index do |id, index|
    puts "  Fetching story #{index + 1}/#{num_stories} (ID: #{id})..."
    story_data = fetch_json("item/#{id}.json")

    if story_data && story_data['type'] == 'story'
      stories << story_data
    elsif story_data
      puts "    Skipping item ID #{id} as it's not a 'story' type (it's a '#{story_data['type']}')."
    else
      puts "    Could not retrieve details for story ID #{id}."
    end
    # Be polite to the API
    sleep(0.1)
  end

  display_stories(stories)
end

# Function to display the scraped stories
def display_stories(stories)
  puts "\n--- Hacker News Top Stories ---"
  if stories.empty?
    puts "No stories found or retrieved."
    return
  end

  stories.each_with_index do |story, index|
    # Safely access fields, providing default values if they are nil or missing.
    # This is crucial to prevent the 'comparison of Integer with Hash failed' error
    # or similar errors if a field is unexpectedly nil or not an integer.
    title = story['title'] || '[No Title]'
    url = story['url'] || "https://news.ycombinator.com/item?id=#{story['id']}" # Link to HN comments if no external URL
    score = story['score'].to_i # Convert to integer, defaults to 0 if nil/non-numeric
    by = story['by'] || '[unknown]'
    time = story['time'] ? Time.at(story['time']).strftime('%Y-%m-%d %H:%M:%S') : '[unknown time]'
    comments = story['descendants'].to_i # Convert to integer, defaults to 0 if nil/non-numeric

    puts "\n#{index + 1}. #{title}"
    puts "   URL: #{url}"
    puts "   Points: #{score}"
    puts "   Author: #{by}"
    puts "   Posted: #{time}"
    puts "   Comments: #{comments}"
  end
  puts "\n-----------------------------"
end

# Main execution block
if __FILE__ == $0
  num_stories_to_scrape = ARGV[0] ? ARGV[0].to_i : 20

  if num_stories_to_scrape <= 0
    puts "Please provide a positive number of stories to scrape."
  else
    scrape_hacker_news(num_stories_to_scrape)
  end
end