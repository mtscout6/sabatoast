class Build
  def initialize(jobName, buildNumber, requester)
    @jobName = jobName
    @buildNumber = buildNumber
    @requester = requester

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
    response = @requester.getJSON("#{@baseUrl}?tree=building,result")
    @isRunning = response["building"]
    @currentStatus = response["result"] unless @isRunning
  end
end
