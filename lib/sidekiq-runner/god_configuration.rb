require 'sidekiq-runner/common_configuration'

module SidekiqRunner
  class GodConfiguration < CommonConfiguration
    def self.default
      @default ||= GodConfiguration.new
    end

    RUNNER_ATTRIBUTES = [:config_file, :daemonize, :port, :syslog, :events, :options]
    RUNNER_ATTRIBUTES.each { |att| attr_accessor att }

    CONFIG_FILE_ATTRIBUTES = [:process_name, :interval, :stop_timeout, :log_file]
    CONFIG_FILE_ATTRIBUTES.each { |att| attr_accessor att }

    def initialize
      @process_name = 'sidekiq'
      @interval  = 30
      @stop_timeout = 30
      @log_file   = File.join(Dir.pwd, 'log', 'god.log')

      @config_file  = File.join(Dir.pwd, 'config', 'god.yml')
      @daemonize = true
      # This is going to be a part of the .sock file name e.g. "/tmp/god.17165.sock"
      # Change this in the configuration file to be able to run multiple instances of god
      @port = 17165
      @syslog = true
      @events = true
      @options = {
        daemonize: @daemonize,
        port: @port,
        syslog: @syslog,
        events: @events,
        config: File.expand_path("../#{@process_name}.god", __FILE__),
        log: @log_file
      }
    end

  end
end
