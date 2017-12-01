require 'spec_helper'

module Bosh::Director
  module DeploymentPlan
    module Steps
      describe DetachDisksStep do
        subject(:step) { DetachDisksStep.new(instance_plan) }

        let(:instance) { Models::Instance.make }
        let!(:vm) { Models::Vm.make(instance: instance, active: true, cpi: 'vm-cpi') }
        let!(:disk1) { Models::PersistentDisk.make(instance: instance, name: '') }
        let!(:disk2) { Models::PersistentDisk.make(instance: instance, name: 'unmanaged') }
        let(:deployment_instance) { instance_double(Instance, model: instance) }
        let(:instance_plan) { instance_double(InstancePlan, instance: deployment_instance) }
        let(:cloud_factory) { instance_double(CloudFactory) }
        let(:cloud) { Config.cloud }

        before do
          allow(CloudFactory).to receive(:create_with_latest_configs).and_return(cloud_factory)
          allow(cloud_factory).to receive(:get).with(vm.cpi).once.and_return(cloud)
          allow(cloud).to receive(:detach_disk)
        end

        it 'calls out to vms cpi to detach all attached disks' do
          expect(cloud).to receive(:detach_disk).with(disk1.disk_cid)
          expect(cloud).to receive(:detach_disk).with(disk2.disk_cid)

          step.perform
        end

        it 'logs notification of detaching' do
          expect(logger).to receive(:info).with("Detaching disk #{disk1.disk_cid}")
          expect(logger).to receive(:info).with("Detaching disk #{disk2.disk_cid}")

          step.perform
        end

        context 'when the CPI reports that a disk is not attached' do
          before do
            allow(cloud).to receive(:detach_disk)
              .with(disk1.disk_cid)
              .and_raise(Bosh::Clouds::DiskNotAttached.new('foo'))
          end

          context 'and the disk is active' do
            before do
              disk1.update(active: true)
            end

            it 'raises a CloudDiskNotAttached error' do
              expect { step.perform }.to raise_error(
                CloudDiskNotAttached,
                "'#{instance}' VM should have persistent disk '#{disk1.disk_cid}' attached " \
                "but it doesn't (according to CPI)"
              )
            end
          end

          context 'and the disk is not active' do
            before do
              disk1.update(active: false)
            end

            it 'does not raise any errors' do
              expect { step.perform }.not_to raise_error
            end
          end
        end

        context 'when the instance does not have an active vm' do
          before do
            vm.update(active: false)
          end

          it 'does nothing' do
            expect(cloud).not_to receive(:detach_disk)

            step.perform
          end
        end
      end
    end
  end
end
