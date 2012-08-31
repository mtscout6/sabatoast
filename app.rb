require 'sinatra'
require 'erb'
require 'json'

configure do
#  require 'redis'
#  redisUri = ENV["REDISTOGO_URL"] || 'redis://localhost:6379'
#  uri = URI.parse(redisUri)
#  REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

get '/' do
  #json = REDIS.get("things_to_do") || "[]"
  #things_to_do = JSON.parse(json)
  #@activity = things_to_do.randomly_pick(1)[0]
  erb :index
end