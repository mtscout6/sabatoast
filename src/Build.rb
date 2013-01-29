require_relative './JenkinsRequest'

class Build
  include JenkinsRequest

  def initialize(job, buildNumber)
    @job = job
    @buildNumber = buildNumber

    @url = "/job/#{@job.jobName}/#{buildNumber}"
    @apiUrl = "#{@url}/api/json"

    @downstreamBuilds = Hash.new

    @currentStatus = "NOTRUN"
  end

  def status
    if (@currentStatus == "NOTRUN" || @currentStatus == "RUNNING")
      updateStatus
    end

    @currentStatus
  end

  def branch
    result = @job.buildToBranchMap.branchFor buildNumber
    result.sub('f-','').gsub(/(_|\-)/,' ').gsub(/([a-z])([A-Z])/,'\1 \2')
  end

  def sha
    shortSha = nil
    longSha = @job.buildToBranchMap.shaFor(buildNumber)
    shortSha = longSha[0,6] unless longSha.nil?
    shortSha
  end

  def upstreamBuild
    getUpstreamBuild
    @upstreamBuild
  end

  def downstreamBuilds
    @job.downstreamProjects.each do |project|
      hasBuild = @downstreamBuilds.has_key?(project.jobName) && @downstreamBuilds[project.jobName].kind_of?(Build)

      unless hasBuild
        build = project.lastXBuilds(nil).find() {|b| b.upstreamBuild == self }
        build = TemporaryBuild.new(project, self) if build.nil?
        @downstreamBuilds[project.jobName] = build
      end
    end

    @downstreamBuilds.each_value
  end

  def addDownstreamBuild(build)
    @downstreamBuilds[build.job.jobName] = build
  end

  attr_reader :buildNumber, :url, :job

  private

  def updateStatus
    response = getJSON("#{@apiUrl}?tree=building,result")
    isRunning = response["building"]

    if (isRunning)
      @currentStatus = "RUNNING"
    else
      @currentStatus = "NOTRUN"
      @currentStatus = response["result"] unless response["result"].nil?
      @currentStatus = "FAILURE" if @currentStatus == "ABORTED"
    end
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
    JobCache.instance
  end

end

class TemporaryBuild
  def initialize(job, upstreamBuild)
    @upstreamBuild = upstreamBuild
    @status = 'NOTRUN'
    @url = job.url
    @job = job
  end

  attr_reader :upstreamBuild, :status, :url, :job
end
