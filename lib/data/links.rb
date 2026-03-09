# frozen_string_literal: true

require 'json'
require 'logger'
require 'sequel'
require 'httparty'

require_relative '../element'

DEBUG = 1

# testing, fetch links from any webpage from local go colly server
# afpodcast scrape
LINK_EXTRACT_API = 'http://127.0.0.1:7171/?url='
HOME_PAGE_URL = "#{LINK_EXTRACT_API}https://www.ancientfaith.com/podcasts/?sort=latest_episodes"

def iterate_links(links, group_name, links_db)
  # log config
  time_stamp = Time.now.strftime('%Y%m%d_%H%M')
  log_file_name = "#{group_name}_#{time_stamp}.log"
  logger = Logger.new(log_file_name)
  sub_links = []

  links.each do |link|
    next if link.nil?

    link = link[0]
    next if link.blank?
    next unless link.start_with?('https://www.ancientfaith.com/podcasts')

    pp link if DEBUG == 1
    text = link.substring('podcasts/', '/')
    p text if DEBUG == 1
    element = LinkElement.new(link, text)
    sub_links.push(element)
  end

  sub_links.delete_if { |link| link[:text].blank? }

  sub_links.each do |podcast|
    logger.info(podcast)
    links_db.insert(podcast.link, podcast.text)
  end

  sub_links
end

def root_links(_url)
  # contact linkserver - GET HTTP
  response = HTTParty.get(_url)
  # parse "Links" JSON
  scrape_links = JSON.parse(response.body)
  # assign "Links" collection
  links = scrape_links['Links']

  links unless links.nil?
end

# DB
db_group_name = 'af_podcasts'
db_time_stamp = Time.now.strftime('%Y%m%d_%H%M')
db_name = "#{db_group_name}_#{db_time_stamp}.db"

DB = Sequel.sqlite db_name, loggers: [Logger.new($stdout)]

Sequel.database_timezone = :utc
Sequel.application_timezone = :local

DB.create_table :links do
  String :link
  String :text
end

DB.create_table :linksmeta do
  Integer :scrape_count
  column :scraped_at, :timestamp, null: false, default: Sequel::CURRENT_TIMESTAMP
end

links_db = DB[:links]
links_meta = DB[:linksmeta]

# pp new_podcasts
link_tree = {}
home_page_links = root_links(HOME_PAGE_URL)
podcast_list = iterate_links(home_page_links, 'af_podcasts', links_db)
sub_links = []

podcast_list.each do |podcast|
  next if podcast.link.blank? || podcast.link.nil?

  sub_link = podcast.link
  sub_page_url = LINK_EXTRACT_API + sub_link
  sub_links.push(LinkElement.new(sub_page_url, podcast.text))
  links_db.insert(link: podcast.link, text: podcast.text)
end

sub_links.each do |sublink|
  next if sublink.link.nil?

  child_link_to_scrape = sublink.link
  child_page_name = sublink.text
  link_tree[sublink] = iterate_links(root_links(child_link_to_scrape), child_page_name, links_db)
end

pp link_tree if DEBUG == true

process_count = links_db.count

puts "GET from link server - #{home_page_links.size} podcasts returned\n"
puts "Processed ALL new Podcasts - #{process_count} processed.\n"

links_meta.insert(scrape_count: process_count)
