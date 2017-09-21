module Bosh::Director
  module DeploymentPlan
    class Vm
      include ValidationHelper

      attr_reader :cpu

      attr_reader :ram

      attr_reader :ephemeral_disk

      def initialize(spec)
        @cpu = safe_property(spec, 'cpu', class: Integer)
        @ram = safe_property(spec, 'ram', class: Integer)
        @ephemeral_disk = safe_property(spec, 'ephemeral_disk', class: Integer)
      end

      def spec
        {
          'cpu' => @cpu,
          'ram' => @ram,
          'ephemeral_disk' => @ephemeral_disk,
        }
      end
    end
  end
end
