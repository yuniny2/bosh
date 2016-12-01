require 'spec_helper'
require 'json'
require 'tempfile'

module Bosh::Director
  describe 'validate mysql database' do
    let(:db) { Bosh::Director::Config.db }
    let(:committed_schema_file) { File.expand_path('../../../../../db/schema.dump', __FILE__) }
    let(:tmp_schema_file) { Tempfile.new('generated_schema') }

    it 'should match the schema that is currently checked in' do
      require_relative '../../../../lib/bosh/director/models'
      db.dump_schema_cache(tmp_schema_file)
      generated_contents = File.read(tmp_schema_file)
      committed_contents = File.read(committed_schema_file)

      expect(generated_contents).to eq(committed_contents)

      # Uncomment to update schema dump and re-run test
      # File.write(generated_contents, committed)
    end

    context 'schema dump exists' do
      it 'loads schemas' do
        db.load_schema_cache?(committed_schema_file)
        expect(db.schemas.length).to_not eq(0)
      end
    end
  end
end
