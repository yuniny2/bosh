module Bosh::Director
  class Errand::LifecycleServiceStep
    def initialize(runner, instance, logger)
      @runner = runner
      @instance = instance
      @logger = logger
    end

    def prepare
    end

    def run(&checkpoint_block)
      @logger.info('Starting to run errand')
      @runner.run(@instance, &checkpoint_block)
    end

    def ignore_cancellation?
      false
    end

    def state_hash
      digest = ::Digest::SHA1.new

      digest << @instance.uuid

      digest << @instance.configuration_hash
      # rendered_templates_archive_model = @instance.model.latest_rendered_templates_archive
      # if rendered_templates_archive_model && rendered_templates_archive_model.content_sha1
      #   digest << rendered_templates_archive_model.content_sha1
      # else
      #   raise "NO RENDERED TEMPLATES FOUND for #{@instance}"
      # end

      digest << @instance.current_packages.to_s
      Config.logger.info("Computed configuration hash for #{@instance}: digest: '#{digest.hexdigest}', uuid: #{@instance.uuid}, templates sha1 #{rendered_templates_archive_model.content_sha1}, current_packages: #{@instance.current_packages.to_s}")

      digest.hexdigest
    end
  end
end
