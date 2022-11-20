# create an object to hold the podcasts/programs
class Element < Struct.new(:link, :text)
    # include all comparable operations
    include Comparable
    # add a method for rendering a custom
    # display string
    def to_s
      "\n::Element Link::#{link}::Element Text::#{text}::\n"
    end
  
    # we want to be able to sort an array of Program structs
    def <=>(other)
      # sort/order by the link
      self[:link] <=> other[:link]
    end
  end