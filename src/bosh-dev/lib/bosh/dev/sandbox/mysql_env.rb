require 'bosh/dev'
require 'bosh/core/shell'
require 'tmpdir'

module Bosh::Dev::Sandbox
  class MysqlEnv
    attr_reader :username,
                :password,
                :server_root_ca,
                :cert,
                :private_key

    def initialize(sandbox_root, port_provider, logger, base_log_path, username = 'root', password = 'password', runner = Bosh::Core::Shell.new)
      @port_provider = port_provider
      @logger = logger
      @runner = runner
      @username = username
      @password = password
      @sandbox_root = sandbox_root
      @base_log_path = base_log_path
      @base_ssl_log_path = "#{base_log_path}.ssl"

      @server_port = 3306
      @proxy_port = @port_provider.get_port(:postgres_proxy)

      FileUtils.cp(File.join(Workspace.new.assets_dir, 'database', 'rootCA.pem'), "/tmp")
      FileUtils.copy_entry(File.join(Workspace.new.assets_dir, 'database', 'database_client'), "/tmp/database_client")

      @server_root_ca = File.join(Workspace.new.assets_dir, 'database', 'rootCA.pem')
      @cert = File.join(Workspace.new.assets_dir, 'database', 'database_client', "certificate.pem")
      @private_key = File.join(Workspace.new.assets_dir, 'database', 'database_client', "private_key")
    end

    def get_proxy
      @proxy || (@proxy = ConnectionProxyService.new(File.join(@sandbox_root, 'proxy'), '127.0.0.1', @server_port, @proxy_port, @base_log_path, @logger))
    end

    def get_database(db_name)
      Mysql.new(db_name, @logger, @runner, @username, @password)
    end
  end
end