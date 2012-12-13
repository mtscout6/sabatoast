require_relative './JenkinsRequest'
require_relative './Build'

class Job
  include JenkinsRequest

  def initialize(jobName, jobCache)
    @jobName = jobName

    @builds = Hash.new
    @downstreamJobs = Hash.new

    @jobCache = jobCache

    @baseUrl = "/job/#{jobName}/api/json"
  end

  def lastXBuilds(count)
    initializeBuilds

    @builds.keys
      .sort
      .reverse
      .map{|num| @builds[num]}
      .take(count)
  end

  def downstreamProjects
    initializeDownstreamJobs
    @downstreamJobs.each_value
  end

  attr_reader :jobName

  private

  def initializeBuilds
    response = getJSON("#{@baseUrl}?tree=builds[number]")

    response["builds"]
      .map {|b| b["number"]}
      .each{|num|
        @builds[num] = Build.new(@jobName, num) unless @builds.has_key? num
      }
  end

  def initializeDownstreamJobs
    return unless @lastPulledDownstreamJobs.nil? || @lastPulledDownstreamJobs + (60*60) <= Time.now

    response = getJSON("#{@baseUrl}?tree=downstreamProjects[name]")

    response["downstreamProjects"]
      .map {|p| p["name"] }
      .each {|project|
        @downstreamJobs[project] = @jobCache.getJob project unless @downstreamJobs.has_key? project
      }

    @lastPulledDownstreamJobs = Time.now
  end

end
