module Bosh::Director
  describe 'add_errands' do
    let(:db) { DBSpecHelper.db }
    let(:migration_file) { '20170116235940_add_errands.rb' }

    before { DBSpecHelper.migrate_all_before(migration_file) }

    it 'creates the table' do
      DBSpecHelper.migrate(migration_file)
      db[:errands] << {id: 1, fingerprint: 'fingerprint', properties_json: '{ "valid": "json" }', links_json: '{ "consumes":"bosh2.0" }'}
      expect(db[:errands].first[:fingerprint]).to eq('fingerprint')
      expect(db[:errands].first[:properties_json]).to eq('{ "valid": "json" }')
      expect(db[:errands].first[:properties_json]).to eq('{ "consumes":"bosh2.0" }')
      expect(db[:errands].first[:ran_successfully]).to be_falsey
    end
  end
end
