require 'sinatra'
require 'erb'
require 'json'
require 'nokogiri'
require 'open-uri'

require_relative 'src/JobCache'

puts ENV["SABATOAST_JENKINS_URL"]
puts ENV["SABATOAST_JENKINS_AUTH"]
puts ENV["SABATOAST_JENKINS_JOB"]

configure do
  set :jenkinsUri, ENV["SABATOAST_JENKINS_URL"]
  set :jenkinsAuth, ENV["SABATOAST_JENKINS_AUTH"]
  set :jenkinsJob, ENV["SABATOAST_JENKINS_JOB"]
  set :serve_static_assets, true
end

##################################

get '/' do
  job = JobCache.instance.getJob settings.jenkinsJob
  @builds = job.lastXBuilds 4

  erb :index
end

##################################
