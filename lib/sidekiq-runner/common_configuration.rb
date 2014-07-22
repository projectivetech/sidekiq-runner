require 'yaml'

module SidekiqRunner

  # common functions for GodConfiguration and Configuration classes
  class CommonConfiguration
    # this method MUST be reimplemented
    def self.default
      fail(NotImplementedError, "Method \"#{__method__}\" is not implemented in \"#{name}\" class. Please DO implement this method to be able to derive from CommonConfiguration class.")
    end

    RUNNER_ATTRIBUTES = []
    CONFIG_FILE_ATTRIBUTES = []

    @config_file = ''

    def to_hash
      Hash[CONFIG_FILE_ATTRIBUTES.map { |att| [att, send(att)] }]
    end

    def self.get
      config = default.dup
      config.send :merge_config_file!
      config.send :sane?
      config
    end

    private

    def merge_config_file!
      if File.exist?(config_file)
        yml = YAML.load_file(config_file)
        CONFIG_FILE_ATTRIBUTES.each do |k|
          v = nil || yml[k] || yml[k.to_s]
          send("#{k}=", v) unless v.nil?
        end
      end

      self
    end

    def sane?
    end

  end # class
end # module