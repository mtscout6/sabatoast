require_relative './JenkinsRequest'

class BuildToBranchMap
  include JenkinsRequest

  def initialize(jobName)
    @jobName = jobName

    @buildNumberToBranch = Hash.new
    @branchToBuildNumbers = Hash.new
  end

  def branchFor(buildNumber)
    getBranchInfo(buildNumber, :branch)
  end

  def shaFor(buildNumber)
    getBranchInfo(buildNumber, :sha)
  end

  def buildNumbersFor(branch)
    @branchToBuildNumbers[branch]
  end

  def branches
    @branchToBuildNumbers.each_key
  end

  private

  def getBranchInfo(buildNumber, key)
    retrieveBranchInfo(buildNumber) unless @buildNumberToBranch.has_key? buildNumber
    @buildNumberToBranch[buildNumber][key]
  end

  def retrieveBranchInfo(buildNumber)
    response = getJSON("/job/#{@jobName}/#{buildNumber}/api/json")

    idx = response["actions"].index { |a| a.has_key?("buildsByBranchName") }
    setBranchToDefault buildNumber if idx.nil?
    return if idx.nil?

    response["actions"][idx]["buildsByBranchName"].values
      .map {|build|
        {
          :num => build["buildNumber"],
          :branch => build["revision"]["branch"][0]["name"].sub(/origin\//, ''),
          :sha => build["revision"]["branch"][0]["SHA1"]
        }
      }
      .each{|build|
        @buildNumberToBranch[build[:num]] = {:branch => build[:branch], :sha => build[:sha]} unless @buildNumberToBranch.has_key? build[:num]

        @branchToBuildNumbers[build[:branch]] = SortedSet.new unless @branchToBuildNumbers.has_key? build[:branch]
        @branchToBuildNumbers[build[:branch]].add build[:num]
      }

    setBranchToDefault buildNumber
  end

  def setBranchToDefault(buildNumber)
    @buildNumberToBranch[buildNumber] = {:branch => nil, :sha => nil} unless @buildNumberToBranch[buildNumber]
  end
end
