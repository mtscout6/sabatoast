require_relative './spec_helper'

describe Build do

  before :each do
    @build = Build.new('someJob', 5)
  end

  describe "readonly jobName property" do
    it "returns job name" do
      @build.jobName.should eq 'someJob'
    end

    it "cannot be set externally" do
      lambda { @build.jobName = 'newJobName' }.should raise_error(NoMethodError)
    end
  end

  describe "readonly buildNumber property" do
    it "returns build number" do
      @build.buildNumber.should eq 5
    end

    it "cannot be set externally" do
      lambda { @build.buildNumber = 6 }.should raise_error(NoMethodError)
    end
  end

  describe "status" do
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

end
