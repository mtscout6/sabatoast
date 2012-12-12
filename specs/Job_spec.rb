require_relative './spec_helper'

describe 'Job' do

  before :each do
    @cache = double(JobCache)
    @requester = double(JenkinsRequest)

    @requester.stub(:getJSON).with(/downstreamProjects/).and_return(JSON.parse('{ "downstreamProjects" : [] }'))

    @job = Job.new 'someJobName', @cache, @requester
  end

  describe "readonly jobName property" do
    it "returns job name" do
      @job.jobName.should eq 'someJobName'
    end

    it "cannot be set externally" do
      lambda { @job.jobName = 'newJobName' }.should raise_error(NoMethodError)
    end
  end

  describe "lastXBuilds" do
    before :each do
      @requester.stub(:getJSON).and_return(JSON.parse('{ "builds" : [ { "number" : "1" }, { "number" : "2" }, { "number" : "3" }, { "number" : "4" }, { "number" : "5" }, { "number" : "6" }] }'))
    end

    it "requests build numbers" do
      @requester.should_receive(:getJSON).once
      result1 = @job.lastXBuilds(1)
    end

    it "gets 3 builds" do
      result = @job.lastXBuilds(3)
      result.length.should eq 3
    end

    it "gets build objects" do
      result = @job.lastXBuilds(1)
      result[0].should be_an_instance_of Build
    end

    it "gets latest builds" do
      result = @job.lastXBuilds(3)
      result[0].buildNumber.should eq "6"
      result[1].buildNumber.should eq "5"
      result[2].buildNumber.should eq "4"
    end

    it "gets same instance of build with each call" do
      @requester.should_receive(:getJSON).twice

      result1 = @job.lastXBuilds(1)
      result2 = @job.lastXBuilds(1)

      result1[0].should be result2[0]
    end

  end

end
