module Bosh::Director::DeploymentPlan
  class Property
    def initialize(name, resolved_value, default_value, provided_value, type, description)
      @name = name
      @resolved_value = resolved_value
      @default_value = default_value
      @provided_value = provided_value
      @type = type
      @description = description
    end
  end
end
