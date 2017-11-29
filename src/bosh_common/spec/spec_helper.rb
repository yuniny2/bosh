require File.expand_path('../../../spec/shared/spec_helper', __FILE__)

def asset(file)
  File.expand_path(File.join(File.dirname(__FILE__), "assets", file))
end

RSpec.configure do |c|
  c.example_status_persistence_file_path = '/tmp/common-examples.txt'
end
