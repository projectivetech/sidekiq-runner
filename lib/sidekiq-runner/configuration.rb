require 'yaml'

module SidekiqRunner
  class Configuration
    attr_accessor :configfile
    attr_accessor :bundle_env
    attr_accessor :daemonize
    attr_accessor :chdir
    attr_accessor :requirefile

    CONFIG_FILE_ATTRIBUTES = [ :pidfile, :logfile, :concurrency, :verbose ]
    CONFIG_FILE_ATTRIBUTES.each { |att| attr_accessor att }

    attr_reader   :queues

    def initialize
      @configfile  = File.join(Dir.pwd, 'config', 'sidekiq.yml')
      @bundle_env  = true
      @daemonize   = true
      @chdir       = nil
      @requirefile = nil

      @pidfile     = File.join(Dir.pwd, 'tmp', 'pids', 'sidekiq.pid')
      @logfile     = File.join(Dir.pwd, 'log', 'sidekiq.log')
      @concurrency = 4
      @verbose     = false

      @queues      = []
    end

    def queue(name, weight = 1)
      @queues << [name, weight]
    end

    def merge_config_file!
      if File.exists?(configfile)
        yml = YAML.load_file(config_file)
        CONFIG_FILE_ATTRIBUTES.each do |k|
          v = yml[k] || yml[k.to_sym]
          self.send("#{k}=", v) if v
        end
      end

      self
    end

    def sane?
      raise 'No requirefile given and not in Rails env.' if !defined?(Rails) && !requirefile
      raise 'No queues given.' if queues.empty?
    end

    def self.default
      @default ||= Configuration.new
    end

    def self.get
      config = default.dup
      config.merge_config_file!
      config.sane?
      config
    end
  end
end
