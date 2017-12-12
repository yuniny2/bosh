require 'spec_helper'

module Bosh::Director
  module DeploymentPlan
    module Steps
      describe AttachInstanceDisksStep do
        subject(:step) { AttachInstanceDisksStep.new(instance_plan, vm) }

        let(:instance_plan) { instance_double(InstancePlan, tags: tags) }
        let(:instance) { Models::Instance.make }
        let!(:vm) { Models::Vm.make(instance: instance, active: false, cpi: 'vm-cpi') }
        let!(:disk1) { Models::PersistentDisk.make(instance: instance, active: true, name: '') }
        let!(:disk2) { Models::PersistentDisk.make(instance: instance, active: true, name: 'unmanaged') }
        let(:tags) {{'mytag' => 'myvalue'}}

        let(:attach_disk_1) { instance_double(AttachDiskStep) }
        let(:attach_disk_2) { instance_double(AttachDiskStep) }

        before do
          allow(AttachDiskStep).to receive(:new).with(disk1, vm, tags).and_return(attach_disk_1)
          allow(AttachDiskStep).to receive(:new).with(disk2, vm, tags).and_return(attach_disk_2)

          allow(instance_plan).to receive_message_chain(:instance, :model).and_return instance
          allow(instance_plan).to receive(:needs_disk?).and_return(true)
        end

        it 'calls out to vms cpi to attach all attached disks' do
          expect(attach_disk_1).to receive(:perform).once
          expect(attach_disk_2).to receive(:perform).once

          step.perform
        end

        context 'when the instance plan does not need disk' do
          before do
            allow(instance_plan).to receive(:needs_disk?).and_return(false)
          end

          it 'does nothing' do
            expect(AttachDiskStep).not_to receive(:new)
            expect(AttachDiskStep).not_to receive(:new)
            expect(attach_disk_1).not_to receive(:perform)
            expect(attach_disk_2).not_to receive(:perform)

            step.perform
          end
        end
      end
    end
  end
end
