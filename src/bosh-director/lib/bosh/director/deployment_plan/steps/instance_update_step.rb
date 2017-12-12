module Bosh::Director
  module DeploymentPlan
    module Steps
      class InstanceUpdateStep
        def initialize(disk, vm, tags)
          @disk = disk
          @logger = Config.logger
          @vm = vm
          @tags = tags
        end

        def perform
          return if @disk.nil?

          cloud_factory = CloudFactory.create_with_latest_configs
          cloud = cloud_factory.get(@disk.cpi)
          @logger.info("Attaching disk #{@disk.disk_cid}")
          cloud.attach_disk(@vm.cid, @disk.disk_cid)
          MetadataUpdater.build.update_disk_metadata(cloud, @disk, @tags)
        end
      end
    end
  end
end
