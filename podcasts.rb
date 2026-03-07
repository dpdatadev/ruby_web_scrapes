# frozen_string_literal: true

require 'nokogiri'
require 'httparty'
require 'logger'
# require 'pg'

require_relative 'lib/element'

# connection = PG.connect(:hostaddr=>"23.239.16.24", :port=>5432, :dbname=>"scrapedata", :user=>"linpostgres", :password=>"")

DEBUG = 1

# program configuration

# set up logger and data store
# data_log_file = File.open("database.log", File::WRONLY | File::APPEND)

# logger
time_stamp = Time.now.strftime('%Y%m%d_%H%M')
log_file_name = "af_podcasts_#{time_stamp}.log"
data_log = Logger.new(log_file_name)
p log_file_name if DEBUG == 1

# http
URL = 'https://www.ancientfaith.com/podcasts/?sort=latest_episodes'
data_log.info("Scraping #{URL}")
scrape_page = HTTParty.get(URL)
scrape_data = scrape_page.body

# load the page
doc = Nokogiri::HTML(scrape_data)

# find all links
links = doc.search('a')

# see how many we're working with
puts "There are #{links.size} links found"

# title of the document
puts doc.title

class Podcast < LinkElement
end

# array to store the recent program objects
recent_podcasts = []

links.each do |podcast_content|
  next if podcast_content.nil?

  link = podcast_content['href']
  text = podcast_content.children.text.strip

  if DEBUG == 1
    pp link
    pp text
  end

  podcast_link = Podcast.new(link.prepend('https://www.ancientfaith.com'), text)
  recent_podcasts.push(podcast_link) unless podcast_link.text.blank?
end

# clean up, remove duplicate entries, and alphabetize the objects
recent_podcasts.delete_if { |link| link[:text] == 'View Episodes' }
recent_podcasts = recent_podcasts.uniq.sort

# display contents
File.open('podcast_data.txt', 'w') do |file|
  recent_podcasts.each do |podcast|
    data_log.info(podcast.to_s)
    file << podcast.to_s
  end
end

# get final count
puts "#{recent_podcasts.size} Program elements scraped"

# display for debugging purposes
pp recent_podcasts if DEBUG == 1
