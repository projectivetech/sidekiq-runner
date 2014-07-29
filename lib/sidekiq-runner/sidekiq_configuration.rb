require 'sidekiq-runner/common_configuration'
require 'fileutils'

module SidekiqRunner
  class SidekiqConfiguration < CommonConfiguration
    include Enumerable

    RUNNER_ATTRIBUTES = [:config_file, :daemonize]
    RUNNER_ATTRIBUTES.each { |att| attr_accessor att }

    attr_reader :sidekiqs

    def initialize
      @config_file = File.join(Dir.pwd, 'config', 'sidekiq.yml')
      @daemonize   = true

      @sidekiqs    = {}
    end

    def self.default
      @default ||= SidekiqConfiguration.new
    end

    def each(&block)
      @sidekiqs.each(&block)
    end

    def each_key(&block)
      @sidekiqs.each_key(&block)
    end

    def empty?
      @sidekiqs.empty?
    end

    # DELETEME in the future
    # Redefined and kept for bakward compatibility
    def queue(name, weight = 1)
      # Create a default sidekiq instance when no instances were created
      fail 'Sidekiq instances hash does not seem to be empty. 
      It means you are using the newer syntax in the initializer to create at least one instance. 
      Therefore you should not be using the old queue() function.' unless @sidekiqs.empty?

      add_instance('sidekiq_default') do |skiq|
        skiq.add_queue('default')
      end
    end

    def add_instance(name)
      skiq = SidekiqInstance.new(name)
      yield skiq if block_given?

      fail "Sidekick instance with the name of #{name} already exists! No duplicates please." if @sidekiqs.has_key?(name)

      FileUtils.mkdir_p(File.dirname(skiq.pidfile))
      FileUtils.mkdir_p(File.dirname(skiq.logfile))

      @sidekiqs[name] = skiq

      skiq
    end

    %w(start stop).each do |action|
      %w(success error).each do |state|
        attr_reader "#{action}_#{state}_cb".to_sym

        define_method("on_#{action}_#{state}") do |&block|
          instance_variable_set("@#{action}_#{state}_cb".to_sym, block)
        end
      end
    end

    private

    def merge_config_file!
      sidekiqs_common_config = {}
      yml = {}

      if File.exist?(config_file)
        yml = YAML.load_file(config_file)
        # Get sidekiq config common for all instances
        SidekiqInstance::CONFIG_FILE_ATTRIBUTES.each do |k|
          v = yml[k] || yml[k.to_s]
          sidekiqs_common_config[k] = v if v
        end
      end

      # Backwards compatibility
      # Get sidekiq pidfile and logfile if no sidekiq instance was specified
      SidekiqInstance::INDIVIDUAL_FILE_ATTRIBUTES.each do |k|
        v = yml[k] || yml[k.to_s]
        sidekiqs_common_config[k] = v if v
      end

      @sidekiqs.each do |name, skiq|
        # Symbolize keys in yml hash
        if yml[name] && yml[name].is_a?(Hash)
          yml_config = Hash[yml[name].map { |k, v| [k.to_sym, v] }]
        end
        # Merge common and specific sidekiq instance configs
        # Sidekiq instances not defined in the initializer but present in yml will be ignored
        final_skiq_config = yml_config ? sidekiqs_common_config.merge(yml_config) : sidekiqs_common_config
        skiq.merge_config!(final_skiq_config)
        skiq.sane?
      end

      self
    end

    def sane?
      fail 'No requirefile given and not in Rails env.' if !defined?(Rails) && !requirefile
      fail 'No sidekiq instances defined. Nothing to run.' if @sidekiqs.empty?
    end
  end
end
