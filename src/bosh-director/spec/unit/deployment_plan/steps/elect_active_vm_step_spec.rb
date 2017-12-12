require 'spec_helper'

module Bosh::Director
  module DeploymentPlan
    module Steps
      describe ElectActiveVmStep do
        subject(:step) { described_class.new(instance_plan, vm) }

        let!(:instance_plan) { instance_double(InstancePlan) }
        let(:instance) { Models::Instance.make }
        let!(:vm) { Models::Vm.make(instance: instance, active: false, cpi: 'vm-cpi') }

        before do
          allow(instance_plan).to receive_message_chain(:instance, :model).and_return instance
        end

        it 'marks the new vm as active' do
          step.perform
          expect(vm.reload.active).to eq true
        end

        context 'when there is already an active vm' do
          let!(:active_vm) { Models::Vm.make(instance: instance, active: true, cpi: 'vm-cpi') }
          it 'marks the old vm as inactive' do
            step.perform
            expect(active_vm.reload.active).to eq false
            expect(vm.reload.active).to eq true
          end
        end
      end
    end
  end
end
