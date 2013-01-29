require_relative './JenkinsRequest'
require_relative './Build'
require_relative './BuildToBranchMap'

class Job
  include JenkinsRequest

  def initialize(jobName)
    @jobName = jobName

    @builds = Hash.new
    @downstreamJobs = Hash.new

    @url = "/job/#{jobName}"
    @baseUrl = "#{url}/api/json"
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

  attr_reader :jobName, :url

  private

  def initializeBuilds
    return unless @lastPulledBuildNumbers.nil? || @lastPulledBuildNumbers + (30) <= Time.now
    @lastPulledBuildNumbers = Time.now

    response = getJSON("#{@baseUrl}?tree=builds[number]")

    # TODO: Remove old builds no longer seen on Jenkins

    response["builds"]
      .map {|b| b["number"]}
      .each{|num|
        @builds[num] = Build.new(self, num) unless @builds.has_key? num
      }
  end

  def initializeDownstreamJobs
    # Pull once every hour
    return unless @lastPulledDownstreamJobs.nil? || @lastPulledDownstreamJobs + (60*60) <= Time.now
    @lastPulledDownstreamJobs = Time.now

    response = getJSON("#{@baseUrl}?tree=downstreamProjects[name]")

    response["downstreamProjects"]
      .map {|p| p["name"] }
      .each {|project|
        @downstreamJobs[project] = jobCache.getJob project unless @downstreamJobs.has_key? project
      }
  end

  def jobCache
    JobCache.instance
  end
end
