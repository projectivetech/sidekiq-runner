require 'sidekiq-runner/sidekiq_configuration'
require 'sidekiq-runner/god_configuration'
require 'sidekiq-runner/sidekiq_instance'
require 'sidekiq-runner/version'

module SidekiqRunner
  def self.configure
    yield SidekiqConfiguration.default if block_given?
  end

  def self.configure_god
    yield GodConfiguration.default if block_given?
  end

  def self.start
    sidekiq_config, god_config = get_all_settings

    fail 'No sidekiq instances defined. There is nothing to run.' if sidekiq_config.empty?

    abort 'God is running. I found an instance of a running god process. Please stop it manually and try again.' if god_alive?(god_config)

    run(:start, sidekiq_config) do
      puts 'Starting god.'
      God::CLI::Run.new(god_config.options)
    end
  end

  def self.stop
    sidekiq_config, god_config = get_all_settings

    run(:stop, sidekiq_config) do
      God::EventHandler.load

      if god_alive?(god_config)
        puts "Stopping process #{god_config.process_name}."

        # Stop all the processes
        sidekiq_config.each_key do |name|
          God::CLI::Command.new('stop', god_config.options, ['', name])
        end

        puts 'Terminating god.'
        God::CLI::Command.new('terminate', god_config.options, [])
      else
        puts 'God is not running, so no need to stop it.'
      end
    end
  end

  def self.settings
    SidekiqConfiguration.get.to_hash
  end

  private

  def self.get_all_settings
    [SidekiqConfiguration.get, GodConfiguration.get]
  end

  def self.god_alive?(god_config)
    puts 'Checking whether god is alive...'

    require 'drb'
    require 'god/socket'
    DRb.start_service('druby://127.0.0.1:0')
    server = DRbObject.new(nil, God::Socket.socket(god_config.port))

    # ping server to ensure that it is responsive
    begin
      server.ping
    rescue DRb::DRbConnError
      return false
    end
    true
  end

  def self.run(action, sidekiq_config)
    begin
      # Use this flag to actually load all of the god infrastructure
      $load_god = true
      require 'god'
      require 'god/cli/run'

      # Peform the action
      yield if block_given?
      cb = nil
    rescue SystemExit => e
      cb = e.success? ? "#{action}_success_cb" : "#{action}_error_cb"
    ensure
      if [:start, :stop].include? action
        cb = "#{action}_success_cb" unless cb
        cb = sidekiq_config.send(cb.to_sym)
        cb.call if cb
      end
    end
  end

end