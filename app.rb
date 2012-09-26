require 'sinatra'
require 'erb'
require 'json'
require 'open-uri'

configure do
   set :jenkinsUri, ENV["SABATOAST_JENKINS_URL"]
   set :jenkinsAuth, ENV["SABATOAST_JENKINS_AUTH"]
   set :jenkinsJob, ENV["SABATOAST_JENKINS_JOB"]
   set :serve_static_assets, true
end


##################################

get '/' do
  last_x_root_build_nums = get_last_x_build_numbers 3
  downstream_projects = get_downstream_projects 
  @builds = collect_build_details last_x_root_build_nums
  collect_downstream_build_statuses @builds, downstream_projects
    
  erb :index
end

##################################


def _get(url_fragment)
  return JSON.parse(open("#{settings.jenkinsUri}#{url_fragment}", "Authorization" => "Basic " + settings.jenkinsAuth).read)
end

def get_downstream_projects
  response = _get("/job/#{settings.jenkinsJob}/api/json")
  projects = response['downstreamProjects'] || []
  projects.map {|p| p['name'] } 
  enabled_projects = projects.select {|p| p["color"] != "disabled" }
  enabled_projects.map {|p| p['name'] } 
end

def get_last_x_build_numbers builds_to_get
 json = _get("/job/#{settings.jenkinsJob}/api/json")
 json["builds"].map {|b| b["number"] }.take(builds_to_get)
end

def collect_build_details(build_nums)
  builds = []  
  build_nums.each do |root_build_num |
    this_build_status = _get("/job/#{settings.jenkinsJob}/#{root_build_num}/api/json")
    this_build_result = this_build_status['result']
    idx = this_build_status["actions"].index { |a| a.has_key?("buildsByBranchName") }
    unless idx.nil?
      builds_by_branch = this_build_status["actions"][idx]["buildsByBranchName"]
      ar = builds_by_branch.values.select {|v| v["buildNumber"] == root_build_num.to_i}
      this_build_branch = ar[0]["revision"]["branch"][0]["name"]
      this_build_sha = ar[0]["revision"]["branch"][0]["SHA1"]
      
      builds << {
                  :buildnum => root_build_num, 
                  :branch => this_build_branch.sub(/origin\//, ""), 
                  :SHA1 => this_build_sha[0,6],
                  :result => this_build_status["result"], 
                  :full_status => this_build_status, 
                  :downstream_builds => [],
                  :failures => [],                  
                  :overall_result => this_build_status["result"],
                  :url => this_build_status["url"]
                }
    end
  end  
  
  builds
end

def collect_downstream_build_statuses(root_builds, downstream_projects)
  root_builds.each do |root_build|
    root_build_num = root_build[:buildnum]
    if root_build[:result] == "FAILURE" 
       root_build[:failures] << {:name => settings.jenkinsJob, :buildnum => root_build_num}
       next
    end
    next if root_build[:result].nil? # currently running    
    downstream_projects.each do |ds_project|
      ds_build_info = _get("/job/#{ds_project}/api/json")
      ds_build_numbers = ds_build_info["builds"].map { |x| x["number"] }
      ds_build_counter = 0
      ds_build_numbers.each do |ds_build_num|          
         ds_build_counter += 1
         if ds_build_counter > 5 then
            break 
         end
         # see if this build is the downstream for this Blue build
         cur_ds_build = _get("/job/#{ds_project}/#{ds_build_num}/api/json")
         causes_idx = cur_ds_build["actions"].index{|x| x.has_key?("causes") }
         upstreamBuild = cur_ds_build["actions"][causes_idx]["causes"][0]["upstreamBuild"]
         if upstreamBuild == root_build_num            
            ds_build_status = {:name=>ds_project, :buildnum=>ds_build_num, :result=>cur_ds_build["result"], :url=>cur_ds_build["url"]} 
            if ds_build_status[:result] == "FAILURE" 
               root_build[:overall_result] = "FAILURE"
               root_build[:failures] << {:name => ds_project, :buildnum => ds_build_num}
            end
            root_build[:downstream_builds] << ds_build_status
            break
         end
      end
    end
    root_build[:downstream_builds] = root_build[:downstream_builds].sort_by {|b| b[:name]}
  end
end