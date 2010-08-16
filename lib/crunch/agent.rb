# Defines a helper object that serves as an intermediary between Documents or
# Groups and the Database.  It creates a query to retrieve whatever data's
# asked for and sends it to the Database, then sets up callbacks to receive
# the response. This is meant to be an abstract class; by itself it only does
# some header validation, but subclasses will parse the responses and pass
# them further up the callback chain. Agents are short-lived and only run a
# single query once.
#
# This separates concerns rather nicely. Documents that are prepopulated with
# data (say, from a Group) don't have to worry about how to talk to the
# Database.  The Database doesn't have to care whether it's routing traffic
# for a document or a group.  And even the Agent object doesn't have to keep
# explicit track of its creator; the creator can set its own callback and let
# the data fall into place with the magic of closures. (Closures are a bit
# like The Force, surrounding and penetrating all object data and binding it
# together. But without the midichlorians.)
module Crunch
  class Agent
    include EventMachine::Deferrable
    
    attr_reader :database, :collection, :message, :conditions, :fields, :limit, :skip

    # Our base Agent is created with whatever information is necessary to 
    # construct a working MongoDB query. Subclasses will also accept the
    # parameters to tie responses to their owners.
    #
    # @param [Collection] collection We need to know where to ask
    # @param [Fieldset] conditions We must have _something_ to ask the Database
    # @option [Array] fields Only retrieve these fields from documents
    # @option [Integer] limit Only retrieve this many records
    # @option [Integer] skip Start at this position in the DB's matching records
    def initialize(collection, conditions, options={})
      super
      @collection, @conditions = collection, conditions
      @database = @collection.database
    
      @fields = options[:fields]
      @limit = options[:limit]
      @skip = options[:skip]

      @message = QueryMessage.new self, 
                                  conditions: @conditions, 
                                  fields: @fields, 
                                  limit: @limit, 
                                  skip: @skip
      
      
      # Parse the reply's header and pass it on. We declare this in the initializer
      # because we want it to be the first callback that's run; we either fail early
      # or send slightly more refined data to our subclasses.
      #
      # @see http://www.mongodb.org/display/DOCS/Mongo+Wire+Protocol
      callback do |mongo_data| 
        header = {}
        header[:message_length],
        header[:request_id],
        header[:response_to],
        header[:op_code],
        header[:response_flags],
        header[:cursor_id],  # The 'Q' pack option may get 64-bit endianness wrong, but we don't care; we're not going to _use_ this number, just send it back to the DB.
        header[:starting_from],
        header[:number_returned],
        documents = mongo_data.unpack('VVVVVQVVa*')
        
        # Fail early, fail often
        fail HeaderError.new("Incomplete reply! Expected #{mongo_data.bytesize} bytes, got #{header[:message_length]}.") unless header[:message_length] == mongo_data.bytesize
        
        fail HeaderError.new("Wrong reply! The handler for request #{@message.request_id} got an answer to request #{header[:response_to]}.") unless header[:response_to] == message.request_id
        
        # Check our response flags for errors
        fail QueryError.new("MongoDB reports unknown cursor for cursor id #{message.cursor_id}.") if (header[:response_flags] & 1) > 0
        fail QueryError.new("MongoDB reports query failure: #{documents}") if (header[:response_flags] & 2) > 0
        
        # Pass our parsed results down the chain
        set_deferred_status :succeeded, header, documents
      end
      
      # Catch failures.  If we don't get an exception back, it was probably a timeout. Confirm this and
      # raise the appropriate exception for downstream handling.
      errback do |exception=nil|
        unless exception
          if message.delivered_at and (Time.now.utc - message.delivered_at) >= database.timeout
            fail TimeoutError.new "Request #{message.request_id} timed out."
          else
            fail ResponseError.new "Unknown error on request #{message.request_id}."
          end
        end
      end
    end
  
  
    # Sends the message to the Database and waits for the reply. 
    def deliver
      database << message
      timeout(database.timeout)
    end
    
    # The fully qualified "database.collection" name.  (We query the Collection for it.)
    def collection_name
      collection.full_name
    end
    
    # A convenience method that allows Agents to do their work in a single method call.
    # Does the following:
    #   1. Creates a new Agent object with the parameters given;
    #   2. If a block is provided, assigns it to the new agent as a callback;
    #   3. Calls the new agent's {#query} method;
    #   4. Returns the new agent so that other reindeer games can be played.
    #
    # @param [Collection] collection We need to know where to ask
    # @param [Fieldset] conditions We must have _something_ to ask the Database
    # @option [Array] fields Only retrieve these fields from documents
    # @option [Integer] limit Only retrieve this many records
    # @option [Integer] skip Start at this position in the DB's matching records
    def self.run(collection, conditions, options={}, &callback)
      agent = self.new collection, conditions, options
      agent.callback &callback if callback
      agent.deliver
      agent
    end
    
    
    
  end
end  