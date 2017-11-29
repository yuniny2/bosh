require 'rspec'
require 'yaml'
require 'json'
require 'open3'
require 'fileutils'
require 'bosh/template/test'
require 'bosh/template/evaluation_context'
require_relative './template_example_group'

RSpec.configure do |c|
  c.example_status_persistence_file_path = '/tmp/release-examples.txt'
end
