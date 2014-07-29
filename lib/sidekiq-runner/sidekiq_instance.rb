module SidekiqRunner
  class SidekiqInstance

    CONFIG_FILE_ATTRIBUTES = [:bundle_env, :chdir, :requirefile, :concurrency, :verbose]
    INDIVIDUAL_FILE_ATTRIBUTES = [:pidfile, :logfile]
    CONFIG_FILE_ATTRIBUTES.concat(INDIVIDUAL_FILE_ATTRIBUTES).each { |att| attr_accessor att }

    attr_reader :name, :queues

    def initialize(name)
      fail "No sidekiq instance name given!" if name.empty?

      @name = name
      @queues = []

      @bundle_env   = true
      @daemonize    = true
      @chdir        = nil
      @requirefile  = nil
      @pidfile      = File.join(Dir.pwd, 'tmp', 'pids', "#{@name}.pid")
      @logfile      = File.join(Dir.pwd, 'log', "#{@name}.log")
      @concurrency  = 4
      @verbose      = false

    end

    def add_queue(queue_name, weight = 1)
      fail "Cannot add the queue. The name is empty!" if queue_name.empty?
      fail "Cannot add the queue. The weight is not an integer!" unless weight.is_a? Integer
      fail "Cannot add the queue. The queue with \"#{queue_name}\" name already exist" if @queues.any?{|arr| arr.first == queue_name}
      @queues << [queue_name, weight]
    end

    def sane?
      fail "No queues given for #{@name}!" if @queues.empty?  
    end

    def merge_config!(skiq)
        CONFIG_FILE_ATTRIBUTES.each do |k|
          v = nil || skiq[k]
          send("#{k}=", v) unless v.nil?
        end

      self
    end

  end
end