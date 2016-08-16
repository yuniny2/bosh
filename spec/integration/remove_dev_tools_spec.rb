require 'spec_helper'

describe 'remove dev tools', type: :integration do
  with_reset_sandbox_before_each(
      remove_dev_tools: true,
      config_server_enabled: true,
      user_authentication: 'uaa',
      uaa_encryption: 'asymmetric'
  )
  let (:config_server_helper) { Bosh::Spec::ConfigServerHelper.new(current_sandbox)}
  let (:client_env) { {'BOSH_CLIENT' => 'test', 'BOSH_CLIENT_SECRET' => 'secret'} }

  let(:simple_manifest) do
    manifest_hash = Bosh::Spec::Deployments.simple_manifest
    manifest_hash['jobs'][0]['instances'] = 1
    manifest_hash
  end

  it 'should send the flag to the agent and when redeployed, it should not recreate the vm' do
    bosh_runner.run("target #{current_sandbox.director_url}", {ca_cert: current_sandbox.certificate_path})
    bosh_runner.run('logout')
    deploy_from_scratch(no_login: true, manifest_hash: simple_manifest, env: client_env)

    invocations = current_sandbox.cpi.invocations_for_method('create_vm')
    expect(invocations.size).to eq(3) # 2 compilation vms and 1 for the one in the instance_group

    expect(invocations[2].inputs).to match({'agent_id' => String,
                                            'stemcell_id' => String,
                                            'cloud_properties' => {},
                                            'networks' => Hash,
                                            'disk_cids' => Array,
                                            'env' =>
                                                {
                                                    'bosh' => {
                                                        'password' => 'foobar',
                                                        'remove_dev_tools' => true,
                                                        'group_name' => 'foobar'
                                                    }
                                                }
                                           })


    deploy_simple_manifest(no_login: true, manifest_hash: simple_manifest, env: client_env)

    invocations = current_sandbox.cpi.invocations_for_method('create_vm')
    expect(invocations.size).to eq(3) # no vms should have been deleted/created
  end
end

