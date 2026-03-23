require 'gemini'

# Initialize the client
client = Gemini::Client.new("")

# Simple Text Generation
response = client.generate_content(
  "Please generate a summary of the decorator design pattern using a comparison in the following Languages: Go, C#, Ruby, Python",
  model: "gemini-2.5-flash"
)

puts response.text if response.valid?


# Rails version
module AI   
  class PromptViewModel
    attr_accessor :prompt_text, :response_text
    def initialize(prompt_text, response_text)
      @prompt_text = prompt_text
      @response_text = response_text
    end
  end

  class PromptRequest
    attr_reader :api_key, :prompt, :response
    
    def initilize(api_key)
      @api_key = api_key
      @client = Gemini::Client.new(api_key)
    end

    def set_prompt_text(prompt_text)
      @prompt = prompt_text
    end

    def generate_response 
      if @prompt.nil? or @prompt.blank?
        puts "MUST SET PROMPT TEXT"
        return
      end
      response_result = @client.generate_content(@prompt, model: "gemini-2.5-flash")
      @response = response_result.text if response_result.valid?
    end
  end
end