# frozen_string_literal: true

links = %w[derek derek libby libby theo]
texts = ['hello', 'where do i go', 'this is cool', 'this is cool']

# new_collection = links.uniq.product(texts.uniq).map { |link, text| { link: link, text: text} }

Program = Struct.new(:link, :text)

new_collection = []

links.uniq.zip(texts.uniq).each do |link, text|
  p = Program.new(link, text)
  new_collection << p
end

puts new_collection
