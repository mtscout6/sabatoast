require_relative './spec_helper'

describe Job do

  before :each do
    @cache = JobCache.new
    @job = Job.new 'someJobName', @cache
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
      @job.stub(:getJSON).with(/builds/).and_return(JSON.parse('{ "builds" : [ { "number" : "1" }, { "number" : "2" }, { "number" : "3" }, { "number" : "4" }, { "number" : "5" }, { "number" : "6" }] }'))
    end

    it "requests build numbers" do
      @job.should_receive(:getJSON).with(/builds/).once
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
      @job.should_receive(:getJSON).with(/builds/).twice

      result1 = @job.lastXBuilds(1)
      result2 = @job.lastXBuilds(1)

      result1[0].should be result2[0]
    end
  end

  describe 'downstreamProjects' do
    before :each do
      @job.stub(:getJSON).with(/downstreamProjects/).and_return(JSON.parse('{ "downstreamProjects" : [ { "name" : "proj1" }, { "name" : "proj2" }, { "name" : "proj3" }, { "name" : "proj4" } ] }'))
    end

    it 'gets list of downstream projects' do
      projects = @job.downstreamProjects
      projects.count.should eq 4
    end

    it 'gets same projects as found in cache' do
      projects = @job.downstreamProjects
      projects.each {|p| p.should be @cache.getJob p.jobName }
    end

    it 'caches the results' do
      @job.should_receive(:getJSON).with(/downstreamProjects/).once
      @job.downstreamProjects
      @job.downstreamProjects
    end

    it 'caches the results for an hour' do
      @job.should_receive(:getJSON).with(/downstreamProjects/).once
      Time.stub(:now).and_return(Time.local(2012,1,1,1,0,0))
      @job.downstreamProjects
      Time.stub(:now).and_return(Time.local(2012,1,1,1,59,59))
      @job.downstreamProjects
    end

    it 'resets cached results on the hour' do
      @job.should_receive(:getJSON).with(/downstreamProjects/).twice
      Time.stub(:now).and_return(Time.local(2012,1,1,1,0,0))
      @job.downstreamProjects
      Time.stub(:now).and_return(Time.local(2012,1,1,2,0,0))
      @job.downstreamProjects
    end

    it 'resets cached results just after the hour' do
      @job.should_receive(:getJSON).with(/downstreamProjects/).twice
      Time.stub(:now).and_return(Time.local(2012,1,1,1,0,0))
      @job.downstreamProjects
      Time.stub(:now).and_return(Time.local(2012,1,1,2,0,1))
      @job.downstreamProjects
    end

  end

end
