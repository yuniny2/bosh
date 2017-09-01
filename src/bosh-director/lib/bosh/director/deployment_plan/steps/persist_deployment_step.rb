module Bosh::Director
  module DeploymentPlan
    module Steps
      class PersistDeploymentStep

        def initialize(deployment_plan)
          @deployment_plan = deployment_plan
        end

        def perform
          #prior updates may have had release versions that we no longer use.
          #remove the references to these stale releases.
          stale_release_versions = (@deployment_plan.model.release_versions - @deployment_plan.releases.map(&:model))
          # stale_release_names = stale_release_versions.map {|version_model| version_model.release.name}.uniq
          # @deployment_plan.with_release_locks(stale_release_names) do
            stale_release_versions.each do |release_version|
              @deployment_plan.model.remove_release_version(release_version)
            end
          # end

          @deployment_plan.model.manifest = YAML.dump(@deployment_plan.uninterpolated_manifest_text)
          @deployment_plan.model.cloud_config = @deployment_plan.cloud_config
          Config.logger.debug('***** before runtime config assignment')
          Config.logger.debug("***** deployment: #{@deployment_plan.model.inspect}")
          Config.logger.debug("***** runtime configs: #{@deployment_plan.model.runtime_configs[0].inspect}")
          Config.logger.debug("***** runtime configs (all): #{Bosh::Director::Models::Config.where(type: 'runtime').all.inspect}")
          Config.logger.debug("***** deployments (all): #{Bosh::Director::Models::Deployment.all.inspect}")
          @deployment_plan.model.runtime_configs = @deployment_plan.runtime_configs
          Config.logger.debug('***** after runtime config assignment')
          @deployment_plan.model.link_spec = @deployment_plan.link_spec
          @deployment_plan.model.save
          Config.logger.debug("***** deployments (all): #{Bosh::Director::Models::Deployment.all.inspect}")
        end
      end
    end
  end
end
