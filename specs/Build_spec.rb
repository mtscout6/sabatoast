require_relative './spec_helper'

describe 'Build' do

  before :each do
    @requester = double(JenkinsRequest)
    @build = Build.new('someJob', 5, @requester)
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
      status = @build.status
      status.should eq "RUNNING"
    end

    it "returns build result if job is not building" do
      stubResult('{ "building" : false, "result" : "SOMERESULT" }')
      status = @build.status
      status.should eq "SOMERESULT"
    end

    def stubResult(json)
      @requester.stub(:getJSON).with(/tree=building,result/).and_return(JSON.parse(json))
    end
  end

end
