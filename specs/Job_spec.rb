require_relative './spec_helper'

describe 'Job' do

  before :each do
    @job = Job.new 'someJobName'
  end

  describe "readonly jobName property" do
    it "returns job name" do
      @job.jobName.should eq 'someJobName'
    end

    it "cannot be set externally" do
      lambda { @job.jobName = 'newJobName' }.should raise_error(NoMethodError)
    end
  end

end
