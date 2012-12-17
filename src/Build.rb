require_relative './JenkinsRequest'

class Build
  include JenkinsRequest

  def initialize(job, buildNumber)
    @job = job
    @buildNumber = buildNumber

    @url = "/job/#{@job.jobName}/#{buildNumber}"
    @apiUrl = "/#{@url}/api/json"

    @isRunning = true
    @currentStatus = "RUNNING"
  end

  def status
    updateStatus if @isRunning
    @currentStatus
  end

  def branch
    @job.buildToBranchMap.branchFor buildNumber
  end

  def sha
    @job.buildToBranchMap.shaFor buildNumber
  end

  def upstreamBuild
    getUpstreamBuild unless @fetchedUpstreamBuild
    @upstreamBuild
  end

  def addDownstreamBuild(build)
    # TODO Implement
  end

  attr_reader :buildNumber, :url, :job

  private

  def updateStatus
    response = getJSON("#{@apiUrl}?tree=building,result")
    @isRunning = response["building"]
    @currentStatus = response["result"] unless @isRunning
  end

  def getUpstreamBuild
    return @upstreamBuild if @fetchedUpstreamBuild
    @fetchedUpstreamBuild = true

    index = getUpstreamBuildIndex
    return if index.nil?

    @upstreamBuild = jobCache.getJob(index[:jobName]).getBuild(index[:buildNumber])
    @upstreamBuild.addDownstreamBuild self
  end

  def getUpstreamBuildIndex
    response = getJSON("#{@apiUrl}?tree=actions[causes[upstreamBuild,upstreamProject]]")

    causesIndex = response["actions"].index {|n| n.has_key? "causes" }
    return nil if causesIndex.nil?
    causes = response["actions"][causesIndex]["causes"]

    upstreamInfo = causes.find {|n| n.has_key? "upstreamBuild" }
    return nil if upstreamInfo.nil?

    {
      :jobName => upstreamInfo["upstreamProject"],
      :buildNumber => upstreamInfo["upstreamBuild"]
    }
  end

  def jobCache
    @job.jobCache
  end

end
