require_relative './JenkinsRequest'

class Build
  include JenkinsRequest

  def initialize(jobName, buildNumber)
    @jobName = jobName
    @buildNumber = buildNumber

    @baseUrl = "/job/#{jobName}/#{buildNumber}/api/json"

    @isRunning = true
    @currentStatus = "RUNNING"
  end

  def status()
    updateStatus if @isRunning
    @currentStatus
  end

  attr_reader :jobName, :buildNumber

  private

  def updateStatus
    response = getJSON("#{@baseUrl}?tree=building,result")
    @isRunning = response["building"]
    @currentStatus = response["result"] unless @isRunning
  end
end
