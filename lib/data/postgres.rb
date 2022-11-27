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
        @connection = "fakeconnection"
        @connection = PG.connect(:hostaddr=>@hostaddr, :port=>@port, :dbname=>@dbname, :user=>@username, :password=>@password)
      end

      def ingest_link_text(link_element)
        insert_sql = "INSERT INTO #{@schema}.#{@table}(link, text)VALUES($1, $2)"
        data_values = [article.link, article.text]
        connection.exec_params(insert_sql, data_values)
        data_log.info("INSERTING VALUES: #{data_values}}")
      end

    end
  end
end

