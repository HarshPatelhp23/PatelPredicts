require 'net/http'
require 'json'
require 'fileutils'

# Configuration
IMAGE_FOLDER = Rails.root.join('app', 'assets', 'images', 'ipl')
UNSPLASH_ACCESS_KEY = 'koK3rjjb7ecjOkuO6CeFR2y_roJJaEhKWPruyO5AoL0' # Get free key from https://unsplash.com/developers

# Create the directory if it doesn't exist
FileUtils.mkdir_p(IMAGE_FOLDER)

def fetch_player_image(player_name)
  # Clean the player name for filename
  clean_name = player_name.gsub(/[^0-9A-Za-z.\-]/, '_').downcase
  file_path = IMAGE_FOLDER.join("#{clean_name}.jpg")
  
  # Skip if image already exists
  if File.exist?(file_path)
    puts "Image already exists for #{player_name}"
    return true
  end
  
  begin
    # Search for image on Unsplash
    search_url = URI("https://api.unsplash.com/search/photos")
    search_url.query = URI.encode_www_form({
      query: "#{player_name} cricket player",
      per_page: 1,
      client_id: UNSPLASH_ACCESS_KEY
    })
    
    response = Net::HTTP.get_response(search_url)
    
    if response.code != '200'
      puts "Failed to search for #{player_name}: #{response.code}"
      return false
    end
    
    data = JSON.parse(response.body)
    
    if data['results'].empty?
      puts "No image found for #{player_name}"
      return false
    end
    
    # Get the image URL
    image_url = data['results'][0]['urls']['regular']
    
    # Download the image
    image_uri = URI(image_url)
    image_data = Net::HTTP.get(image_uri)
    
    # Save the image
    File.open(file_path, 'wb') do |file|
      file.write(image_data)
    end
    
    puts "Successfully saved image for #{player_name}"
    return true
    
  rescue StandardError => e
    puts "Error fetching image for #{player_name}: #{e.message}"
    return false
  end
end

# Main script
puts "Starting player image fetch..."
puts "================================"

Player.find_each do |player|
  puts "\nProcessing: #{player.name}"
  fetch_player_image(player.name)
  
  # Be respectful with API rate limits
  sleep(1)
end

puts "\n================================"
puts "Player image fetch completed!"
puts "Images saved to: #{IMAGE_FOLDER}"
