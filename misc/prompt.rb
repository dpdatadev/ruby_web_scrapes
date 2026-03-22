require 'gemini'

# Initialize the client
client = Gemini::Client.new("")

# Simple Text Generation
response = client.generate_content(
  "Please generate a ruby script for scraping Hacker News. Please avoid this error: 'Integer#<': comparison of Integer with Hash failed (ArgumentError)'",
  model: "gemini-2.5-flash"
)

puts response.text if response.valid?