require 'spec_helper'

module Bosh::Director::Models
  describe RuntimeConfig do
    let(:runtime_config_model) { RuntimeConfig.make(raw_manifest: mock_manifest) }
    let(:mock_manifest) { {name: '((manifest_name))'} }
    let(:new_runtime_config) { {name: 'runtime manifest'} }
    let(:deployment_name) { 'some_deployment_name' }

    describe "#interpolated_manifest_for_deployment" do
      let(:variables_interpolator) { instance_double(Bosh::Director::ConfigServer::VariablesInterpolator) }

      before do
        allow(Bosh::Director::ConfigServer::VariablesInterpolator).to receive(:new).and_return(variables_interpolator)
        allow(variables_interpolator).to receive(:interpolate_runtime_manifest).with(mock_manifest, deployment_name).and_return(new_runtime_config)
      end

      it 'calls manifest resolver and returns its result' do
        result = runtime_config_model.interpolated_manifest_for_deployment(deployment_name)
        expect(result).to eq(new_runtime_config)
      end
    end

    describe "#raw_manifest" do
      it 'returns raw result' do
        expect(runtime_config_model.raw_manifest).to eq(mock_manifest)
      end
    end

    describe '#tags' do
      let(:current_deployment) { instance_double(Bosh::Director::Models::Deployment)}
      let(:current_variable_set) { instance_double(Bosh::Director::Models::VariableSet)}

      before do
        allow(Bosh::Director::Models::Deployment).to receive(:[]).with(name: deployment_name).and_return(current_deployment)
        allow(current_deployment).to receive(:current_variable_set).and_return(current_variable_set)
      end

      context 'when there are no tags' do
        it 'returns an empty hash' do
          expect(runtime_config_model.tags(deployment_name)).to eq({})
        end
      end

      context 'when there are tags' do
        let(:mock_manifest) { {'tags' => {'my-tag' => 'best-value'}}}
        let(:uninterpolated_mock_manifest) { {'tags' => {'my-tag' => '((a_value))'}} }

        it 'returns interpolated values from the manifest' do
          allow(runtime_config_model).to receive(:interpolated_manifest_for_deployment).with(deployment_name).and_return({'tags' => {'my-tag' => 'something'}})
          expect(runtime_config_model.tags(deployment_name)).to eq({'my-tag' => 'something'})
        end

        it 'returns the tags from the manifest' do
          expect(runtime_config_model.tags(deployment_name)).to eq({'my-tag' => 'best-value'})
        end
      end
    end

    describe '#latest_set' do
      it 'returns the list of latest runtime configs grouped by name' do
        moop1 = Bosh::Director::Models::RuntimeConfig.new(properties: 'super_shiny: moop1', name: 'moop').save
        default = Bosh::Director::Models::RuntimeConfig.new(properties: 'super_shiny: default', name: '').save
        moop2 = Bosh::Director::Models::RuntimeConfig.new(properties: 'super_shiny: moop2', name: 'moop').save
        boopis1 = Bosh::Director::Models::RuntimeConfig.new(properties: 'super_shiny: boopis1', name: 'boopis').save
        boopis2 = Bosh::Director::Models::RuntimeConfig.new(properties: 'super_shiny: boopis2', name: 'boopis').save

        expect(Bosh::Director::Models::RuntimeConfig.latest_set).to contain_exactly(moop2, default, boopis2)
      end

      it 'returns empty list when there are no records' do
        expect(Bosh::Director::Models::RuntimeConfig.latest_set).to be_empty()
      end
    end

    describe '#latest_set_ids' do
      it 'returns the list of latest runtime config ids that are grouped by name' do
        moop1 = Bosh::Director::Models::RuntimeConfig.new(properties: 'super_shiny: moop1', name: 'moop').save
        default = Bosh::Director::Models::RuntimeConfig.new(properties: 'super_shiny: default', name: '').save
        moop2 = Bosh::Director::Models::RuntimeConfig.new(properties: 'super_shiny: moop2', name: 'moop').save
        boopis1 = Bosh::Director::Models::RuntimeConfig.new(properties: 'super_shiny: boopis1', name: 'boopis').save
        boopis2 = Bosh::Director::Models::RuntimeConfig.new(properties: 'super_shiny: boopis2', name: 'boopis').save

        expect(Bosh::Director::Models::RuntimeConfig.latest_set_ids).to contain_exactly(moop2.id, default.id, boopis2.id)
      end

      it 'returns empty list when there are no records' do
        expect(Bosh::Director::Models::RuntimeConfig.latest_set_ids).to be_empty()
      end
    end

    describe '#find_by_ids' do
      it 'returns all records that match ids' do
        runtime_configs = [
          Bosh::Director::Models::RuntimeConfig.new(properties: 'super_shiny: rc_1', name: 'rc_1').save,
          Bosh::Director::Models::RuntimeConfig.new(properties: 'super_shiny: rc_2', name: 'rc_2').save,
          Bosh::Director::Models::RuntimeConfig.new(properties: 'super_shiny: rc_3', name: 'rc_3').save
        ]

        expect(Bosh::Director::Models::RuntimeConfig.find_by_ids(runtime_configs.map(&:id))).to eq(runtime_configs)
      end
    end
  end
end