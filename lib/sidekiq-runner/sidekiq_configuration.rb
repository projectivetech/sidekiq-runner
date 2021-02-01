require 'yaml'

module SidekiqRunner
  class SidekiqConfiguration
    include Enumerable

    RUNNER_ATTRIBUTES = [:config_file]
    RUNNER_ATTRIBUTES.each { |att| attr_accessor att }

    attr_reader :sidekiqs

    def initialize
      @config_file =
        if defined?(Rails)
          File.join(Rails.root, 'config', 'sidekiq.yml')
        else
          File.join(Dir.pwd, 'config', 'sidekiq.yml')
        end

      @sidekiqs    = {}
    end

    def self.default
      @default ||= SidekiqConfiguration.new
    end

    def self.get
      config = default.dup
      config.merge_config_file!
      config.sane?
      config
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

    def add_instance(name)
      fail "Sidekiq instance with the name '#{name}' already exists! No duplicates please." if @sidekiqs.key?(name)

      @sidekiqs[name] = SidekiqInstance.new(name)
      yield @sidekiqs[name] if block_given?
    end

    # Top-level single instance configuration methods, partially for backward compatibility.

    (SidekiqInstance::CONFIG_FILE_ATTRIBUTES + SidekiqInstance::RUNNER_ATTRIBUTES).each do |meth|
      define_method("#{meth}=") do |val|
        ensure_default_sidekiq!
        @sidekiqs.each { |_, skiq| skiq.send("#{meth}=", val) }
      end
    end

    def queue(name, weight = 1)
      fail 'Multiple Sidekiq instances defined and queue() outside of instance block called.' if @sidekiqs.size > 1

      ensure_default_sidekiq!
      @sidekiqs.values.first.add_queue(name, weight)
    end

    alias_method :add_queue, :queue
    alias_method :configfile=, :config_file=

    # Callbacks.

    %w(start stop).each do |action|
      %w(success error).each do |state|
        attr_reader "#{action}_#{state}_cb".to_sym

        define_method("on_#{action}_#{state}") do |&block|
          instance_variable_set("@#{action}_#{state}_cb".to_sym, block)
        end
      end
    end

    def ensure_default_sidekiq!
      add_instance('sidekiq_default') if empty?
    end

    def merge_config_file!
      yml = File.exist?(config_file) ? YAML.load_file(config_file) : {}
      yml = Hash[yml.map { |k, v| [k.to_sym, v] }]

      @sidekiqs.each_value { |skiq| skiq.merge_config_file!(yml) }
    end

    def sane?
      fail 'No sidekiq instances defined. Nothing to run.' if @sidekiqs.empty?

      @sidekiqs.each_value { |skiq| skiq.sane? }
    end
  end
end
