require 'sidekiq-runner/sidekiq_instance'
require 'sidekiq-runner/sidekiq_configuration'
require 'sidekiq-runner/god_configuration'
require 'sidekiq-runner/version'

module SidekiqRunner
  def self.configure
    yield SidekiqConfiguration.default if block_given?
  end

  def self.configure_god
    yield GodConfiguration.default if block_given?
  end

  def self.start
    sidekiq_config, god_config = SidekiqConfiguration.get, GodConfiguration.get

    abort 'God is already running.' if god_alive?(god_config)

    run(:start, sidekiq_config) do
      $0 = "SidekiqRunner/God (#{god_config.process_name})"

      puts 'Starting god.'
      God::CLI::Run.new(god_config.options)
    end
  end

  def self.stop
    sidekiq_config, god_config = SidekiqConfiguration.get, GodConfiguration.get

    run(:stop, sidekiq_config) do
      God::EventHandler.load

      if god_alive?(god_config)
        sidekiq_config.each_key do |name|
          puts "Stopping Sidekiq instance #{name}..."
          God::CLI::Command.new('stop', god_config.options, ['', name])
        end

        puts "Terminating god process #{god_config.process_name}..."
        God::CLI::Command.new('terminate', god_config.options, [])
      else
        abort 'God is not running, so no need to stop it.'
      end
    end
  end

  private

  def self.god_alive?(god_config)
    puts 'Checking whether god is alive...'

    require 'drb'
    require 'god/socket'
    DRb.start_service('druby://127.0.0.1:0')
    server = DRbObject.new(nil, God::Socket.socket(god_config.port))

    # Ping server to ensure that it is responsive.
    begin
      server.ping
    rescue DRb::DRbConnError
      return false
    end
    true
  end

  def self.run(action, sidekiq_config)
    begin

      # Use this flag to actually load all of the god infrastructure.
      $load_god = true
      require 'god'
      require 'god/cli/run'

      # Peform the action.
      yield if block_given?

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
