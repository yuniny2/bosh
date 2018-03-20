module Bosh::Director
  module DeploymentPlan
    class VipNetwork < Network
      include IpUtil
      extend ValidationHelper

      # @return [Hash] Network cloud properties
      attr_reader :cloud_properties
      attr_reader :subnets

      ##
      # Creates a new network.
      #
      # @param [Hash] network_spec parsed deployment manifest network section
      # @param [Logger] logger
      def self.parse(network_spec, availability_zones, logger)
        name = safe_property(network_spec, "name", :class => String)
        subnet_specs = safe_property(network_spec, 'subnets', class: Array, default: [])
        cloud_properties = safe_property(network_spec, "cloud_properties", class: Hash, default: {})

        subnets = []
        subnet_specs.each do |spec|
          subnets << VipNetworkSubnet.parse(spec, availability_zones)
        end

        new(name, subnets, cloud_properties, logger)
      end

      def initialize(name, subnets, cloud_properties, logger)
        @subnets = subnets
        @reserved_ips = Set.new
        @logger = TaggedLogger.new(logger, 'network-configuration')
        @cloud_properties = cloud_properties

        super(name, logger)
      end

      ##
      # Returns the network settings for the specific reservation.
      #
      # @param [NetworkReservation] reservation
      # @param [Array<String>] default_properties
      # @return [Hash] network settings that will be passed to the BOSH Agent
      def network_settings(reservation, default_properties = REQUIRED_DEFAULTS, availability_zone = nil)
        if default_properties && !default_properties.empty?
          raise NetworkReservationVipDefaultProvided,
                "Can't provide any defaults since this is a VIP network"
        end

        {
          "type" => "vip",
          "ip" => ip_to_netaddr(reservation.ip).ip,
          "cloud_properties" => @cloud_properties
        }
      end

      def ip_type(_)
        :static
      end

      def has_azs?(az_names)
        true
      end
    end
  end
end
