module Bosh::Director
  module DeploymentPlan
    module Steps
      class UpdateInstanceSettingsStep
        def initialize(instance_model, vm, agent_client)
          @instance_model = instance_model
          @vm = vm
          @agent_client = agent_client 
        end

        def perform(cloud_properties={})
        disk_associations = @instance_model.reload.active_persistent_disks.collection.select do |disk|
          !disk.model.managed?
        end
        disk_associations.map! do |disk|
           {'name' => disk.model.name, 'cid' => disk.model.disk_cid}
        end

        @agent_client.update_settings(Config.trusted_certs, disk_associations)
        @instance_model.active_vm.update(:trusted_certs_sha1 => ::Digest::SHA1.hexdigest(Config.trusted_certs))

        @instance_model.update(cloud_properties: JSON.dump(cloud_properties))
        end
      end
    end
  end
end
