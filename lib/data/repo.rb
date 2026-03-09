require 'sequel'
require_relative '../element'

#TODO 3-9-26
class Database 
  def initialize(options)
    
  end
end


group_name = 'test_db'
time_stamp = Time.now.strftime('%Y%m%d_%H%M')
db_name = "#{group_name}_#{time_stamp}.db"

DB = Sequel.sqlite db_name

Sequel.database_timezone = :utc
Sequel.application_timezone = :local

DB.create_table :links do
  primary_key :id
  String :link
  String :text
  column :scraped_at, :timestamp, null: false, default: Sequel::CURRENT_TIMESTAMP
end

links = DB[:links] # Create a dataset

