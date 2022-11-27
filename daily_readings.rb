# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'logger'
require 'pg'

require_relative 'lib/element'

# set up logger and data store
log_file = File.open("database.log", File::WRONLY | File::APPEND)

data_log = Logger.new(log_file)

connection = PG.connect(:hostaddr=>"23.239.16.24", :port=>5432, :dbname=>"scrapedata", :user=>"linpostgres", :password=>"")


# config variables
DEBUG = 1

LOG_OUTPUT = 1

# function for viewing/storing the reading texts
def log_reading_text(reading_link, output_file)
  reading_doc = Nokogiri::HTML(URI.open(reading_link))
  reading_title = reading_doc.search('#main #content section article h2')
  reading_text = reading_doc.search('#main #content section article dl dd')

  title = reading_title.text.strip
  text = reading_text.text.strip

  File.open(output_file, 'w') do |file|
    file << title
    file << "\n"
    file << text
  end

  pp title
  pp text
end

# MAIN
# load the page
doc = Nokogiri::HTML(URI.open('https://www.oca.org/readings'))

# find all links
links = doc.search('a')

# see how many we're working with
puts "There are #{links.size} links found"

# title of the document
puts doc.title

class ScriptureReading < LinkElement
end

# now search the document for all reading elements
html = doc.search('#main #content section ul li a')

# array to store the scripture reading objects
recent_readings = []

html.each do |reading_link|
  sr = ScriptureReading.new(reading_link['href'].prepend('https://www.oca.org'), reading_link.text.strip)
  recent_readings << sr
end

# remove duplicate entries and alphabetize the objects
recent_readings = recent_readings.uniq.sort

# display contents
File.open('readings_data.txt', 'w') do |file|
  recent_readings.each do |reading|
    file << reading.to_s
  end
end

recent_readings.each do |reading|
  insert_sql = 'INSERT INTO scriptures.ocadailyreadings(link, text)VALUES($1, $2)'
  data_values = [reading.link, reading.text]
  connection.exec_params(insert_sql, data_values)
  data_log.info("INSERTING VALUES: #{data_values}}")
end

# get final count
puts "#{recent_readings.size} Reading elements scraped"

# display for debugging purposes
pp recent_readings if DEBUG == 1

if LOG_OUTPUT == 1

  # control variable for file output
  reading_count = 0

  # iterate over each daily reading and log output
  recent_readings.each do |reading_link|
    log_reading_text(reading_link.link, "reading_output_#{reading_count += 1}.txt")
  end
end
