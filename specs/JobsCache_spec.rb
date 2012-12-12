require_relative './spec_helper'

describe 'JobCache' do

  before :each do
    @cache = JobCache.new double(JenkinsRequest)
  end

  describe "getJob" do
    it "creates job if not already present" do
      @cache.getJob("someJob").should be_an_instance_of Job
    end

    it "returns same job by name after created" do
      job1 = @cache.getJob "someJob"
      job2 = @cache.getJob "someJob"

      job1.should be job2
    end

    it "returns different jobs by name" do
      job1 = @cache.getJob "someJob"
      job2 = @cache.getJob "otherJob"

      job1.should_not be job2
    end
  end
end
