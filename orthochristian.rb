require 'open-uri'
require 'nokogiri'

require 'logger'
require 'pg'

require_relative 'lib/element'

# set up logger and data store
log_file = File.open("database.log", File::WRONLY | File::APPEND)

data_log = Logger.new(log_file)

connection = PG.connect(:hostaddr=>"23.239.16.24", :port=>5432, :dbname=>"scrapedata", :user=>"linpostgres", :password=>"")


DEBUG = 1

# load the page
doc = Nokogiri::HTML(URI.open('https://orthochristian.com/202/'))

# find all links
links = doc.search('a')

# see how many we're working with
puts "There are #{links.size} links found"

# title of the document
puts doc.title

class Article < LinkElement

end

html = doc.search(".list-articles-wide__uppertitle a")

#puts html

recent_articles = []

html.each do |article_content|
  a = Article.new(article_content['href'], article_content.text.strip())
  recent_articles << a
end

recent_articles = recent_articles.uniq.sort

# display contents
File.open('orthochristian.txt', 'w') do |file|
  recent_articles.each do |article|
    file << article.to_s
  end
end

# save to database
recent_articles.each do |article|
  insert_sql = 'INSERT INTO articles.orthochristian(link, text)VALUES($1, $2)'
  data_values = [article.link, article.text]
  connection.exec_params(insert_sql, data_values)
  data_log.info("INSERTING VALUES: #{data_values}}")
end

# get final count
puts "#{recent_articles.size} Program elements scraped"

# display for debugging purposes
pp recent_articles if DEBUG == 1
