module Bosh::Director
  module DeploymentPlan
    module Steps
      class AttachInstanceDisksStep
        def initialize(instance_plan, vm)
          @instance_plan = instance_plan
          @vm = vm
        end

        def perform
          if @instance_plan.needs_disk?
            @instance_plan.instance.model.active_persistent_disks.each do |disk|
              AttachDiskStep.new(disk.model, @vm, @instance_plan.tags).perform
            end
          else
            Config.logger.warn('Skipping disk attachment, instance no longer needs disk')
          end
        end
      end
    end
  end
end
