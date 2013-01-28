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

    it 'retrieves the shortened commit sha' do
      @map.stub(:shaFor).and_return('sha-test')
      @build.sha.should eq 'sha-test'[0,6]
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
    before :each do
      def @build.downstreamBuildsRaw
        @downstreamBuilds.each_value.map{|x| x}
      end
    end

    it 'returns empty list' do
      downstreamBuilds = @build.downstreamBuildsRaw
      downstreamBuilds.length.should eq 0
    end

    it 'adds build to list' do
      downstreamJob = double(Job)
      downstreamJob.stub(:jobName).and_return('downstreamJob')

      downstreamBuild = Build.new(downstreamJob, 15)
      @build.addDownstreamBuild downstreamBuild

      downstreamBuilds = @build.downstreamBuildsRaw
      downstreamBuilds.length.should eq 1

      downstreamBuilds[0].should be downstreamBuild
    end

    it 'stores the last build by job' do
      downstreamJob = double(Job)
      downstreamJob.stub(:jobName).and_return('downstreamJob')

      downstreamBuild1 = Build.new(downstreamJob, 15)
      downstreamBuild2 = Build.new(downstreamJob, 16)

      @build.addDownstreamBuild downstreamBuild1
      @build.addDownstreamBuild downstreamBuild2

      downstreamBuilds = @build.downstreamBuildsRaw
      downstreamBuilds.length.should eq 1

      downstreamBuilds[0].should be downstreamBuild2
    end

    it 'stores all downstream builds by job' do
      downstreamJob1 = double(Job)
      downstreamJob1.stub(:jobName).and_return('downstreamJob1')
      downstreamJob2 = double(Job)
      downstreamJob2.stub(:jobName).and_return('downstreamJob2')

      downstreamBuild1 = Build.new(downstreamJob1, 15)
      downstreamBuild2 = Build.new(downstreamJob2, 16)

      @build.addDownstreamBuild downstreamBuild1
      @build.addDownstreamBuild downstreamBuild2

      downstreamBuilds = @build.downstreamBuildsRaw
      downstreamBuilds.length.should eq 2

      downstreamBuilds[0].should be downstreamBuild1
      downstreamBuilds[1].should be downstreamBuild2
    end
  end

  describe '#downstreamBuilds' do
    before :each do
      @jobCache = double(JobCache)
      @jobCache.stub(:getJob).with(@job.jobName).and_return(@job)

      @job.stub(:getBuild).with(5).and_return(@build)

      @downstreamJobs = []
      for i in 1..5
        downstreamJob = double(Job)
        downstreamJob.stub(:jobName).and_return("downstreamJob#{i}")

        builds = []

        for j in 1..5
          b = Build.new(downstreamJob, i*j)
          b.stub(:getUpstreamBuild).and_return(nil)
          builds << b
        end

        downstreamJob.stub(:jobCache).and_return(@jobCache)
        downstreamJob.stub(:lastXBuilds).with(nil).and_return(builds)
        @downstreamJobs << downstreamJob
      end

      @job.stub(:downstreamProjects).and_return(@downstreamJobs)
    end

    it 'build temporary builds' do
      builds = @build.downstreamBuilds
      builds.length.should eq @downstreamJobs.length
      builds.each {|b|
        b.should be_an_instance_of TemporaryBuild
        b.status.should eq 'NOTRUN'
      }
    end

    it 'returns downstream build if has been started' do
      expBuild = @downstreamJobs[0].lastXBuilds(nil)[0]
      expBuild.stub(:upstreamBuild).and_return(@build)

      builds = @build.downstreamBuilds
      builds.length.should eq @downstreamJobs.length

      nonTemp = builds.find {|b| b.kind_of? Build}
      nonTemp.nil?.should eq false
      nonTemp.should be expBuild

      builds.reject{|b|
        b.kind_of? Build
      }
      .each {|b|
        b.should be_an_instance_of TemporaryBuild
        b.status.should eq 'NOTRUN'
      }.count.should eq 4
    end
  end

end
