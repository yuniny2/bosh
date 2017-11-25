module Bosh::Dev::Sandbox
  class DatabaseConfig
    attr_reader :adapter,
                :name,
                :host,
                :port,
                :username,
                :password,
                :enable_ssl,
                :ca_path,
                :cert_path,
                :private_key_path

    def initialize(database_env, database, enable_ssl)
      puts database_env.inspect
      @adapter = database.adapter
      @name = database.db_name
      @host = database.host
      @port = database.port
      @username = database_env.username
      @password = database_env.password
      @ca_path = database_env.server_root_ca
      @cert_path = database_env.cert
      @private_key_path = database_env.private_key
      @enable_ssl = enable_ssl
    end
  end
end