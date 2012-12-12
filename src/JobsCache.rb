require_relative './Job'

class JobCache
  def initialize
    @jobs = Hash.new
  end

  def getJob(job)
    @jobs[job] = Job.new job unless @jobs.has_key? job
    return @jobs[job]
  end
end
