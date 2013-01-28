require_relative './Job'
require 'singleton'

class JobCache
  include Singleton

  def getJob(job)
    @jobs = Hash.new if @jobs.nil?
    @jobs[job] = Job.new(job) unless @jobs.has_key? job
    return @jobs[job]
  end
end
