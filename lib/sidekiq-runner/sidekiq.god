$LOAD_PATH.unshift "#{File.expand_path('../..', __FILE__)}"
require 'sidekiq-runner'

sidekiq_config = SidekiqRunner::SidekiqConfiguration.get
god_config = SidekiqRunner::GodConfiguration.get

God.terminate_timeout = god_config.stop_timeout + 10

god_config.generic_watchers.each do |block|
  God.watch do |w|
    block.call(w)
  end
end

sidekiq_config.each do |name, skiq|
  God.watch do |w|
    w.name = name

    # Set start command.
    w.start = skiq.build_start_command

    # Set logfile
    w.log = skiq.logfile

    # Set stop command.
    w.stop_timeout = god_config.stop_timeout

    # Set uid/gid if requested.
    w.uid = skiq.uid if skiq.uid
    w.gid = skiq.gid if skiq.gid

    # Working directory has to be set properly.
    # Be aware that by default, God sets the working directory to / (root dir).
    w.dir = skiq.chdir || (defined?(Rails) ? Rails.root : Dir.pwd)

    # Determine the state on startup.
    # If process is running move to 'up' state, otherwise move to 'start' state.
    # States transitions: http://godrb.com/
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.interval = 5
      end
    end

    # Determine when process has finished starting.
    # If process is running move to 'up' state.
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.interval = 5
      end

      # If the process went down during state change, try 5 times, on failure move to 'start' state again.
      on.condition(:tries) do |c|
        c.times = 3
        c.interval = 5
        c.transition = :start
      end
    end

    # Start if process is not running.
    w.transition(:up, :start) do |on|
      on.condition(:process_running) do |c|
        c.running = false
        # Set poll interval in case kqueue/netlink events won't work (you have to
        # trigger god with root privileges for events to work).
        c.interval = god_config.interval
      end
    end

    # Monitor process memory usage.
    if god_config.maximum_memory_usage
      w.restart_if do |restart|
        restart.condition(:memory_usage) do |c|
          c.above = god_config.maximum_memory_usage.to_i.megabytes
          c.times = 3
          c.interval = god_config.interval
        end
      end
    end

    if skiq.config_blocks.length > 0
      skiq.config_blocks.each { |blk| blk.call(w) }
    end

    w.lifecycle do |on|
      on.condition(:flapping) do |c|
        c.to_state = [:start, :restart] # If this watch is started or restarted...
        c.times = 5                     # 5 times
        c.within = 5.minutes            # within 5 minutes
        c.transition = :unmonitored     # then unmonitor it.
        c.retry_in = 10.minutes         # Then after 10 minutes monitor it again to see if it was just a temporary problem.
        c.retry_times = 5               # If the process is seen to be flapping 5 times
        c.retry_within = 2.hours        # within 2 hours, then give up completely.
      end
    end
  end
end
