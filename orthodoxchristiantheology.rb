# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require 'logger'

require_relative 'lib/element'

# set up logger and data store

DEBUG = 1

# load the page
doc = Nokogiri::HTML(HTTParty.get('https://orthodoxchristiantheology.com/').body)

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
  article_text = article_content.text.strip
  article_link = article_content['href']

  unless article_link.include? 'orthodoxchristiantheology.com'
    article_link = article_content['href'].prepend('https://www.orthodoxchristiantheology.com')
  end

  a = Article.new(article_link, article_text)

  recent_articles << a
end

recent_articles = recent_articles.uniq.sort

File.open('orthodoxchristiantheology.txt', 'w') do |file|
  recent_articles.each do |article|
    file << article.to_s
  end
end

pp recent_articles
