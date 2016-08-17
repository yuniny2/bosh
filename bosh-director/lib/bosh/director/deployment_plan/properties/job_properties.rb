module Bosh::Director::DeploymentPlan
  class JobProperties

    # @return [String] Job Name
    attr_reader :job_name

    # @return List of [Bosh::Director::DeploymentPlan::Property]
    attr_reader :properties


    def initialize(job_name)
      @job_name = job_name
      @properties = []
    end

    def add_property(property)
      @properties << property
    end

    # @return [Hash] properties as a Hash
    def spec

    end
  end
end
