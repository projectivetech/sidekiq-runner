require 'sidekiq-runner/common_configuration'

module SidekiqRunner
  class SidekiqConfiguration < CommonConfiguration
    def self.default
      @default ||= SidekiqConfiguration.new
    end

    RUNNER_ATTRIBUTES = [:config_file, :bundle_env, :daemonize, :chdir, :requirefile, :verify_ps]
    RUNNER_ATTRIBUTES.each { |att| attr_accessor att }

    CONFIG_FILE_ATTRIBUTES = [:pidfile, :logfile, :concurrency, :verbose]
    CONFIG_FILE_ATTRIBUTES.each { |att| attr_accessor att }

    attr_reader :queues

    def initialize
      @config_file  = File.join(Dir.pwd, 'config', 'sidekiq.yml')
      @bundle_env  = true
      @daemonize   = true
      @chdir       = nil
      @requirefile = nil
      @verify_ps   = false

      @pidfile     = File.join(Dir.pwd, 'tmp', 'pids', 'sidekiq.pid')
      @logfile     = File.join(Dir.pwd, 'log', 'sidekiq.log')
      @concurrency = 4
      @verbose     = false

      @queues      = []
    end

    def queue(name, weight = 1)
      @queues << [name, weight]
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

    def sane?
      fail 'No requirefile given and not in Rails env.' if !defined?(Rails) && !requirefile
      fail 'No queues given.' if queues.empty?
    end
  end
end
