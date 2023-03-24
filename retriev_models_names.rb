require 'net/http'
require 'json'
require 'dotenv/load'

uri = URI('https://api.openai.com/v1/models')
req = Net::HTTP::Get.new(uri)
req['Authorization'] = "Bearer #{ENV['OPENAI_API_KEY']}"

res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(req)
end

models = JSON.parse(res.body)['data']
models.each { |model| p model['id'] }
