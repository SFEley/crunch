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
    
    attr_reader :name, :host, :port, :command, :connection
          
    
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
    # @return Database The new or existing database object
    def self.connect(name, opts={})
      # Flesh out our options, we're gonna need them...
      opts.merge! name: name.to_s
      opts[:host] ||= 'localhost'
      opts[:port] ||= 27017
      
      @@databases[opts] ||= new opts[:name], opts[:host], opts[:port]
    end
    
    # Accepts a message to be sent to MongoDB (insert, update, query, etc.), schedules it
    # in EventMachine, and returns immediately.
    #
    # @param [Message] message An instance of a Message subclass
    # @return true
    def <<(message)
      raise DatabaseError, "The data to be sent must be a Message class; instead you sent a #{message.class}" unless message.respond_to?(:deliver)
      
      if message.respond_to?(:sender) 
        @senders[message.request_id] = {sender: message.sender, sent_at: Time.now}
      end
      
      EventMachine.defer ->{message.deliver}, ->message_data {connection.send_data(message_data)}
      true
    end
    
    # Receives a deserialized reply message from MongoDB and routes it to the original sender.
    def receive_reply(reply)
      sender(reply[:reply_id]).receive_data(reply)
    end
    
    private_class_method :new
    
 
    # Returns a Crunch::Collection from the database. Really just a shortcut for {Collection::new}.
    #
    # @param [String] name The base name of the collection to retrieve
    def collection(name)
      Collection.send :new, self, name
    end
      


    
    
  private
    # Given a request ID from a query response, returns the object that originally sent the message.
    def sender(request_id)
      @senders[request_id] && @senders[request_id][:sender]
    end
    
    def initialize(name, host, port)
      @senders = Hash.new
      @name, @host, @port = name, host, port
      @command = CommandCollection.send(:new, self)
      @connection = :placeholder   # Just make a placeholder for the thing for closure purposes
      
      # This would be so much easier if "EventMachine.run" included the reactor_running? check...
      if EventMachine.reactor_running?
        EventMachine.next_tick do
          @connection = EventMachine.connect(host, port)
        end
      else
        Thread.new do 
          EventMachine.run do
            @connection = EventMachine.connect(host, port)
          end
        end
      end
      while @connection == :placeholder
        sleep 0.0001
      end
    end
  end
end