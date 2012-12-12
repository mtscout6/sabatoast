require_relative './Build'

class Job
  def initialize(jobName, jobCache, requester)
    @jobName = jobName

    @builds = Hash.new
    @downstreamJobs = Hash.new

    @jobCache = jobCache
    @requester = requester

    @baseUrl = "/job/#{jobName}/api/json"

    initializeDownstreamJobs
  end

  def lastXBuilds(count)
    initializeBuilds

    @builds.keys
      .sort
      .reverse
      .map{|num| @builds[num]}
      .take(count)
  end

  attr_reader :jobName

  private

  def initializeBuilds
    response = @requester.getJSON("#{@baseUrl}?tree=builds[number]")

    response["builds"]
      .map {|b| b["number"]}
      .each{|num|
        @builds[num] = Build.new(@jobName, num) unless @builds.has_key? num
      }
  end

  def initializeDownstreamJobs
    response = @requester.getJSON("#{@baseUrl}?tree=downstreamProjects[name]")

    response["downstreamProjects"]
      .map {|p| p["name"] }
      .each {|project|
        @downstreamProjects[project] = @jobCache.getJob project unless @downstreamProjects.has_key? project
      }
  end
end
