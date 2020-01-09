require 'net/http'

response = Net::HTTP.get('0.0.0.0', '/example', '4567')
puts response

response = Net::HTTP.get('0.0.0.0', '/example_render', '4567')
puts response

response = Net::HTTP.get('0.0.0.0', '/thing/12345', '4567')
puts response
