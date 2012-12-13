require_relative './spec_helper'

describe BuildToBranchMap do

  before :each do
    @map = BuildToBranchMap.new 'someJob'
    @map.stub(:getJSON).and_return(
      JSON.parse('{ "actions" : [ { "buildsByBranchName" : { "origin/branch1" : { "buildNumber" : 1, "buildResult" : null, "revision" : { "SHA1" : "sha-1", "branch" : [ { "SHA1" : "sha-1", "name" : "origin/branch1" } ] } }, "origin/branch2" : { "buildNumber" : 2, "buildResult" : null, "revision" : { "SHA1" : "sha-2", "branch" : [ { "SHA1" : "sha-2", "name" : "origin/branch2" } ] } }, "origin/branch3" : { "buildNumber" : 3, "buildResult" : null, "revision" : { "SHA1" : "sha-3", "branch" : [ { "SHA1" : "sha-3", "name" : "origin/branch3" } ] } } } } ] }'),
      JSON.parse('{ "actions" : [ { "buildsByBranchName" : { "origin/branch1" : { "buildNumber" : 4, "buildResult" : null, "revision" : { "SHA4" : "sha-4", "branch" : [ { "SHA4" : "sha-4", "name" : "origin/branch1" } ] } }, "origin/branch2" : { "buildNumber" : 5, "buildResult" : null, "revision" : { "SHA1" : "sha-5", "branch" : [ { "SHA1" : "sha-5", "name" : "origin/branch2" } ] } }, "origin/branch3" : { "buildNumber" : 6, "buildResult" : null, "revision" : { "SHA1" : "sha-6", "branch" : [ { "SHA1" : "sha-6", "name" : "origin/branch3" } ] } } } } ] }'))
  end

  describe '#branchFor' do
    it 'requests branch info' do
      @map.should_receive(:getJSON).once
      @map.branchFor 1
      @map.branchFor 2
      @map.branchFor 3
    end

    it 'requests branch info if build is not in cache' do
      @map.should_receive(:getJSON).twice
      @map.branchFor 1
      @map.branchFor 2
      @map.branchFor 3
      @map.branchFor 4
      @map.branchFor 5
      @map.branchFor 6
    end

    it 'returns the branch name' do
      @map.branchFor(1).should eq 'branch1'
      @map.branchFor(2).should eq 'branch2'
      @map.branchFor(3).should eq 'branch3'
      @map.branchFor(4).should eq 'branch1'
      @map.branchFor(5).should eq 'branch2'
      @map.branchFor(6).should eq 'branch3'
    end
  end

  describe '#buildNumbersFor' do
    it 'returns nil if nothing is found' do
      @map.buildNumbersFor('branch1').should be nil
    end

    it 'returns all known build numbers for branch' do
      @map.branchFor 1

      @map.buildNumbersFor('branch1').should eq SortedSet.new([1])
      @map.buildNumbersFor('branch2').should eq SortedSet.new([2])
      @map.buildNumbersFor('branch3').should eq SortedSet.new([3])

      @map.branchFor 4

      @map.buildNumbersFor('branch1').should eq SortedSet.new([1, 4])
      @map.buildNumbersFor('branch2').should eq SortedSet.new([2, 5])
      @map.buildNumbersFor('branch3').should eq SortedSet.new([3, 6])
    end
  end

  describe '#branches' do
    it 'returns an empty list of branches' do
      @map.branches.count.should eq 0
    end

    it 'returns a list of all known branches' do
      @map.branchFor 1

      branches = @map.branches.map{|i| i}
      branches.length.should eq 3

      branches[0].should eq 'branch1'
      branches[1].should eq 'branch2'
      branches[2].should eq 'branch3'
    end
  end

end
