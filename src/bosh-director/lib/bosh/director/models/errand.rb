module Bosh::Director::Models
  class Errand < Sequel::Model(Bosh::Director::Config.db)
    def ran_successfully?
      return self.ran_successfully
    end
  end
end
