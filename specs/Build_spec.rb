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

  describe '#upstreamBuild' do
    before :each do
      @cache = double(JobCache)

      @upstreamJob = double(Job)
      @upstreamJob.stub(:jobName).and_return('upstreamJob')

      @upstreamBuild = Build.new(@upstreamJob, 3)

      @upstreamJob.stub(:getBuild).with(3).and_return(@upstreamBuild)
      @cache.stub(:getJob).with("upstreamJob").and_return(@upstreamJob)

      @build.stub(:jobCache).and_return @cache
    end

    describe 'with upstream' do
      before :each do
        @build.stub(:getJSON).with(/tree=actions\[causes/).and_return(JSON.parse('{ "actions" : [ { "causes" : [ { "upstreamBuild" : 3, "upstreamProject" : "upstreamJob" }, { }, { } ] }, { }, { }, { } ] }'))
      end

      it 'caches the result' do
        @build.should_receive(:getJSON).with(/tree=actions\[causes/).once
        first = @build.upstreamBuild
        second = @build.upstreamBuild

        first.should be second
      end

      it 'returns the upstream build' do
        @build.upstreamBuild.should be_an_instance_of Build
        @build.upstreamBuild.buildNumber.should eq 3
        @build.upstreamBuild.job.jobName.should eq 'upstreamJob'
      end

      it 'adds itself to the upstream builds list of child builds' do
        @upstreamBuild.should_receive(:addDownstreamBuild).with(@build).once
        @build.upstreamBuild
      end
    end

    describe 'without upstream' do
      before :each do
        @build.stub(:getJSON).with(/tree=actions\[causes/).and_return(JSON.parse('{ "actions" : [ { "causes" : [ { }, { }, { } ] }, { }, { }, { } ] }'))
      end

      it 'caches the result' do
        @build.should_receive(:getJSON).with(/tree=actions\[causes/).once
        first = @build.upstreamBuild
        second = @build.upstreamBuild

        first.should be second
      end

      it 'returns nil' do
        @build.upstreamBuild.should be nil
      end

      it 'does not add itself to an upstream build' do
        @upstreamBuild.should_receive(:addDownstreamBuild).with(@build).never
        @build.upstreamBuild
      end
    end
  end

  describe '#addDownstreamBuild' do
    it 'should be implemented' do
      2.should eq 1
    end
  end

end
