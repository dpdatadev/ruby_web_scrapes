# frozen_string_literal: true

# https://www.delftstack.com/howto/ruby/ruby-nil-empty-blank/
class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end

# create an object to hold links
LinkElement = Struct.new(:link, :text) do
  # include all comparable operations
  include Comparable
  # add a method for rendering a custom
  # display string
  def to_s
    "\n::Element Link::#{link}::Element Text::#{text}::\n"
  end

  # we want to be able to sort an array of elements based on link
  def <=>(other)
    # sort/order by the link
    self[:link] <=> other[:link]
  end
end

# TODO, OOP refactoring (3/6)

# require 'httparty'
# require 'nokogiri'
# require 'json'
# require 'logger'
# require 'sqlite3'

module Scrapers
  class ScraperConfiguration
    attr_accessor :options,
                  :URL

    def initialize(options)
      @logfile = options[:log_file]
      @URL = options[:URL]
    end
  end

  class ElementScraper
    attr_accessor :scrape_url, :debug
    attr_reader :scrape_data, :logger

    def initialize(scrape_url, debug)
      @scrape_url = scrape_url
      @debug = debug
      _bootstrap_app()
    end

    def scrape
      p @scrape_url if @debug
    end

    private

    def _bootstrap_app
      time_stamp = Time.now.strftime('%Y%m%d_%H%M')
      log_file_name = "af_podcasts_#{time_stamp}.log"
      @logger = Logger.new(log_file_name)
      p log_file_name if @DEBUG == 1
    end
  end
end
# # testing
# s = ElementScraper.new('https://www.oca.org/readings/daily', true)
# pp s.to_s
# pp af_scraper_config[:log_file]
# sc = ScraperConfiguration.new(af_scraper_config)
# pp sc.URL
