require 'eventmachine'

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
    @@databases ||= {}
    
    attr_reader :name, :host, :port, :command, :min_connections, :max_connections, :requests
          
    
    # Returns a database object from which you can query or obtain 
    # Crunch::Collections. An immediate connection will be made to verify
    # the connection and authentication parameters.  If the database doesn't
    # exist, it will be created if possible.  (Pass :create => false if you
    # don't want this.)
    #
    # @param [String] name The name of the MongoDB database
    # @param [optional, Hash] opts Connection options
    # @option opts [String]  :host Connection hostname (defaults to localhost)
    # @option opts [Integer] :port Connection port (default to 27017)
    # @option opts [String]  :user Authentication username, if needed
    # @option opts [String]  :pass Authentication password, if needed
    # @option opts [Boolean] :admin Check the username and password against the 'admin' database instead of the named database (defaults to false)
    # @option opts [Boolean] :create Create the database if it doesn't exist (defaults to true)
    # @option opts [Integer] :min_connections Always maintain at least this many connections (defaults to 1)
    # @option opts [Integer] :max_connections Never create more than this many connections (defaults to 10)
    # @option opts [Integer] :heartbeat Frequency (in seconds) to perform connection maintenance (defaults to 1)
    # @return Database The new or existing database object
    def self.connect(name, opts={})
      # Flesh out our options, we're gonna need them...
      opts.merge! name: name.to_s
      opts[:host] ||= 'localhost'
      opts[:port] ||= 27017
      
      @@databases[opts] ||= new opts
    end
    
    # Accepts a message to be sent to MongoDB (insert, update, query, etc.), schedules it
    # in EventMachine, and returns immediately.
    #
    # @param [Message] message An instance of a Message subclass
    # @return true
    def <<(message)
      raise DatabaseError, "The data to be sent must be a Message class; instead you sent a #{message.class}" unless message.respond_to?(:deliver)
      
      if message.respond_to?(:sender) 
        senders[message.request_id] = {sender: message.sender, sent_at: Time.now}
      end
      
      EventMachine.defer ->{message.deliver}, ->message_data {requests.push message_data}
      true
    end
    
    # Receives a deserialized reply message from MongoDB and routes it to the original sender.
    def receive_reply(reply)
      # The 'response_to' field is the third 32-bit integer in the message
      reply_id = reply[8..11].unpack('V').first
      sender(reply_id).succeed reply
    end
    
    private_class_method :new
    
 
    # Returns a Crunch::Collection from the database. Really just a shortcut for {Collection::new}.
    #
    # @param [String] name The base name of the collection to retrieve
    def collection(name)
      Collection.send :new, self, name
    end
      
    # The number of messages waiting in the queue to be sent to the Mongo server.
    # In a happy world where there enough connections to handle requests, this will
    # remain close to 0.
    def pending_count
      @heart_mutex.synchronize{requests.size}
    end
    
    # The number of connections to the Mongo server this Database is maintaining.
    # This is ordinarily self-managed, but you can set minimum and maximum counts
    # to resize the connection pool if you're the micromanaging type.
    def connection_count
      @heart_mutex.synchronize{connections.size}
    end
    
    
    # The minimum number of connections to maintain at any time. Defaults
    # to 1.  If you raise this number at runtime or connections crash
    # or timeout, new connections will be made at the next database
    # heartbeat.  Setting it to 0 is possible but usually pointless; it
    # simply means a connection will be instantiated when a request shows
    # up in the queue, introducing delays.
    # 
    # To maintain a constant number of connections, set min_connections
    # and max_connections to be equal to each other. Setting min_connections
    # to a value _higher_ than max_connections will raise an exception.
    def min_connections=(val)
      raise DatabaseError, "You can't set min_connections to #{val}. Use a non-negative integer." unless val.kind_of?(Integer) and val >= 0
      raise DatabaseError, "You can't set min_connections to #{val} when max_connections is #{max_connections}." if val > max_connections
      @heart_mutex.synchronize{@min_connections = val}
    end
    
    # The maximum numer of connections to maintain at any time. Defaults
    # to 10.   If you reduce this number at runtime below the number of
    # active connections, some connections will be closed at the next
    # database heartbeat.  Otherwise, connections will slowly die back
    # down to min_connections if load is light.
    # 
    # Setting min_connections and max_connections equal to each other
    # will maintain a constant number of connections. Setting max_connections
    # to a value _lower_ than max_connections will raise an exception.
    # Setting both to 0 is possible but horrendously inefficient; it will
    # force connections to be created when a request is in the queue and
    # then die off at the next heartbeat.
    def max_connections=(val)
      raise DatabaseError, "You can't set max_connections to #{val}. Use a non-negative integer." unless val.kind_of?(Integer) and val >= 0
      raise DatabaseError, "You can't set max_connections to #{val} when min_connections is #{min_connections}." if val < min_connections
      @heart_mutex.synchronize{@max_connections = val}
    end
    
    # Set the frequency (in seconds) at which the database runs connection maintenance.
    # Setting it to 0 cancels 
    # @see #heartbeat
    def heartbeat=(val)
      raise DatabaseError, "You can't set heartbeat to #{val}. Use a non-negative integer or float." unless val.kind_of?(Numeric) and val >= 0
      @heart_mutex.synchronize {@heart.interval = val}
    end
    
    # The frequency (in seconds) at which the database runs connection
    # maintenance.  On every heartbeat, the following happens:
    # 
    # 1. If the number of connections *n* is less than *min_connections*,
    # (*min_connections* - *n*) new connections are created.
    # 
    # 2. If the number of connections *n* is greater than *max_connections*,
    # the oldest (*n* - *max_connections*) connections are sent an expire
    # signal to terminate after their current request.
    # 
    # 3. If the pending request queue exceeds the current number of
    # connections, a single new connection is created.
    # 
    # 4. If the pending request queue has been at 0 or 1 for (max_connections
    # + min_connections - connections)**2 consecutive heartbeats, the
    # oldest connection is expired.
    def heartbeat
      @heart_mutex.synchronize {@heart.interval}
    end
    
    
  protected
    attr_reader :connections, :senders
    
    # Given a request ID from a query response, returns the object that originally sent the message.
    def sender(request_id)
      @senders[request_id] && @senders[request_id][:sender]
    end
    
    # 
    def initialize(opts)
      @name, @host, @port = opts[:name], opts[:host], opts[:port]
      @max_connections = opts[:max_connections] || 10
      @min_connections = opts[:min_connections] || 1
      @senders = Hash.new
      @command = CommandCollection.send(:new, self)
      @connections = []
      @heart_mutex = Mutex.new
      @requests = EventMachine::Queue.new
      
      # We start EM in a thread and make a new connection.  If it's already
      # running, this'll just run the code and return right away.
        
      Thread.new do
        @heart_mutex.lock
        EventMachine.run do
          @min_connections.times do 
            @connections << EventMachine.connect(host, port, Crunch::Connection, self)
          end
          @heart = EventMachine::PeriodicTimer.new((opts[:heartbeat] || 1), self.method(:perform_heartbeat))
          @heart_mutex.unlock
        end
      end
      
      # Give EM a chance to start before we come back to the application
      Thread.pass while connection_count < min_connections
    end
    
    # Maintains connections
    def perform_heartbeat
      # If some non-EventMachine thread is looking at our connections, don't freak out; 
      # just skip a turn.
      return false unless @heart_mutex.try_lock
      
      # Create connections if there aren't enough
      current = @connections.size
      if current < @min_connections
        (@min_connections - current).times do 
          @connections << EventMachine.connect(host, port, Crunch::Connection, self)
        end
      end
    ensure
      @heart_mutex.unlock
    end
  end
end