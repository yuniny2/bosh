module Bosh::Director
  module DeploymentPlan
    module Steps
      class DetachDisksStep
        def initialize(instance_plan)
          @instance_plan = instance_plan
          @logger = Config.logger
        end

        def perform
          cloud_factory = CloudFactory.create_with_latest_configs
          instance_model = @instance_plan.instance.model

          if instance_model.active_vm
            cloud = cloud_factory.get(instance_model.active_vm.cpi)

            instance_model.persistent_disks.each do |disk|
              begin
                @logger.info("Detaching disk #{disk.disk_cid}")
                cloud.detach_disk(disk.disk_cid)
              rescue Bosh::Clouds::DiskNotAttached
                if disk.active
                  raise CloudDiskNotAttached,
                        "'#{instance_model}' VM should have persistent disk " \
                        "'#{disk.disk_cid}' attached but it doesn't (according to CPI)"
                end
              end
            end
          end
        end
      end
    end
  end
end
