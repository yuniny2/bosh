module Bosh::Director::DeploymentPlan
  module NetworkPlanner
    class VipStaticIpsPlanner
      def initialize(network_planner, job_networks, desired_azs, logger)
        @network_planner = network_planner
        @logger = logger
        @job_networks = job_networks
        @networks_to_static_ips = Bosh::Director::DeploymentPlan::PlacementPlanner::NetworksToStaticIps.create(@job_networks, desired_azs, 'vip')
        @logger = logger
      end

      def add_vip_network_plans(instance_plans, vip_networks)
        vip_networks.each do |vip_network|
          static_ips = Array(vip_network.static_ips.dup)
          deployment_network = vip_network.deployment_network

          unplaced_instance_plans = []
          instance_plans.each do |instance_plan|
            static_ip = get_instance_static_ip(instance_plan.existing_instance, vip_network.name, static_ips)
            if static_ip
              instance_plan.network_plans << @network_planner.network_plan_with_static_reservation(instance_plan, vip_network, static_ip)
            else
              unplaced_instance_plans << instance_plan
            end
          end

          unplaced_instance_plans.each do |instance_plan|
            if static_ips.empty?
              desired_instance = instance_plan.desired_instance
              instance = instance_plan.instance
              if desired_instance.az.nil?
                static_ip_to_azs = @networks_to_static_ips.next_ip_for_network(deployment_network)
                if static_ip_to_azs.az_names.size == 1
                  az_name = static_ip_to_azs.az_names.first
                  @logger.debug("Assigning az '#{az_name}' to instance '#{instance}'")
                else
                  az_name = find_az_name_with_least_number_of_instances(static_ip_to_azs.az_names, instance_plans)
                  @logger.debug("Assigning az '#{az_name}' to instance '#{instance}' based on least number of instances")
                end
                desired_instance.az = to_az(az_name)
              else
                static_ip_to_azs = @networks_to_static_ips.find_by_network_and_az(deployment_network, desired_instance.availability_zone)
              end

              if static_ip_to_azs.nil?
                raise Bosh::Director::NetworkReservationError,
                  'Failed to distribute static IPs to satisfy existing instance reservations'
              end

              static_ip_to_azs = @networks_to_static_ips.next_ip_for_network(deployment_network).ip

              @logger.debug("Claiming IP '#{format_ip(static_ip_to_azs.ip)}' on network #{network.name} and az '#{desired_instance.availability_zone}' for instance '#{instance}'")
              @networks_to_static_ips.claim_in_az(static_ip_to_azs.ip, desired_instance.availability_zone) 

              myip = static_ip_to_azs.ip
            else
              myip = static_ips.shift
            end
            instance_plan.network_plans << @network_planner.network_plan_with_static_reservation(instance_plan, vip_network, myip)
          end
        end
      end

      private

      def get_instance_static_ip(existing_instance, network_name, static_ips)
        if existing_instance
          existing_instance_ip = find_ip_for_network(existing_instance, network_name)
          if existing_instance_ip && static_ips.include?(existing_instance_ip)
            static_ips.delete(existing_instance_ip)
            return existing_instance_ip
          end
        end
      end

      def find_ip_for_network(existing_instance, network_name)
        ip_address = existing_instance.ip_addresses.find do |ip_address|
          ip_address.network_name == network_name
        end
        ip_address.address if ip_address
      end

      def find_az_name_with_least_number_of_instances(az_names, instance_plans)
        az_names.sort_by do |az_name|
          instance_plans.select { |instance_plan| instance_plan.desired_instance.availability_zone == az_name }.size
        end.first
      end
    end
  end
end
