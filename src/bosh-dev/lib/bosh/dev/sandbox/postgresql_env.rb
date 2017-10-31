require 'bosh/dev'
require 'bosh/core/shell'
require 'tmpdir'

module Bosh::Dev::Sandbox
  class PostgresqlEnv
    attr_reader :username,
                :password,
                :server_root_ca

    def initialize(sandbox_root, port_provider, logger, base_log_path, username = 'postgres', runner = Bosh::Core::Shell.new)
      @port_provider = port_provider
      @logger = logger
      @runner = runner
      @username = username
      @password = ''
      @sandbox_root = sandbox_root
      @base_log_path = base_log_path
      @base_ssl_log_path = "#{base_log_path}.ssl"

      @ssl_server_port = 56000
      @ssl_proxy_port = @port_provider.get_port(:postgres_ssl_proxy)
      @server_port = 55000
      @proxy_port = @port_provider.get_port(:postgres_proxy)

      @server_root_ca = File.join(Workspace.new.assets_dir, 'database', 'rootCA.pem')
    end

    def get_proxy
      @proxy || (@proxy = ConnectionProxyService.new(File.join(@sandbox_root, 'proxy'), '127.0.0.1', @server_port, @proxy_port, @base_log_path, @logger))
    end

    def get_ssl_proxy
      @ssl_proxy || (@ssl_proxy = ConnectionProxyService.new(File.join(@sandbox_root, 'proxy_ssl'), '127.0.0.1', @ssl_server_port, @ssl_proxy_port, @base_ssl_log_path, @logger))
    end

    def get_database(db_name)
      Postgresql.new(db_name, @logger, @proxy_port, @runner, @username, @password)
    end

    def get_ssl_database(db_name)
      Postgresql.new(db_name, @logger, @ssl_proxy_port, @runner, @username, @password)
    end
  end
end