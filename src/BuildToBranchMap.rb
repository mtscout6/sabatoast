require_relative './JenkinsRequest'

class BuildToBranchMap
  include JenkinsRequest

  def initialize(jobName)
    @jobName = jobName

    @buildNumberToBranch = Hash.new
    @branchToBuildNumbers = Hash.new
  end

  def branchFor(buildNumber)
    return @buildNumberToBranch[buildNumber] if @buildNumberToBranch.has_key? buildNumber

    getBranchInfo(buildNumber).each{|build|
      @buildNumberToBranch[build[:num]] = build[:branch] unless @buildNumberToBranch.has_key? build[:num]

      @branchToBuildNumbers[build[:branch]] = SortedSet.new unless @branchToBuildNumbers.has_key? build[:branch]
      @branchToBuildNumbers[build[:branch]].add build[:num]
    }

    @buildNumberToBranch[buildNumber]
  end

  def buildNumbersFor(branch)
    @branchToBuildNumbers[branch]
  end

  def branches
    @branchToBuildNumbers.each_key
  end

  private

  def getBranchInfo(buildNumber)
    response = getJSON("/job/#{@jobName}/#{buildNumber}/api/json")

    idx = response["actions"].index { |a| a.has_key?("buildsByBranchName") }
    return if idx.nil?

    response["actions"][idx]["buildsByBranchName"].values
      .map {|build|
        {
          :num => build["buildNumber"],
          :branch => build["revision"]["branch"][0]["name"].sub(/origin\//, ''),
        }
      }
  end

end
