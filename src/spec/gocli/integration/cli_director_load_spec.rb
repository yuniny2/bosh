require_relative '../spec_helper'

describe 'cli: director load test', type: :integration do
  with_reset_sandbox_before_each

  it 'massively calls the director' do
    sandbox = Thread.current[:sandbox]
    threads = []
    failed = false
    failure_output = []

    32000.times do
      if !failed
        threads << Thread.new {
          if !failed
            Thread.current[:sandbox] = sandbox
            output = bosh_runner.run('environment', failure_expected: true)
            if output.match('502')
              failure_output << output
              failed = true
            end
          end
        }
      end
    end

    threads.each { |thr| thr.join }

    expect(failed).not_to be, "Failure messages: #{failure_output}"
  end
end
