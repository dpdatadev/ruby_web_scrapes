require 'open-uri'
require 'nokogiri'
require 'logger'
require 'pg'

require_relative 'lib/element.rb'

# set up logger and data store
log_file = File.open("database.log", File::WRONLY | File::APPEND)

data_log = Logger.new(log_file)

connection = PG.connect(:hostaddr=>"23.239.16.24", :port=>5432, :dbname=>"scrapedata", :user=>"linpostgres", :password=>"KHrdU1JRn9H_8EsO")


DEBUG = 1

# load the page
doc = Nokogiri::HTML(URI.open('https://orthodoxchristiantheology.com/'))

puts doc.title

# find all links
links = doc.search('a')

# see how many we're working with
puts "There are #{links.size} total links found (not all may be harvested)"

# now search the document for all artcile elements
html = doc.search('#posts article .post-title a')

class Article < LinkElement

end

# array to store the recent article objects
recent_articles = []
html.each do |article_content|
  article_text = article_content.text.strip()
  article_link = article_content['href']

  if !article_link.include? "orthodoxchristiantheology.com"
    article_link = article_content['href'].prepend("https://www.orthodoxchristiantheology.com")
  end

  a = Article.new(article_link, article_text)

  recent_articles << a
end

recent_articles = recent_articles.uniq.sort

File.open("orthodoxchristiantheology.txt", "w") do |file|
  recent_articles.each do |article|
    file << article.to_s
  end
end

connection.exec('TRUNCATE TABLE articles.orthodoxchristiantheology')

# save to database
recent_articles.each do |article|
  insert_sql = 'INSERT INTO articles.orthodoxchristiantheology(link, text)VALUES($1, $2)'
  data_values = [article.link, article.text]
  connection.exec_params(insert_sql, data_values)
  data_log.info("INSERTING VALUES: #{data_values}}")
end

puts recent_articles
