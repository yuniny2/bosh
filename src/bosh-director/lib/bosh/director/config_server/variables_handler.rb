module Bosh::Director::ConfigServer
  class VariablesHandler

    def self.remove_unused_variable_sets(deployment, instance_groups)
      current_variable_set = deployment.current_variable_set
      deployment.variable_sets.each do |variable_set|
        variable_set_usage = 0
        instance_groups.each do |instance_group|
          variable_set_usage += instance_group.needed_instance_plans.select{ |instance_plan| instance_plan.instance.variable_set.id == variable_set.id }.size
        end

        if variable_set_usage == 0 && variable_set.id != current_variable_set.id
          variable_set.delete
        end
      end
    end
  end
end
