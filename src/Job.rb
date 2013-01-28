require_relative './JenkinsRequest'
require_relative './Build'
require_relative './BuildToBranchMap'

class Job
  include JenkinsRequest

  def initialize(jobName)
    @jobName = jobName

    @builds = Hash.new
    @downstreamJobs = Hash.new

    @baseUrl = "/job/#{jobName}/api/json"
  end

  def lastXBuilds(count)
    initializeBuilds

    builds = @builds.keys
      .sort
      .reverse
      .map{|num| @builds[num]}

    builds = builds.take(count) unless count.nil?
    builds
  end

  def getBuild(buildNumber)
    return @builds[buildNumber] if @builds.has_key? buildNumber

    @builds[buildNumber] = Build.new(self, buildNumber)
    @builds[buildNumber]
  end

  def downstreamProjects
    initializeDownstreamJobs
    @downstreamJobs.each_value
  end

  def buildToBranchMap
    @branchMap = BuildToBranchMap.new @jobName if @branchMap.nil?
    @branchMap
  end

  attr_reader :jobName

  private

  def initializeBuilds
    response = getJSON("#{@baseUrl}?tree=builds[number]")

    response["builds"]
      .map {|b| b["number"]}
      .each{|num|
        @builds[num] = Build.new(self, num) unless @builds.has_key? num
      }
  end

  def initializeDownstreamJobs
    return unless @lastPulledDownstreamJobs.nil? || @lastPulledDownstreamJobs + (60*60) <= Time.now

    response = getJSON("#{@baseUrl}?tree=downstreamProjects[name]")

    response["downstreamProjects"]
      .map {|p| p["name"] }
      .each {|project|
        @downstreamJobs[project] = jobCache.getJob project unless @downstreamJobs.has_key? project
      }

    @lastPulledDownstreamJobs = Time.now
  end

  def jobCache
    JobCache.instance
  end

end
