require_relative './Build'

class Job
  def initialize(jobName)
    @jobName = jobName
    @builds = Hash.new
  end

  def load(requestor)
    response = requestor.getJSON("/job/#{jobName}/api/json")
  end

  attr_reader :jobName
end
