# frozen_string_literal: true

require_relative 'postgres'
require_relative '../element'
require 'test/unit'

class TestPostgres < Test::Unit::TestCase
  def test_postgres_connection_is_valid
    table = Postgres::LinkElement::Table.new('articles', 'orthochristian', '23.239.16.24', 5432, 'scrapedata',
                                             'linpostgres', 'KHrdU1JRn9H_8EsO')
    assert_not_nil table
  end
end
