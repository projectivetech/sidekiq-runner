require 'sidekiq-runner/configuration'
require 'sidekiq-runner/version'

require 'fileutils'

module SidekiqRunner
  def self.configure
    yield Configuration::default if block_given?
  end

  def self.start
    config = Configuration.get

    abort("Sidekiq is already running (pid: #{File.read(config.pidfile).strip}).") if File.exists?(config.pidfile)

    cmd = []
    cmd << (config.bundle_env ? 'bundle exec sidekiq' : 'sidekiq')
    cmd << '-d' if config.daemonize
    cmd << "-c #{config.concurrency}"
    cmd << "-e #{Rails.env}" if defined?(Rails)
    cmd << '-v' if config.verbose
    cmd << "-L #{config.logfile}"
    cmd << "-P #{config.pidfile}"
    config.queues.each do |q, w|
      cmd << "-q #{q},#{w}"
    end

    if config.requirefile
      cmd << "-r #{config.requirefile}"
    else # Rails is defined, see Configuration.sane?.
      cmd << "-e #{Rails.env}"
    end

    FileUtils.mkdir_p(File.dirname(config.pidfile))
    FileUtils.mkdir_p(File.dirname(config.logfile))
    run(cmd, config)
  end

  def self.stop
    config = Configuration.get

    abort('Sidekiq is not running.') unless File.exists?(config.pidfile)

    cmd = []
    cmd << (config.bundle_env ? 'bundle exec sidekiqctl' : 'sidekiqctl')
    cmd << 'stop'
    cmd << config.pidfile
    cmd << '60'

    run(cmd, config)
  end

private

  def self.run(cmd, config)
    chdir = config.chdir || Dir.pwd
    Dir.chdir(chdir) do
      puts ">> #{cmd.join(' ')}" if config.verbose
      Kernel.exec cmd.join(' ')
    end
  end
end
