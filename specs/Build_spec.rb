require_relative './spec_helper'

describe Build do

  before :each do
    @job = double(Job)
    @job.stub(:jobName).and_return('someJob')

    @build = Build.new(@job, 5)
  end

  describe "#buildNumber" do
    it "returns build number" do
      @build.buildNumber.should eq 5
    end

    it "cannot be set externally" do
      lambda { @build.buildNumber = 6 }.should raise_error(NoMethodError)
    end
  end

  describe "#url" do
    it "returns build url" do
      @build.url.should eq "/job/someJob/5"
    end

    it "cannot be set externally" do
      lambda { @build.url = "otherUrl" }.should raise_error(NoMethodError)
    end
  end

  describe "#status" do
    it "returns RUNNING if job is building" do
      stubResult('{ "building" : true, "result" : null }')
      @build.should_receive(:getJSON).with(/tree=building,result/).twice
      @build.status().should eq "RUNNING"
      @build.status().should eq "RUNNING"
    end

    it "returns build result if job is not building" do
      stubResult('{ "building" : false, "result" : "SOME RESULT" }')
      @build.should_receive(:getJSON).with(/tree=building,result/).once
      @build.status().should eq "SOME RESULT"
      @build.status().should eq "SOME RESULT"
    end

    def stubResult(json)
      @build.stub(:getJSON).with(/tree=building,result/).and_return(JSON.parse(json))
    end
  end

  describe "#branch" do
    before :each do
      @map = double(BuildToBranchMap)
      @job.stub(:buildToBranchMap).and_return(@map)
    end

    it 'retrieves no name' do
      @map.stub(:branchFor).and_return(nil)
      @build.branch.should eq nil
    end

    it 'retrieves the branch name' do
      @map.stub(:branchFor).and_return('someBranch')
      @build.branch.should eq 'someBranch'
    end
  end

  describe "#sha" do
    before :each do
      @map = double(BuildToBranchMap)
      @job.stub(:buildToBranchMap).and_return(@map)
    end

    it 'retrieves no commit sha' do
      @map.stub(:shaFor).and_return(nil)
      @build.sha.should eq nil
    end

    it 'retrieves the commit sha' do
      @map.stub(:shaFor).and_return('sha-test')
      @build.sha.should eq 'sha-test'
    end
  end

end
