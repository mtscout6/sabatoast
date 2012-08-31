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
  @last_five_builds = get_builds_by_branch_name 1, @last_build  
  @downstream_projects = get_downstream_projects 
  

  this_blue_build_num = @last_five_builds["origin/f-35"]
  this_build_status = _get("/job/#{settings.jenkinsJob}/#{this_blue_build_num}/api/json")
  this_build_result = this_build_status['result']
    
  downstream_status = []
  @downstream_projects.each do |project|
    ds_build_info = _get("/job/#{project}/api/json")
    xx = ds_build_info["builds"].map { |x| x["number"] }
    ds_build_nums = xx.each do |build_num| 
       # see if this build is the downstream for this Blue build
       cur_ds_build = _get("/job/#{project}/#{build_num}/api/json")
       if cur_ds_build["actions"][0]["causes"]["upstreamBuild"] == this_blue_build_num
          downstream_status << {:name=>project, :status=>cur_ds_build["result"]} 
          break
       end
    end
  end

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

def get_downstream_projects
  response = _get("/job/#{settings.jenkinsJob}/api/json")
  x = response['downstreamProjects'] || []
  x.map {|p| p['name'] } 
end

def get_build_statuses(build_num)
  # get Blue build status for build #build_num
  # for each downstream, find the corresponding build and get status
end

def _get(url_fragment)
  return JSON.parse(open("#{settings.jenkinsUri}#{url_fragment}", "Authorization" => "Basic " + settings.jenkinsAuth).read)
end



