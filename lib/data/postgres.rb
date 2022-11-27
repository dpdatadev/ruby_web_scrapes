require 'logger'
require 'pg'
# TODO
module Postgres
  log_file = File.open("database.log", File::WRONLY | File::APPEND)

  data_log = Logger.new(log_file)

  connection = PG.connect(:hostaddr=>"23.239.16.24", :port=>5432, :dbname=>"scrapedata", :user=>"linpostgres", :password=>"KHrdU1JRn9H_8EsO")
end

