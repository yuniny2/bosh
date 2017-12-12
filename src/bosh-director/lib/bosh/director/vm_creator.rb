require 'common/deep_copy'
require 'securerandom'

module Bosh::Director
  # Creates VM model and call out to CPI to create VM in IaaS
  class VmCreator
    include PasswordHelper

    def initialize(logger, vm_deleter, disk_manager, template_blob_cache, dns_encoder, agent_broadcaster)
      @logger = logger
      @vm_deleter = vm_deleter
      @disk_manager = disk_manager
      @template_blob_cache = template_blob_cache
      @dns_encoder = dns_encoder
      @agent_broadcaster = agent_broadcaster

      @config_server_client_factory = Bosh::Director::ConfigServer::ClientFactory.create(@logger)
    end

    def create_for_instance_plans(instance_plans, ip_provider, tags={})
      return @logger.info('No missing vms to create') if instance_plans.empty?

      total = instance_plans.size
      event_log_stage = Config.event_log.begin_stage('Creating missing vms', total)
      ThreadPool.new(max_threads: Config.max_threads, logger: @logger).wrap do |pool|
        instance_plans.each do |instance_plan|
          instance = instance_plan.instance
          pool.process do
            with_thread_name("create_missing_vm(#{instance.model}/#{total})") do
              event_log_stage.advance_and_track(instance.model.to_s) do
                @logger.info('Creating missing VM')
                disks = [instance.model.managed_persistent_disk_cid].compact
                create_for_instance_plan(instance_plan, disks, tags)
                instance_plan.release_obsolete_network_plans(ip_provider) # this should move
              end
            end
          end
        end
      end
    end

    # def create_vm(instance_plan, disks, use_existing=false)
    #   instance = instance_plan.instance

    #   factory, stemcell_cid = choose_factory_and_stemcell_cid(instance_plan, use_existing)

    #   instance_model = instance.model
    #   @logger.info('Creating VM')

    #   # create the vm
    #   vm = create(
    #     instance,
    #     stemcell_cid,
    #     instance.cloud_properties,
    #     instance_plan.network_settings_hash,
    #     disks,
    #     instance.env,
    #     factory
    #   )

    #   begin
    #     # update metadata
    #     # this always changes the active vm!!!!
    #     MetadataUpdater.build.update_vm_metadata(instance_model, tags, factory)
    #     agent_client = AgentClient.with_agent_id(instance_model.agent_id)
    #     agent_client.wait_until_ready

    #     # delete arp entries from all other agents
    #     if Config.flush_arp
    #       ip_addresses = instance_plan.network_settings_hash.map do |index, network|
    #         network['ip']
    #       end.compact

    #       @agent_broadcaster.delete_arp_entries(instance_model.vm_cid, ip_addresses)
    #     end
    #   end
    #   rescue Exception => e
    #     # cleanup in case of failure
    #     @logger.error("Failed to create/contact VM #{instance_model.vm_cid}: #{e.inspect}")
    #     if Config.keep_unreachable_vms
    #       @logger.info('Keeping the VM for debugging')
    #     else
    #       @vm_deleter.delete_for_instance(instance_model)
    #     end
    #     raise e
    # end

    # def update_setting

    #   # send trusted certs and unmanaged disk info to agent
    #   ## FIXME: this always uses active vm!!!
    #   instance.update_instance_settings
    #   # update instance model's cloud_properties column
    #   instance.update_cloud_properties!
    # end

    def create_for_instance_plan(instance_plan, disks, tags, use_existing=false)
      DeploymentPlan::Steps::CreateVmStep.new(
        instance_plan,
        @agent_broadcaster,
        @vm_deleter,
        disks,
        tags, # definitelyd on't need to put these tags here, because they come off the instance plan
        use_existing,
      ).perform

      instance = instance_plan.instance
      DeploymentPlan::Steps::ElectActiveVmStep.new(instance_plan, instance.model.most_recent_inactive_vm).perform

      begin
        # attach disks
        # NOTE: this method is only used here
        DeploymentPlan::Steps::AttachInstanceDisksStep.new(instance_plan, instance.model.active_vm).perform

        # send trusted certs and unmanaged disk info to agent
        ## FIXME: this always uses active vm!!!
        # step.new(instance_model, vm).perform
        instance.update_instance_settings
        # update instance model's cloud_properties column
        instance.update_cloud_properties!
      rescue Exception => e
        # cleanup in case of failure
        @logger.error("Failed to create/contact VM #{instance.model.vm_cid}: #{e.inspect}")
        # TODO what is appropriate response to this error case ? orphan ?
        if Config.keep_unreachable_vms
          @logger.info('Keeping the VM for debugging')
        else
          @vm_deleter.delete_for_instance(instance.model)
        end
        raise e
      end

      # use a STANDARD way to get the "new vm" off the instance

      vm = instance.model.active_vm
      # apply initial state (collection of steps)
      apply_initial_vm_state(instance_plan, vm)

      # def perform
      #   vm = @instance_plan.instance.most_recent_inactive_vm
      #   apply_initial_vm_state(instance_plan, vm)
      # end

      # update instance_plan state
      # per story task, move this to where we activate the vm
      instance_plan.mark_desired_network_plans_as_existing
    end

    private

    def add_event(deployment_name, instance_name, action, object_name = nil, parent_id = nil, error = nil)
      event = Config.current_job.event_manager.create_event(
        {
          parent_id: parent_id,
          user: Config.current_job.username,
          action: action,
          object_type: 'vm',
          object_name: object_name,
          task: Config.current_job.task_id,
          deployment: deployment_name,
          instance: instance_name,
          error: error
        })
      event.id
    end

    def apply_initial_vm_state(instance_plan, vm)
      vm_state = DeploymentPlan::VmSpecApplier.new.apply_initial_vm_state(instance_plan.spec, vm)

      instance_plan.instance.add_state_to_model(vm_state)

      DeploymentPlan::Steps::RenderInstanceJobTemplatesStep.new(instance_plan, blob_cache: @template_blob_cache, dns_encoder: @dns_encoder).perform
    end

    def choose_factory_and_stemcell_cid(instance_plan, use_existing)
      if use_existing && !!instance_plan.existing_instance.availability_zone
        factory = CloudFactory.create_from_deployment(instance_plan.existing_instance.deployment)

        stemcell = instance_plan.instance.stemcell
        cpi = factory.get_name_for_az(instance_plan.existing_instance.availability_zone)
        stemcell_cid = stemcell.models.find { |model| model.cpi == cpi }.cid
        return factory, stemcell_cid
      else
        return CloudFactory.create_with_latest_configs, instance_plan.instance.stemcell_cid
      end
    end
  end
end
