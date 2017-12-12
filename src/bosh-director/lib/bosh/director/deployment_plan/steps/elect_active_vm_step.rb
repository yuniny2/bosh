module Bosh::Director
  module DeploymentPlan
    module Steps
      class ElectActiveVmStep
        def initialize(instance_plan, vm)
          @instance_plan = instance_plan
          @vm = vm
        end

        def perform
          @instance_plan.instance.model.active_vm = @vm
        end
      end
    end
  end
end
