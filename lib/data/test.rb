require_relative 'postgres.rb'
require_relative '../element.rb'

table = Postgres::LinkElement::Table.new("articles", "orthochristian", "fake", 5423, "fake", "fake", "fake")

puts table.inspect

fake_element = LinkElement.new("fakelink.com", "fake link text")

table.ingest_link_text(fake_element)



