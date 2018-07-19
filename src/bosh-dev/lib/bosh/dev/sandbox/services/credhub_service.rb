require 'common/retryable'

module Bosh::Dev::Sandbox
  class CredHubService
    attr_reader :port

    # TODO change it to store credhub jar
    S3_BUCKET_BASE_URL = 'https://s3.amazonaws.com/credhub-extracted-jar'

    CREDHUB_SERVER_VERSION = "100.0.1"
    # TODO update shar version of the jar
    CREDHUB_JAR_SHA256='2f3ffe7524645d153b61c074815bedd0c8e28ae4be50117e6bce70df69c68e67'
    DARWIN_CONFIG_SERVER_SHA256 = '1b8e57100176ce830d83cd2ad040816ccf9406624431f6fd18abb705d5d0cd96'
    LINUX_CONFIG_SERVER_SHA256 = 'd899a9ef1e046eed197efd2732e6ed681c2d4180937b8196c51d0a035b3c7b55'

    LOCAL_CONFIG_SERVER_FILE_NAME = "start-credhub.sh"

    REPO_ROOT = File.expand_path('../../../../../../', File.dirname(__FILE__))
    INSTALL_DIR = File.join('tmp', 'integration-config-server')
    ASSETS_DIR = File.expand_path('bosh-dev/assets/sandbox', REPO_ROOT)
    CREDHUB_ASSETS_DIR = File.join(ASSETS_DIR, '/config_server/credhub')

    # Keys and Certs
    CERTS_DIR = File.expand_path('trust_store', CREDHUB_ASSETS_DIR)
    SERVER_CERT = File.join(CERTS_DIR, 'server.crt')
    SERVER_KEY = File.join(CERTS_DIR, 'server.key') # TODO: actually called server_key.pem?
    ROOT_CERT = File.join(CERTS_DIR, 'server_ca_cert.pem')
    ROOT_PRIVATE_KEY = File.join(CERTS_DIR, 'rootCA.key') # TODO: server_ca_private.pem?
    JWT_VERIFICATION_KEY = File.join(CERTS_DIR, 'jwtVerification.key')
    UAA_CA_CERT = File.join(CERTS_DIR, 'server.crt')
    CREDHUB_ENABLED = ENV['CREDHUB_ENABLED'] || false
    # specified in application.yml
    CREDHUB_SERVER_PORT=9000

    DEFAULT_DIRECTOR_CONFIG = 'director_test.yml'
    CREDHUB_CONFIG_FILE_NAME = 'application.yml'
    CREDHUB_CONFIG_TEMPLATE_PATH = File.join(ASSETS_DIR, 'application.yml.erb')

    def initialize(sandbox_root, base_log_path, logger, test_env_number)
      @config_output = File.join(sandbox_root, CREDHUB_CONFIG_FILE_NAME)

      @port = CREDHUB_SERVER_PORT
      @logger = logger
      @log_location = "#{base_log_path}.config-server.out"
      @connector = HTTPEndpointConnector.new('credhub', 'localhost', CREDHUB_SERVER_PORT, '/info', 'Reset password', @log_location, logger)
      @config_server_config_file = "/Users/pivotal/workspace/credhub/start_server.sh"
      @config_server_process = Bosh::Dev::Sandbox::Service.new(
        [executable_path, '>>/tmp/credhub.log',  '2>&1'],
        {
          output: @log_location,
          env: {
            'JAR_FILE' => jarfile_path,
            'ASSETS_DIR' => CREDHUB_ASSETS_DIR,
            'SANDBOX_ROOT' => sandbox_root,
          }
        },
        @logger
      )
    end

    def self.install
      FileUtils.mkdir_p(INSTALL_DIR)
      downloaded_file_name = download(CREDHUB_SERVER_VERSION)
      executable_file_path = File.join(INSTALL_DIR, LOCAL_CONFIG_SERVER_FILE_NAME)
      FileUtils.copy(File.join(INSTALL_DIR, downloaded_file_name), executable_file_path)
      File.chmod(0777, executable_file_path)
    end

    def start(use_trusted_certs, config)
      @director_config = config
      write_config(config)
      @config_server_process.start

      begin
        sleep(10)
      rescue
        output_service_log(@config_server_process.description, @config_server_process.stdout_contents, @config_server_process.stderr_contents)
        raise
      end
    end

    def stop
      @config_server_process.stop
    end

    def restart(with_trusted_certs)
      @config_server_process.stop
      start(with_trusted_certs, @director_config)
    end

    private

    def write_config(config)
      contents = config.render(CREDHUB_CONFIG_TEMPLATE_PATH)
      File.open(@config_output, 'w+') do |f|
        f.write(contents)
      end
    end

    def self.download(version)
      sha256 = CREDHUB_JAR_SHA256
      file_name_to_download = "config-server-#{version}-#{platform}-amd64"

      retryable.retryer do
        destination_path = File.join(INSTALL_DIR, file_name_to_download)
        `#{File.dirname(__FILE__)}/install_binary.sh #{file_name_to_download} #{destination_path} #{sha256} config-server-releases`
        $? == 0
      end

      file_name_to_download
    end

    def self.retryable
      Bosh::Retryable.new({tries: 6})
    end

    def self.read_current_version
      file = File.open(File.join(INSTALL_DIR, 'current-version'), 'r')
      version = file.read
      file.close

      version
    end

    def executable_path
      # if CREDHUB_ENABLED
      #   "/Users/pivotal/workspace/credhub/start_server.sh"
      # else
      #   File.join(INSTALL_DIR, LOCAL_CONFIG_SERVER_FILE_NAME)
      # end
      File.join(CREDHUB_ASSETS_DIR, LOCAL_CONFIG_SERVER_FILE_NAME)
    end

    def jarfile_path
      # if CREDHUB_ENABLED
      #   "/Users/pivotal/workspace/credhub/start_server.sh"
      # else
      #   File.join(INSTALL_DIR, LOCAL_CONFIG_SERVER_FILE_NAME)
      # end
      File.join(ASSETS_DIR, 'credhub.jar')
    end

    def setup_config_file(with_trusted_certs = true)
      config = with_trusted_certs ? config_json : config_with_untrusted_cert_json
      File.open(@config_server_config_file, 'w') { |file| file.write(config) }
    end

    def config_json
      config = {
        port: @port,
        store: 'memory',
        private_key_file_path: SERVER_KEY,
        certificate_file_path: SERVER_CERT,
        jwt_verification_key_path: JWT_VERIFICATION_KEY,
        ca_certificate_file_path: ROOT_CERT,
        ca_private_key_file_path: ROOT_PRIVATE_KEY
      }
      JSON.dump(config)
    end

    def config_with_untrusted_cert_json
      config = {
        port: @port,
        store: 'memory',
        private_key_file_path: NON_CA_SIGNED_CERT_KEY,
        certificate_file_path: NON_CA_SIGNED_CERT,
        jwt_verification_key_path: JWT_VERIFICATION_KEY,
        ca_certificate_file_path: ROOT_CERT,
        ca_private_key_file_path: ROOT_PRIVATE_KEY
      }
      JSON.dump(config)
    end

    DEBUG_HEADER = '*' * 20

    def output_service_log(description, stdout_contents, stderr_contents)
      @logger.error("#{DEBUG_HEADER} start #{description} stdout #{DEBUG_HEADER}")
      @logger.error(stdout_contents)
      @logger.error("#{DEBUG_HEADER} end #{description} stdout #{DEBUG_HEADER}")

      @logger.error("#{DEBUG_HEADER} start #{description} stderr #{DEBUG_HEADER}")
      @logger.error(stderr_contents)
      @logger.error("#{DEBUG_HEADER} end #{description} stderr #{DEBUG_HEADER}")
    end
  end
end
