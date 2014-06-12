require 'sidekiq-runner/configuration'
require 'sidekiq-runner/version'

require 'open3'
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

    run(:start, cmd, config) do
      break unless config.verify_ps

      # It might take a while for sidekiq to start.
      sleep 1
      abort('Failed to verify that Sidekiq is now running.') unless running?
    end
  end

  def self.stop
    config = Configuration.get

    abort('Sidekiq is not running.') unless running?

    cmd = []
    cmd << (config.bundle_env ? 'bundle exec sidekiqctl' : 'sidekiqctl')
    cmd << 'stop'
    cmd << config.pidfile
    cmd << '60'

    run(:stop, cmd, config)

    # Make sure the pidfile is deleted as sidekiqctl does not delete stale pidfiles.
    FileUtils.rm(config.pidfile) if File.exists?(config.pidfile)
  end

  def self.running?
    config = Configuration.get

    return false unless File.exists?(config.pidfile)
    Process.getpgid(File.read(config.pidfile).strip.to_i)
    true
  rescue
    false
  end

  def self.settings
    Configuration.get.to_hash
  end

private

  def self.run(action, cmd, config)
    cmd   = cmd.join(' ')
    chdir = config.chdir || Dir.pwd

    sout, serr, st = Open3.capture3(cmd, chdir: chdir )

    if !st.success?
      puts "Failed to execute: #{cmd}"
      puts "STDOUT: #{sout}"
      puts "STDERR: #{serr}"
    end

    # Have the result verified externally.
    yield if block_given?

    cb = st.success? ? "#{action}_success_cb" : "#{action}_error_cb"
    cb = config.send(cb.to_sym)
    cb.call if cb
  end
end
