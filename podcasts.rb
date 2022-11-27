# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'logger'
require 'pg'

require_relative 'lib/element.rb'

# set up logger and data store
log_file = File.open("database.log", File::WRONLY | File::APPEND)

data_log = Logger.new(log_file)

connection = PG.connect(:hostaddr=>"23.239.16.24", :port=>5432, :dbname=>"scrapedata", :user=>"linpostgres", :password=>"KHrdU1JRn9H_8EsO")

DEBUG = 1

# load the page
doc = Nokogiri::HTML(URI.open('https://www.ancientfaith.com/podcasts#af-recent-episodes'))

# find all links
links = doc.search('a')

# see how many we're working with
puts "There are #{links.size} links found"

# title of the document
puts doc.title

class Program < LinkElement

end

# now search the document for all podcast elements
html = doc.search('#main #podcasts #podcasts li a')

# array to store the recent program objects
recent_programs = []

html.each do |podcast_content|
  p = Program.new(podcast_content['href'].prepend('https://www.ancientfaith.com'), podcast_content.text.strip)
  recent_programs << p
end

# remove duplicate entries and alphabetize the objects
recent_programs = recent_programs.uniq.sort

# display contents
File.open('podcast_data.txt', 'w') do |file|
  recent_programs.each do |program|
    file << program.to_s
  end
end

# save to database
recent_programs.each do |program|
  insert_sql = 'INSERT INTO podcasts.ancientfaith(link, text)VALUES($1, $2)'
  data_values = [program.link, program.text]
  connection.exec_params(insert_sql, data_values)
  data_log.info("INSERTING VALUES: #{data_values}}")
end

# get final count
puts "#{recent_programs.size} Program elements scraped"

# display for debugging purposes
pp recent_programs if DEBUG == 1
