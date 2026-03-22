Okay, let's create a Ruby script to scrape Hacker News.

We'll use two popular gems:
1.  **`httparty`**: For making HTTP requests to fetch the HTML content.
2.  **`nokogiri`**: For parsing the HTML and extracting the data using CSS selectors.

### Setup

First, make sure you have Ruby installed. Then, install the necessary gems:

```bash
gem install httparty nokogiri
```

### Ruby Script

```ruby
require 'httparty'
require 'nokogiri'

class HackerNewsScraper
  HN_URL = 'https://news.ycombinator.com/'

  def initialize(pages = 1)
    @pages = pages
    @stories = []
  end

  def scrape
    puts "Scraping Hacker News..."
    current_url = HN_URL
    page_count = 0

    while current_url && page_count < @pages
      puts "Fetching page: #{current_url}"
      response = HTTParty.get(current_url)
      doc = Nokogiri::HTML(response.body)

      parse_page(doc)

      # Find the "More" link for pagination
      more_link = doc.at_css('.morelink')
      if more_link && more_link['href']
        current_url = HN_URL + more_link['href']
        page_count += 1
      else
        current_url = nil # No more pages
      end
    end

    puts "Scraping complete. Found #{@stories.length} stories."
    @stories
  end

  private

  def parse_page(doc)
    # Hacker News stories are typically structured with a 'tr.athing' for the title
    # and a subsequent 'tr' for the subtext (score, author, comments).
    doc.css('tr.athing').each do |athing_row|
      story = {}

      # --- Extract Title and URL ---
      title_link = athing_row.at_css('.titleline a')
      next unless title_link # Skip if no title link (e.g., "more" link itself)

      story[:title] = title_link.text.strip
      story[:url] = title_link['href']

      # --- Extract Domain (optional) ---
      domain_span = athing_row.at_css('.titleline span.sitebit a span.sitestr')
      story[:domain] = domain_span.text.strip if domain_span

      # --- Extract Subtext (score, author, time, comments) ---
      # The subtext is in the next sibling 'tr' element
      subtext_row = athing_row.next_sibling
      if subtext_row && subtext_row.at_css('.subtext')
        # Score
        score_span = subtext_row.at_css('.score')
        story[:score] = score_span ? score_span.text.match(/(\d+)/)[1].to_i : 0

        # Author
        author_link = subtext_row.at_css('.hnuser')
        story[:author] = author_link.text.strip if author_link

        # Time
        time_span = subtext_row.at_css('.age a')
        story[:time_ago] = time_span.text.strip if time_span

        # Comments
        comments_link = subtext_row.css('a').find { |link| link.text.include?('comment') || link.text.include?('discuss') }
        if comments_link
          comment_match = comments_link.text.match(/(\d+)\s+(comment|comments)/)
          story[:comments_count] = comment_match ? comment_match[1].to_i : 0
          # Hacker News uses relative URLs for comments, so prepend the base URL
          story[:comments_url] = HN_URL + comments_link['href']
        else
          story[:comments_count] = 0
          story[:comments_url] = nil
        end
      end

      @stories << story
    end
  end
end

# --- How to use the scraper ---
if __FILE__ == $0
  # Create a scraper instance.
  # You can specify how many pages to scrape (e.g., 1 for just the front page, 2 for front page + "more").
  scraper = HackerNewsScraper.new(pages: 2) # Scrape the first 2 pages

  # Run the scraping process
  hn_stories = scraper.scrape

  # Display the results
  puts "\n--- Scraped Hacker News Stories ---"
  hn_stories.each_with_index do |story, index|
    puts "\n#{index + 1}. Title: #{story[:title]}"
    puts "   URL: #{story[:url]}"
    puts "   Domain: #{story[:domain]}" if story[:domain]
    puts "   Score: #{story[:score]} points"
    puts "   Author: #{story[:author]}" if story[:author]
    puts "   Time: #{story[:time_ago]}" if story[:time_ago]
    puts "   Comments: #{story[:comments_count]} (#{story[:comments_url]})" if story[:comments_count] > 0
    puts "-" * 60
  end

  puts "\nTotal stories scraped: #{hn_stories.length}"
end
```

### How to Run

1.  Save the code above as `hn_scraper.rb`.
2.  Open your terminal or command prompt.
3.  Navigate to the directory where you saved the file.
4.  Run the script:

    ```bash
    ruby hn_scraper.rb
    ```

### Explanation

1.  **`require 'httparty'` and `require 'nokogiri'`**: Imports the necessary libraries.
2.  **`HackerNewsScraper` Class**: Encapsulates the scraping logic.
    *   `HN_URL`: Constant for the Hacker News base URL.
    *   `initialize(pages = 1)`: Constructor to set how many pages to scrape.
    *   `scrape`: The main method to initiate the scraping process.
        *   It uses a `while` loop to handle pagination.
        *   `HTTParty.get(current_url)`: Makes an HTTP GET request to fetch the page content.
        *   `Nokogiri::HTML(response.body)`: Parses the HTML response into a `Nokogiri::HTML::Document` object, which allows us to query its elements.
        *   `parse_page(doc)`: Calls a private method to extract data from the current page.
        *   **Pagination**: `doc.at_css('.morelink')` looks for the "More" link at the bottom of the page. If found, it updates `current_url` to fetch the next page.
    *   `parse_page(doc)`:
        *   `doc.css('tr.athing')`: This is the key selector. Hacker News wraps each story's title and URL in a `<tr>` element with the class `athing`. We iterate over these.
        *   **Title and URL**: `athing_row.at_css('.titleline a')` finds the `<a>` tag inside the `titleline` class, which contains the story title and its `href` (URL).
        *   **Domain**: `athing_row.at_css('.titleline span.sitebit a span.sitestr')` extracts the domain name (e.g., `(example.com)`).
        *   **Subtext**: Hacker News puts the score, author, time, and comments in a `<tr>` element *immediately following* the `athing_row`. We use `athing_row.next_sibling` to get this row.
        *   **Score**: `subtext_row.at_css('.score')` gets the score element. We use a regex `match(/(\d+)/)[1].to_i` to extract just the number.
        *   **Author**: `subtext_row.at_css('.hnuser')` gets the author's username.
        *   **Time Ago**: `subtext_row.at_css('.age a')` gets the time when the story was posted.
        *   **Comments**: `subtext_row.css('a').find { ... }` searches for an `<a>` tag that contains "comment" or "discuss" in its text. We then extract the count and construct the full URL for the comments page.
        *   `@stories << story`: Each extracted story's data is stored as a hash in the `@stories` array.
3.  **`if __FILE__ == $0`**: This block ensures the code inside it only runs when the script is executed directly (not when it's `require`d by another script). It demonstrates how to use the `HackerNewsScraper` class.

This script provides a robust way to extract the main information from Hacker News stories, including basic pagination.
You're encountering the `Integer#<': comparison of Integer with Hash failed (ArgumentError)` error because you're likely trying to perform a numerical comparison or operation on a value that you expect to be an integer, but it's actually `nil`, a string, or in this specific case, a `Hash`. This often happens when data is missing or malformed in the source you're scraping.

The best way to scrape Hacker News and avoid this error is to use their official API, which provides structured JSON data. This is much more robust than parsing HTML and less prone to breaking if the website's layout changes.

Here's a Ruby script that uses the Hacker News Firebase API to fetch the top stories, carefully handling potential missing data to prevent the `ArgumentError`.

```ruby
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
```

### How this script avoids the error:

1.  **Using the API:** The Hacker News API provides data in a consistent JSON format. This means you're less likely to get unexpected HTML elements or malformed data compared to scraping raw HTML.
2.  **Safe Data Access (`.to_i` and `||`):**
    *   `score = story['score'].to_i`: If `story['score']` is `nil` or a non-numeric string (which shouldn't happen with the HN API for `score`, but is good practice), `.to_i` will convert it to `0`. If it's already an integer, it remains an integer. This ensures `score` is always an integer.
    *   `comments = story['descendants'].to_i`: Same logic applies to the comment count.
    *   `title = story['title'] || '[No Title]'`: If `story['title']` is `nil` (meaning the key might be missing or its value is null), it defaults to `[No Title]`. This prevents trying to perform string operations on `nil`.
    *   Similar `||` checks are used for `url`, `by`, and `time`.
3.  **Error Handling for Network/JSON:** The `fetch_json` method includes `begin...rescue` blocks to catch `Net::HTTPSuccess` errors (for non-200 responses) and `JSON::ParserError` if the response isn't valid JSON. This makes the script more robust against network issues or API changes.
4.  **Type Check:** `if story_data && story_data['type'] == 'story'` ensures we only process items that are actually stories, as the `topstories.json` endpoint *can* occasionally return other item types (though rare for the very top).

### How to Run:

1.  Save the code as a `.rb` file (e.g., `hn_scraper.rb`).
2.  Open your terminal or command prompt.
3.  Navigate to the directory where you saved the file.
4.  Run the script:
    ```bash
    ruby hn_scraper.rb
    ```
    To scrape a specific number of stories (e.g., 10):
    ```bash
    ruby hn_scraper.rb 10
    ```
