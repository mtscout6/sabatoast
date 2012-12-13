require_relative './JenkinsRequest'

class Build
  include JenkinsRequest

  def initialize(job, buildNumber)
    @job = job
    @buildNumber = buildNumber

    @baseUrl = "/job/#{@job.jobName}/#{buildNumber}/api/json"

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

  attr_reader :buildNumber

  private

  def updateStatus
    response = getJSON("#{@baseUrl}?tree=building,result")
    @isRunning = response["building"]
    @currentStatus = response["result"] unless @isRunning
  end
end
