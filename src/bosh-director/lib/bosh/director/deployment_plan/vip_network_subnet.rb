module Bosh::Director
  module DeploymentPlan
    class VipNetworkSubnet
      extend ValidationHelper
      extend IpUtil

      attr_reader :available, :availability_zones

      def self.parse(subnet_spec, availability_zones)
        available = safe_property(subnet_spec, 'available', class: Array, default: [])
        azs = parse_availability_zones(subnet_spec, availability_zones)
        new(available, azs)
      end

      def initialize(available, azs)
        @available = available
        @availability_zones = azs
      end

      private

      def self.parse_availability_zones(subnet_spec, availability_zones)
        has_availability_zones_key = subnet_spec.has_key?('azs')
        has_availability_zone_key = subnet_spec.has_key?('az')
        if has_availability_zones_key && has_availability_zone_key
          raise Bosh::Director::NetworkInvalidProperty, "Network 'vip' contains both 'az' and 'azs'. Choose one."
        end

        if has_availability_zones_key
          zones = safe_property(subnet_spec, 'azs', class: Array, optional: true)
          if zones.empty?
            raise Bosh::Director::NetworkInvalidProperty, "Network 'vip' refers to an empty 'azs' array"
          end
          zones.each do |zone|
            check_validity_of_subnet_availability_zone(zone, availability_zones)
          end
          zones
        else
          availability_zone_name = safe_property(subnet_spec, 'az', class: String, optional: true)
          check_validity_of_subnet_availability_zone(availability_zone_name, availability_zones)
          availability_zone_name.nil? ? nil : [availability_zone_name]
        end
      end

      def self.check_validity_of_subnet_availability_zone(availability_zone_name, availability_zones)
        unless availability_zone_name.nil? || availability_zones.any? { |az| az.name == availability_zone_name }
          raise Bosh::Director::NetworkSubnetUnknownAvailabilityZone, "Network 'vip' refers to an unknown availability zone '#{availability_zone_name}'"
        end
      end
    end
  end
end
