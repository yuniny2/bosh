Sequel.migration do
  change do
    create_table :errands do
      primary_key :id

      String :fingerprint, :text => true
      String :links_json, :text => true
      String :properties_json, :text => true
      TrueClass :ran_successfully, :default => false
    end
  end
end
