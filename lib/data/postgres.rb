require 'logger'
require 'pg'

module Postgres
  module LinkElement
    class Table
      attr_reader :schema, :table, :hostaddr, :port, :dbname, :username, :password, :connection
      def initialize(schema, table, hostaddr, port, dbname, username, password)
        @schema = schema
        @table = table
        @hostaddr = hostaddr
        @port = port
        @dbname = dbname
        @username = username
        @password = password
        @connection = PG.connect(:hostaddr=>@hostaddr, :port=>@port, :dbname=>@dbname, :user=>@username, :password=>@password)
        # set up logger and data store
        @log_file = File.open("database.log", File::WRONLY | File::APPEND)
        @data_log = Logger.new(log_file)
      end

      def ingest_link_text(link_element)
        insert_sql = "INSERT INTO #{@schema}.#{@table}(link, text)VALUES($1, $2)"
        data_values = [link_element.link, link_element.text]
        @connection.exec_params(insert_sql, data_values)
        @data_log.info("INSERTING VALUES: #{data_values}}")
      end

    end
  end
end

