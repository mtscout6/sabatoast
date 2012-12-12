require_relative './Job'

class JobCache
  def initialize(requester)
    @jobs = Hash.new
    @requester = requester
  end

  def getJob(job)
    @jobs[job] = Job.new(job, self, @requester) unless @jobs.has_key? job
    return @jobs[job]
  end
end
