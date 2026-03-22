# frozen_string_literal: true

require 'json'
require 'logger'
require 'sequel'
require 'httparty'

require_relative '../element'

Dir.glob("*.log").each { |f| File.delete(f) } # clean up yesterdays mess

DEBUG = 1

# Go microservice, very fast page/element parsing using Colly
LINK_EXTRACT_API = 'http://127.0.0.1:7171/links?url='
HOME_PAGE_URL = "#{LINK_EXTRACT_API}https://www.ancientfaith.com/podcasts/?sort=latest_episodes" # latest podcasts

def iterate_links(links, group_name, links_db)
  # log config - each parent group of links will get their own log file
  time_stamp = Time.now.strftime('%Y%m%d_%H%M')
  log_file_name = "#{group_name}_#{time_stamp}.log"
  logger = Logger.new(log_file_name)
  sub_links = []

  links.each do |link|
    next if link.nil? # problem

    link = link[0] # href
    next if link.blank? # bogus link
    next unless link.start_with?('https://www.ancientfaith.com/podcasts') # only valid podcast links
    next if link.end_with?('?page=') # avoid pagination/filters

    pp link if DEBUG == 1
    text = link.substring('podcasts/', '/') # grab the unique name/identifier
    p text if DEBUG == 1
    element = LinkElement.new(link, text)
    sub_links.push(element)
  end

  sub_links.delete_if { |link| link[:text].blank? } # one more catch, no blank href/children

  sub_links.each do |podcast|
    logger.info(podcast)
    links_db.insert(podcast.link, podcast.text)
  end

  sub_links
end

def root_links(_url)
  # contact linkserver - GET HTTP
  response = HTTParty.get(_url)
  # parse "Links" JSON response
  scrape_links = JSON.parse(response.body)
  # assign "Links" collection
  links = scrape_links['Links']

  links unless links.nil? # return and proceed unless nil
end

# DB
db_group_name = 'af_podcasts'
db_time_stamp = Time.now.strftime('%Y%m%d_%H%M')
db_name = "#{db_group_name}_#{db_time_stamp}.db"

DB = Sequel.sqlite db_name, loggers: [Logger.new($stdout)]

Sequel.database_timezone = :utc
Sequel.application_timezone = :local
# table to hold links scraped
DB.create_table :links do
  String :link
  String :text
end
# table to hold final count and scrape time
DB.create_table :linksmeta do
  Integer :scrape_count
  column :scraped_at, :timestamp, null: false, default: Sequel::CURRENT_TIMESTAMP
end

links_db = DB[:links] # all scraped podcast links, starting with parent list
links_meta = DB[:linksmeta] # count of how many scraped plus local timestamp

link_tree = {} # hiearchy of links
home_page_links = root_links(HOME_PAGE_URL) # home page scan - list of initial/parent podcasts
podcast_list = iterate_links(home_page_links, 'af_podcasts', links_db) # validate and build each link
sub_links = [] # collection to hold links of each child/sub page of podcasts

# for each podcast we will be scraping
podcast_list.each do |podcast|
  next if podcast.link.blank? || podcast.link.nil?

  sub_link = podcast.link
  sub_page_url = LINK_EXTRACT_API + sub_link
  sub_links.push(LinkElement.new(sub_page_url, podcast.text)) # construct a call to our link server with the podcast name for ID
  links_db.insert(link: podcast.link, text: podcast.text) # insert the initial list into the DB
end

# for each branch of podcasts from the initial home page list
sub_links.each do |sublink|
  next if sublink.link.nil?

  child_link_to_scrape = sublink.link
  child_page_name = sublink.text
  # build the tree - for each service call to the child podcasts' page, scan each sub/child page of all new podcasts
  # same as above - collect and validate links from each page
  link_tree[sublink] = iterate_links(root_links(child_link_to_scrape), child_page_name, links_db) # :links_db => save all child links to db as well
end

pp link_tree if DEBUG == 1

process_count = links_db.count

puts "GET from link server - #{home_page_links.size} podcasts returned\n"
puts "Processed ALL new Podcasts - #{process_count} processed.\n"

links_meta.insert(scrape_count: process_count)
