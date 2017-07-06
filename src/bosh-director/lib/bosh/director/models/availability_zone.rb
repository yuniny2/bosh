module Bosh::Director::Models
  class AvailabilityZone < Sequel::Model(Bosh::Director::Config.db)
    def self.lookup_table
      self.all.inject({}) do |lookup_table, new_item|
        # BUT if we have foreign keys:
        # az_hash = select(azs.name, azs.id) from LocalDnsRecords.join(instances).left_join(azs)

        lookup_table.merge({new_item.name => new_item.id})
      end
    end

  end
end
