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
                          
    
    attr_reader :name, :host, :port, :requests, :connections
    attr_accessor :min_connections, :max_connections, :heartbeat, :on_heartbeat
    
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
    
    # The number of active connections to the MongoDB server. This is self-managed
    # according to request load; see the #min_connections and #max_connections
    # attributes to manage it.
    # @return Integer
    def connection_count
      @connections_mutex.synchronize do
        @connections.length
      end
    end
    
    # The number of requests waiting in the queue to be send to the MongoDB server.
    # If this is higher than the number of active connections, more connections will
    # be created.
    # @return Integer
    def pending_count
      @requests.size
    end
    
    # Push a new request onto the request queue, to be processed by one of the
    # available connections.  The object passed MUST be an instance of 
    # Crunch::Request.  Returns the Database again so that requests can be 
    # chained if necessary.
    # @param Request request
    # @return Database
    def <<(request)
      raise DatabaseError, "Requests passed via << must be subclasses of Crunch::Request" unless request.kind_of?(Crunch::Request)
      request.begin
      @requests.push request
      self
    end
    
    # Returns the singleton Collection instance for the given name.
    # @param [String, Symbol] name
    def collection(name)
      @collections[name.to_sym] ||= Collection.send :new_from_database, self, name.to_s
    end
       
    
  
  private
    def initialize(options)
      super
      # Set all of our options in one fell swoop
      options.each {|k,v| instance_variable_set "@#{k}".to_sym, v}
            
      # Initialize the connection pool and request queue
      @connections = []
      @connections_mutex = Mutex.new
      @heartbeat_timer = nil
      @heartbeat_count = 0
      @requests = EM::Queue.new
      @collections = {}
      perform_heartbeat = EM::Callback(self, :perform_heartbeat)
      
      # Start EventMachine in its own thread. If it's already running, 
      # this will just pass the work to it and then come back.
      Thread.new do
        EventMachine.run do
          min_connections.times {add_connection}
          @heartbeat_timer = EM::PeriodicTimer.new(heartbeat, method(:perform_heartbeat))
        end
      end
      
      Thread.pass until connection_count >= min_connections
    end

    def add_connection
      @connections_mutex.synchronize do
        @connections << EM.connect(host, port, Connection, self)
        @heartbeat_count = 0
      end
    end
    
    def remove_connection
      @connections_mutex.synchronize do
        self << ShutdownRequest.new(self) # Put a suicide note into the queue
        @heartbeat_count = 0
      end
    end
    
    def perform_heartbeat
      # Clear away dead connections
      @connections_mutex.synchronize do
        @connections.reject! {|c| c.status == :terminated}
      end
      
      # Add or remove connections according to request queue size
      pc, cc = pending_count, connection_count
      
      if pc > cc or cc < min_connections      # We have more requests than connections
        add_connection
      elsif pc < cc and cc > min_connections  # We have more connections than requests
        remove_connection if (@heartbeat_count += 1) >= (cc**2) 
      else                                    # They even out
        @heartbeat_count = 0
      end
      
      # Custom user events
      @on_heartbeat.call if @on_heartbeat
    end
    
  end
end