require_relative './spec_helper'

describe JobCache do

  before :each do
  end

  describe "getJob" do
    it "creates job if not already present" do
      JobCache.instance.getJob("someJob").should be_an_instance_of Job
    end

    it "returns same job by name after created" do
      job1 = JobCache.instance.getJob "someJob"
      job2 = JobCache.instance.getJob "someJob"

      job1.should be job2
    end

    it "returns different jobs by name" do
      job1 = JobCache.instance.getJob "someJob"
      job2 = JobCache.instance.getJob "otherJob"

      job1.should_not be job2
    end

    it "should be singleton" do
      JobCache.instance.object_id.should be JobCache.instance.object_id
    end
  end
end
