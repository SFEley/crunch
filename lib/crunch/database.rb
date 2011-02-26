require 'crunch'

module Crunch

  # Our highest-level object is NOT the connection; it's the database.
  # Each database has one write connection and may have multiple read
  # connections at any given time, which will be managed automatically
  # by Crunch, and can accept one authentication (if necessary).  This
  # dramatically simplifies the API.
  #
  # To get an instance, call Crunch::Database.connect instead of .new --
  # this ensures that other attempts to connect with the same credentials
  # will get the same database object and share the same connections.
  class Database
    DEFAULTS = {
      host: 'localhost',
      port: 27017,
      min_connections: 1,
      max_connections: 10,
      heartbeat: 1.0
    }
    
    @@databases = {}
    @@mutex = Mutex.new   # Let's be threadsafe here, because the actual access into the
                          # @@databases hash does not happen in EventMachine.
    
    attr_reader :name, :host, :port
    attr_accessor :min_connections, :max_connections, :heartbeat
    
    # Singleton pattern -- make .new private and return an exception if called from outside
    class << self
      alias_method :private_new, :new
      private :private_new
      
      def new(*args)
        raise DatabaseError, "Crunch::Database is a singleton. Run Crunch::Database.connect instead of .new."
      end
    end
        
    
    def self.connect(name, opts={})
      options = DEFAULTS.merge(opts).merge(name: name)
      signature = options.values_at :name, :host, :port
      @@mutex.synchronize do
        if database = @@databases[signature]
          # Reset tuning options if any were provided
          database.min_connections = opts[:min_connections] if opts.key?(:min_connections)
          database.max_connections = opts[:max_connections] if opts.key?(:max_connections)
          database.heartbeat = opts[:heartbeat] if opts.key?(:heartbeat)
          database
        else
          @@databases[signature] = private_new options
        end
      end
    end

    private
      def initialize(options)
        super
        @name, @host, @port, @min_connections, @max_connections, @heartbeat = options.values_at :name, :host, :port, :min_connections, :max_connections, :heartbeat
      end


  end
end