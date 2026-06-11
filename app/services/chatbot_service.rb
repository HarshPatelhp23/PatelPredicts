require 'httparty'

class ChatbotService
  BASE_URL = 'https://generativelanguage.googleapis.com/v1beta'
  FREE_MODEL = 'models/gemini-3-flash-preview'
  
  class << self
    def generate_text(prompt, options = {})
      api_key = options[:api_key] || Rails.application.credentials.dig(:gemini_api_key)
      
      unless api_key
        return {
          success: false,
          message: "API key not configured",
          formatted_message: "I'm not properly configured yet. Please contact support."
        }
      end
      
      url = "#{BASE_URL}/#{FREE_MODEL}:generateContent?key=#{api_key}"
      
      payload = {
        contents: [{
          parts: [{ text: prompt.to_s }]
        }],
        generationConfig: {
          temperature: options[:temperature] || 0.7,
          maxOutputTokens: options[:max_tokens] || 2048,
        }
      }
      
      begin
        response = HTTParty.post(
          url,
          headers: { 'Content-Type' => 'application/json' },
          body: payload.to_json,
          timeout: 30
        )
        
        if response.success?
          data = JSON.parse(response.body)
          text = data.dig('candidates', 0, 'content', 'parts', 0, 'text')
          
          if text.nil?
            return {
              success: false,
              message: "No response generated",
              formatted_message: "I couldn't generate a response. Please try again."
            }
          end
          
          # Return both raw and formatted text
          {
            success: true,
            message: text,
            formatted_message: format_chat_response(text)
          }
        else
          handle_api_error(response)
        end
      rescue => e
        {
          success: false,
          message: e.message,
          formatted_message: "Sorry, I encountered an error. Please try again in a moment."
        }
      end
    end
    
    private
    
    def format_chat_response(text)
      # Start with the raw text
      formatted = text.to_s.dup
      
      # 1. Convert markdown bold **text** to HTML
      formatted.gsub!(/\*\*(.*?)\*\*/) do
        "<span class='font-semibold text-gray-900'>#{$1}</span>"
      end
      
      # 2. Handle bullet points
      if formatted.include?('* ')
        lines = formatted.split("\n")
        in_list = false
        formatted_lines = []
        
        lines.each do |line|
          if line.strip.start_with?('* ')
            unless in_list
              formatted_lines << "<ul class='list-disc pl-5 space-y-1 my-2'>"
              in_list = true
            end
            list_item = line.sub('* ', '').strip
            formatted_lines << "<li>#{list_item}</li>"
          else
            if in_list
              formatted_lines << "</ul>"
              in_list = false
            end
            formatted_lines << line
          end
        end
        
        # Close list if still open
        formatted_lines << "</ul>" if in_list
        formatted = formatted_lines.join("\n")
      end
      
      # 3. Convert newlines to breaks (but preserve list structure)
      unless formatted.include?('<ul>')
        formatted = formatted.gsub("\n", "<br>")
      end
      
      # 4. Add some styling classes for chat bubbles
      formatted = "<div class='chat-message'>#{formatted}</div>"
      
      formatted
    end
    
    def handle_api_error(response)
      error_msg = "API Error: #{response.code}"
      
      case response.code
      when 429
        error_msg = "I'm getting too many requests right now. Please wait a moment and try again."
      when 403
        error_msg = "I'm not properly configured. Please contact support."
      end
      
      {
        success: false,
        message: error_msg,
        formatted_message: "<div class='chat-message text-red-600'>#{error_msg}</div>"
      }
    end
  end
end