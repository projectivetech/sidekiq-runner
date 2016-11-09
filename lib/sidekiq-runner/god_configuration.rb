require 'yaml'

module SidekiqRunner
  class GodConfiguration
    def self.default
      @default ||= GodConfiguration.new
    end

    def self.get
      config = default.dup
      config.merge_config_file!
      config
    end

    RUNNER_ATTRIBUTES = [:config_file, :daemonize, :port, :syslog, :events]
    RUNNER_ATTRIBUTES.each { |att| attr_accessor att }

    CONFIG_FILE_ATTRIBUTES = [:process_name, :interval, :stop_timeout, :log_file, :log_level, :maximum_memory_usage, :pid]
    CONFIG_FILE_ATTRIBUTES.each { |att| attr_accessor att }

    def initialize
      @process_name = 'sidekiq'
      @interval  = 30
      @stop_timeout = 30
      @maximum_memory_usage = nil

      @log_file   = File.join(Dir.pwd, 'log', 'god.log')
      @config_file  = File.join(Dir.pwd, 'config', 'god.yml')

      @daemonize = true
      @syslog = true
      @events = true
      @pid = nil
      @log_level = :warn

      # This is going to be a part of the .sock file name e.g. "/tmp/god.17165.sock" and the pidfile name
      # Change this in the configuration file to be able to run multiple instances of god.
      @port = 17165
    end

    def options
      create_directories!

      {
        daemonize: @daemonize,
        port: @port,
        syslog: @syslog,
        events: @events,
        config: File.expand_path("../sidekiq.god", __FILE__),
        log: @log_file,
        pid: @pid,
        log_level: @log_level
      }
    end

    def merge_config_file!
      if File.exist?(config_file)
        yml = YAML.load_file(config_file)
        CONFIG_FILE_ATTRIBUTES.each do |k|
          v = yml[k] || yml[k.to_s]
          send("#{k}=", v) unless v.nil?
        end
      end
    end

    def create_directories!
      FileUtils.mkdir_p(File.dirname(log_file))
    end

    %w(start stop).each do |action|
      attr_reader "before_#{action}_cb".to_sym

      define_method("before_#{action}") do |&block|
        instance_variable_set("@before_#{action}_cb".to_sym, block)
      end
    end
  end
end
