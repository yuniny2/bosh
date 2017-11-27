require 'bosh/dev'
require 'bosh/core/shell'
require 'tmpdir'

module Bosh::Dev::Sandbox
  class MysqlEnv
    attr_reader :username,
                :password,
                :server_root_ca

    def initialize(logger, username = 'root', password = 'password', runner = Bosh::Core::Shell.new)
      @port_provider = port_provider
      @logger = logger
      @runner = runner
      @username = username
      @password = password
      @server_root_ca = nil
    end

    def get_proxy
    end

    def get_ssl_proxy
    end

    def get_ssl_database(db_name)
      get_database(db_name)
    end

    def get_database(db_name)
      Mysql.new(db_name, @logger, @runner, @username, @password)
    end
  end
end