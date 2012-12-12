class Build
  def initialize(jobName, buildNumber)
    @jobName = jobName
    @buildNumber = buildNumber
  end

  attr_reader :jobName, :buildNumber
end
