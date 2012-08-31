require 'sinatra'
require 'erb'
require 'json'
require 'open-uri'

configure do
   set :jenkinsUri, ENV["SABATOAST_JENKINS_URL"]
   set :jenkinsAuth, ENV["SABATOAST_JENKINS_AUTH"]
   set :jenkinsJob, ENV["SABATOAST_JENKINS_JOB"]
end

get '/' do
  @jobs = get_enabled_jobs
  @last_build = get_last_build_number
  @last_five_builds = get_builds_by_branch_name 5, @last_build  
  erb :index
end

def get_enabled_jobs
  response = open("#{settings.jenkinsUri}/api/json", "Authorization" => "Basic " + settings.jenkinsAuth)
  json = JSON.parse(response.read)
  all_jobs = json['jobs']
  all_jobs.select {|item| item["color"] != "disabled" }
end

def get_last_build_number
 response = open("#{settings.jenkinsUri}/job/#{settings.jenkinsJob}/api/json", "Authorization" => "Basic " + settings.jenkinsAuth)
 json = JSON.parse(response.read) 
 json["builds"][0]["number"] 
end

def get_builds_by_branch_name(take, last_build)
 response = open("#{settings.jenkinsUri}/job/#{settings.jenkinsJob}/#{last_build}/api/json", "Authorization" => "Basic " + settings.jenkinsAuth)
 json = JSON.parse(response.read)
 idx = json["actions"].index{|x| x.has_key?("buildsByBranchName") }
 
 branches_by_build = Hash.new
   
 json["actions"][idx]["buildsByBranchName"].each_pair do |k,v| 
    buildNum = v["buildNumber"].to_i
    branches_by_build[buildNum] = k
 end
 
 builds = branches_by_build.keys.sort.reverse
 last_x_branch_builds = Hash.new
 builds.take(take).each{|b| last_x_branch_builds[branches_by_build[b]] = b }
 last_x_branch_builds
end