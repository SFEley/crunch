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
    @@databases ||= {}

    attr_reader :name, :host, :port, :command, :min_connections, :max_connections, :requests, :timeout, :heartbeat


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
      options = Crunch.options.merge(opts)
      options[:name] = name.to_s

      @@databases[options] ||= new options
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
      requests.size
    end

    # The number of connections to the Mongo server this Database is maintaining.
    # This is ordinarily self-managed, but you can set minimum and maximum counts
    # to resize the connection pool if you're the micromanaging type.
    def connection_count
      connections.size
    end


  protected
    attr_reader :connections, :senders

    # Given a request ID from a query response, returns the object that originally sent the message.
    def sender(request_id)
      @senders[request_id] && @senders[request_id][:sender]
    end

    # Maintains connections
    def perform_heartbeat
      # Create connections if there aren't enough
      (min_connections - connection_count).times do
        @connections << EventMachine.connect(host, port, Crunch::Connection, self)
      end
    end

    def initialize(opts)
      opts.each {|k,v| instance_variable_set "@#{k}".to_sym, v}
      @senders = Hash.new
      @command = CommandCollection.send(:new, self)
      @connections = []
      @requests = EventMachine::Queue.new

      # We start EM in a thread and make a new connection.  If it's already
      # running, this'll just run the code and return right away.

      Thread.new do
        EventMachine.run do
          min_connections.times do
            @connections << EventMachine.connect(host, port, Crunch::Connection, self)
          end
          @heart = EventMachine::PeriodicTimer.new(heartbeat, self.method(:heartbeat))
        end
      end

      # Give EM a chance to start before we come back to the application
      Thread.pass while connection_count < min_connections
    end
    
  end
end
