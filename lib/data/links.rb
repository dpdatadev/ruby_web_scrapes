# frozen_string_literal: true

require 'json'
require 'logger'
require 'httparty'

require_relative '../element'

DEBUG = 1

def substring(str, word1, word2)
  str.partition(word1).last.rpartition(word2).first.strip
end

# testing, fetch links from any webpage from local go colly server
# afpodcast scrape
URL = 'http://127.0.0.1:7171/?url=https://www.ancientfaith.com/podcasts/?sort=latest_episodes'

# log config

time_stamp = Time.now.strftime('%Y%m%d_%H%M')
log_file_name = "af_podcasts_#{time_stamp}.log"
LOGGER = Logger.new(log_file_name)

# contact linkserver - GET HTTP
response = HTTParty.get(URL)
# parse "Links" JSON
scrape_links = JSON.parse(response.body)
# assign "Links" collection
links = scrape_links['Links']
# the initial count of "Links" returned
initial_link_count = 0
# the final collection to be returned
new_podcasts = []

links.each do |link|
  next if link.nil?

  link = link[0]
  next if link.blank?
  next unless link.start_with?('https://www.ancientfaith.com/podcasts')

  initial_link_count += 1
  pp link if DEBUG == 1
  text = substring(link, 'podcasts/', '/')
  p text if DEBUG == 1
  element = LinkElement.new(link, text)
  new_podcasts.push(element)
end

new_podcasts.delete_if { |link| link[:text].blank? }

new_podcasts.each { |podcast| LOGGER.info(podcast) }

puts "GET from link server - #{initial_link_count} podcasts returned\n"
puts "Processed new Podcasts - #{new_podcasts.size} processed.\n"

pp new_podcasts
