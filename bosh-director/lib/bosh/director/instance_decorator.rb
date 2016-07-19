module Bosh::Director
  class InstanceDecorator
    def initialize(instance_model)
      @instance_model = instance_model
    end

    def lifecycle
      deployment = Models::Deployment[id: @instance_model.deployment.id]
      planner_factory = Bosh::Director::DeploymentPlan::PlannerFactory.create(Config.logger)
      deployment_plan = planner_factory.create_from_model(deployment)
      instance_group = deployment_plan.instance_groups.find { |instance_group| instance_group.name == @instance_model.job }
      if instance_group
        instance_group.lifecycle
      else
        nil
      end
    end
  end
end