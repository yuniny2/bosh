require_relative '../spec_helper'

describe 'calculated vm properties', type: :integration do
  with_reset_sandbox_before_each

  let(:cloud_config_without_vm_types) do
    cloud_config = Bosh::Spec::Deployments.simple_cloud_config
    cloud_config.delete('resource_pools')
    cloud_config.delete('vm_types')
    cloud_config
  end

  let(:deployment_manifest_with_vm_block) do
    {
      'name' => 'simple',
      'director_uuid'  => 'deadbeef',

      'releases' => [{
        'name'    => 'bosh-release',
        'version' => '0.1-dev',
      }],

      'instance_groups' => [
        {
          'name' => 'dummy',
          'instances' => 1,
          'vm' => {
            'cpu' => 2,
            'ram' => 1024,
            'ephemeral_disk' => 10
          },
          'jobs' => [{'name'=> 'foobar', 'release' => 'bosh-release'}],
          'stemcell' => 'default',
          'networks' => [
            {
              'name' => 'a',
              'static_ips' => ['192.168.1.10']
            }
          ]
        }
      ],

      'stemcells' => [
        {
          'alias' => 'default',
          'os' => 'toronto-os',
          'version' => '1',
        }
      ],

      'update' => {
        'canaries'          => 2,
        'canary_watch_time' => 4000,
        'max_in_flight'     => 1,
        'update_watch_time' => 20
      }
    }
  end

  before do
    create_and_upload_test_release
    upload_stemcell
    upload_cloud_config(cloud_config_hash: cloud_config_without_vm_types)
    deploy_simple_manifest(manifest_hash: deployment_manifest_with_vm_block)
  end

  it 'deploys vms with size calculated from vm block' do
    invocations = current_sandbox.cpi.invocations

    expect(invocations[4].method_name).to eq('calculate_vm_cloud_properties')
  end
end