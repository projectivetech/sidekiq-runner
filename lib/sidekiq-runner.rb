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

      # Verify pidfile and process.
      raise 'PID file does not exists!' unless File.exists?(config.pidfile)
      pid = File.read(config.pidfile).strip.to_i
      Process.kill 0, pid rescue raise "No process has pid #{pid}!"
    end
  end

  def self.stop
    config = Configuration.get

    abort('Sidekiq is not running.') unless File.exists?(config.pidfile)

    cmd = []
    cmd << (config.bundle_env ? 'bundle exec sidekiqctl' : 'sidekiqctl')
    cmd << 'stop'
    cmd << config.pidfile
    cmd << '60'

    run(:stop, cmd, config)
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
