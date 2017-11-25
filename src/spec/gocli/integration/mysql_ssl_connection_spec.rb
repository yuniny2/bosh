require_relative '../spec_helper'

describe 'When director is connected to the MYSQL using TLS', type: :integration, db: :mysql do


  let(:manifest)  { Bosh::Spec::NewDeployments.simple_manifest_with_instance_groups }


  context 'when tls is enabled' do
    with_reset_sandbox_before_each(:enable_tls_database => true )
    it 'can make a successful deployment' do
      _, exit_code = deploy_from_scratch(return_exit_code: true, manifest_hash: manifest)

      bosh_runner.run('cloud-config', deployment_name: 'simple')

      expect(exit_code).to eq(0)
    end
  end
end
