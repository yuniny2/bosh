require_relative '../spec_helper'

describe 'When director is connected to the database using TLS', type: :integration, db: :postgresql do
  with_reset_sandbox_before_each(:enable_tls_database => true)

  it 'can make a successful deployment' do
    _, exit_code = deploy_from_scratch(return_exit_code: true)
    expect(exit_code).to eq(0)
  end
end
