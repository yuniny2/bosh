require 'spec_helper'

module Bosh::Director
  module DeploymentPlan
    module Steps
      describe UpdateInstanceSettingsStep do
        subject(:step) { UpdateInstanceSettingsStep.new(instance, vm, agent_client) }

        let(:disk1) { Models::PersistentDisk.make(instance: instance, name: '') }
        let(:disk2) { Models::PersistentDisk.make(instance: instance, name: 'unmanaged', cid: 'cid2') }
        let(:cloud_props) { { 'prop1' => 'value1' } }
        let(:instance) { Models::Instance.make }
        let!(:vm) {Models::Vm.make(instance: instance, active: false, cpi: 'vm-cpi') }
        let(:agent_client) { instance_double(AgentClient) }
        let(:trusted_certs) { 'fake-cert' }

        describe '#perform' do
          before do
            allow(Config).to receive(:trusted_certs).and_return(trusted_certs)
          end
          context 'when there are unmanaged persistent disks' do
            it 'updates agent disk associations' do
              expect(agent_client).to receive(:update_settings).with({}, [{'name' => 'unmanaged', 'cid' => 'cid2'}])
              step.perform
            end
          end

          it 'updates the agent settings and VM table with configured trusted certs' do
            expect(agent_client).to receive(:update_settings).with(trusted_certs, [])
            expect { step.perform }.to change{vm.trusted_certs_sha1}.from('').to('fake_cert')
          end

          it 'should update any cloud_properties provided' do
            expect { step.perform(cloud_props) }.to change(instance.cloud_properties).from({}).to(cloud_props)
          end
        end
      end
    end
  end
end
