Okay, let's create a Ruby script for scraping Wikipedia pages.

This script will use `Nokogiri` for parsing HTML and `Open-URI` for fetching the page content. It will extract the page title, introductory content, internal links, categories, and (if present) the infobox data.

### Prerequisites

You need to have the `nokogiri` gem installed. If you don't, run:

```bash
gem install nokogiri
```

### The Ruby Script

```ruby
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
  german_scraper = WikipediaScraper.new(language: 'de')
  berlin_de_page = german_scraper.scrape_page("Calculus")
  if berlin_de_page
    puts JSON.pretty_generate(berlin_de_page)
  end
end
```

### How to Run the Script

1.  Save the code above into a file named `wikipedia_scraper.rb`.
2.  Open your terminal or command prompt.
3.  Navigate to the directory where you saved the file.
4.  Run the script using:
    ```bash
    ruby wikipedia_scraper.rb
    ```

### Explanation of the Code

1.  **`WikipediaScraper` Class:**
    *   `initialize(language: 'en')`: Sets up the base URL for the desired Wikipedia language (default is English).
    *   `scrape_page(page_title)`: This is the main public method.
        *   It constructs the full URL, properly encoding the page title to handle spaces and special characters.
        *   It uses `URI.parse(full_url).open` to fetch the HTML content.
        *   `Nokogiri::HTML(html)` parses the HTML into a traversable document object.
        *   It calls several private helper methods to extract specific pieces of information.
        *   Includes `begin...rescue` blocks for error handling (e.g., page not found, network issues).
        *   Returns a hash of the scraped data or `nil` on error.

2.  **Private Helper Methods (`extract_*`):**
    *   `extract_title(doc)`: Finds the `<h1>` tag with `id="firstHeading"` which is Wikipedia's standard title element.
    *   `extract_intro_content(doc)`: This is a bit more involved. It iterates through the children of the main content `div.mw-parser-output`. It collects text from `<p>` tags until it encounters an `<h2>` (a section heading) or the table of contents (`#toc`), which usually marks the end of the introductory section. It also tries to filter out common disambiguation notices.
    *   `extract_infobox(doc)`: Looks for `table.infobox`. If found, it iterates through table rows (`<tr>`), extracting key-value pairs from `<th>` (header) and `<td>` (data) cells. It also cleans up some common Wikipedia artifacts like `[edit]` links.
    *   `extract_links(doc)`: Selects all `<a>` tags within the main content (`#mw-content-text`) whose `href` attribute starts with `/wiki/` (indicating an internal Wikipedia link). It filters out special pages, categories, and disambiguation links. It returns unique links based on their `href`.
    *   `extract_categories(doc)`: Finds the `div` with `id="mw-normal-catlinks"` and then extracts the text from `<a>` tags within its `<ul><li>` structure.

3.  **CSS Selectors:**
    *   Nokogiri uses CSS selectors (similar to JavaScript's `document.querySelector` or jQuery) to find elements.
    *   `#firstHeading`: Selects an element with `id="firstHeading"`.
    *   `.mw-parser-output`: Selects an element with `class="mw-parser-output"`.
    *   `table.infobox`: Selects a `<table>` element with `class="infobox"`.
    *   `a[href^="/wiki/"]`: Selects `<a>` elements whose `href` attribute starts with `/wiki/`.
    *   `#mw-normal-catlinks ul li a`: Selects `<a>` elements that are children of `<li>`, which are children of `<ul>`, which are children of an element with `id="mw-normal-catlinks"`.

### Important Considerations for Scraping

*   **Rate Limiting:** Don't hammer Wikipedia's servers. If you're scraping many pages, add a `sleep` between requests (e.g., `sleep(1)`).
*   **User-Agent:** For more robust scraping, you might want to set a custom `User-Agent` header when making requests, identifying your script. `Open-URI` allows this: `URI.parse(full_url).open('User-Agent' => 'MyRubyWikipediaScraper/1.0 (your-email@example.com)')`.
*   **`robots.txt`:** Always check a website's `robots.txt` file (e.g., `https://en.wikipedia.org/robots.txt`) to understand their scraping policies. Wikipedia is generally open, but it's good practice.
*   **HTML Structure Changes:** Websites, including Wikipedia, can change their HTML structure. If this script stops working, you'll likely need to update the CSS selectors.
*   **Data Cleaning:** The extracted text often contains footnotes, `[edit]` links, or other artifacts. The script does some basic cleaning, but more might be needed depending on your exact use case.
*   **JavaScript-rendered Content:** This script only processes the initial HTML. If parts of the page content are loaded dynamically via JavaScript, `Nokogiri` alone won't see them. You'd need a headless browser (like Selenium or Ferrum) for that, but Wikipedia's main content is usually server-rendered.
