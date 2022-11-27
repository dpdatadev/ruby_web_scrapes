# frozen_string_literal: true

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
