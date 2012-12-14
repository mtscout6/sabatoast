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

  attr_reader :buildNumber, :url

  private

  def updateStatus
    response = getJSON("#{@apiUrl}?tree=building,result")
    @isRunning = response["building"]
    @currentStatus = response["result"] unless @isRunning
  end
end
