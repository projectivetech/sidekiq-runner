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

      @sidekiqs    = []
    end

    def self.default
      @default ||= SidekiqConfiguration.new
    end

    def each
      @sidekiqs.each do |skiq|
        yield skiq if block_given?
      end
    end

    def empty?
      @sidekiqs.empty?
    end

    def add_instance(name)
      skiq = SidekiqInstance.new(name)
      yield skiq if block_given?

      fail "Sidekick instance with the name of #{skiq.name} already exits! No duplicates please." unless @sidekiqs.select{|sk| sk.name ==  skiq.name}.empty?

      FileUtils.mkdir_p(File.dirname(skiq.pidfile))
      FileUtils.mkdir_p(File.dirname(skiq.logfile))

      @sidekiqs << skiq

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

      # Create a default sidekiq instance when no instances were created
      if @sidekiqs.empty?
        default_skiq = add_instance('sidekiq_default')
        default_skiq.add_queue('default') if default_skiq.queues.empty?
        # Backwards compatibility
        # Get sidekiq pidfile and logfile if no sidekiq instance was specified
        SidekiqInstance::INDIVIDUAL_FILE_ATTRIBUTES.each do |k|
          v = yml[k] || yml[k.to_s]
          sidekiqs_common_config[k] = v if v
        end
      end

      @sidekiqs.each do |skiq|
        # Symbolize keys in yml hash
        if yml[skiq.name] && yml[skiq.name].is_a?(Hash)
          yml_config = yml[skiq.name].inject({}) do |h,(k,v)|
            h[k.to_sym] = v; h
          end
        end
        # Merge common and specific sidekiq instance configs
        # Sidekiq instances not defined in the initializer but present in yml will be ignored
        sidekiqs_common_config.merge!(yml_config) if yml_config
        skiq.merge_config!(sidekiqs_common_config) unless sidekiqs_common_config.empty?
        skiq.sane?
      end

      self
    end

    def sane?
      fail 'No requirefile given and not in Rails env.' if !defined?(Rails) && !requirefile
    end
  end
end
