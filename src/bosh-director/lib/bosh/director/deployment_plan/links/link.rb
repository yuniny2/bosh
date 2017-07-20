module Bosh::Director
  module DeploymentPlan
    class Link
      attr_reader :name

      def initialize(provider_deployment_name, name, source_instance_group, job, network_name=nil)
        @provider_deployment_name = provider_deployment_name # Provider Deployment Name
        @name = name
        @source_instance_group = source_instance_group
        @network_name = network_name
        @job = job
      end

      def spec
        instance_plan = @source_instance_group.needed_instance_plans.first
        if instance_plan
          root_domain = instance_plan.root_domain
        else
          root_domain = Bosh::Director::Config.root_domain
        end

        if !@network_name.nil?
          network = @network_name
        else
          network = @source_instance_group.default_network_name
        end

        {
          'deployment_name' => @provider_deployment_name,
          'domain' => root_domain,
          'default_network' => network,
          'networks' => @source_instance_group.networks.map { |network| network.name },
          'instance_group' => @source_instance_group.name,
          'properties' => @job.provides_link_info(@source_instance_group.name, @name)['mapped_properties'],
          'instances' => @source_instance_group.needed_instance_plans.map do |instance_plan|
            network_address = instance_plan.network_address(@network_name)

            instance = instance_plan.instance
            availability_zone = instance.availability_zone.name if instance.availability_zone
            {
              'name' => @source_instance_group.name,
              'id' => instance.uuid,
              'index' => instance.index,
              'bootstrap' => instance.bootstrap?,
              'az' => availability_zone,
              'address' => network_address,
              'addresses' => instance_plan.network_addresses(true),
              'ip_addresses' => instance_plan.network_addresses(false),
            }
          end
        }
      end
    end
  end
end
