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
    
    attr_reader :database, :collection, :message, :query, :fields, :limit, :skip

    # Our base Agent is created with whatever information is necessary to 
    # construct a working MongoDB query. Subclasses will also accept the
    # parameters to tie responses to their owners.
    #
    # @param [Collection] collection We need to know where to ask
    # @param [Fieldset] query We must have _something_ to ask the Database
    # @option [Array] fields Only retrieve these fields from documents
    # @option [Integer] limit Only retrieve this many records
    # @option [Integer] skip Start at this position in the DB's matching records
    def initialize(collection, query, options={})
      super
      @collection, @query = collection, query
      @database = @collection.database
    
      @fields = options[:fields]
      @limit = options[:limit]
      @skip = options[:skip]

      @message = QueryMessage.new self, 
                                  query: @query, 
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
        header[:response_flag],
        header[:cursor_id],  # The 'Q' pack option may get 64-bit endianness wrong, but we don't care; we're not going to _use_ this number, just send it back to the DB.
        header[:starting_from],
        header[:number_returned],
        documents = mongo_data.unpack('VVVVVQVVa*')
        
        # Fail early, fail often
        fail HeaderError.new("Incomplete reply! Expected #{mongo_data.bytesize} bytes, got #{header[:message_length]}.") unless header[:message_length] == mongo_data.bytesize
        
        fail HeaderError.new("Wrong reply! The handler for request #{@message.request_id} got an answer to request #{header[:response_to]}.") unless header[:response_to] == message.request_id
        
        fail "MongoDB reports query failure. Response code: #{header[:response_flag]}" unless header[:response_flag] == 0
        
        # Pass our parsed results down the chain
        set_deferred_status :succeeded, header, documents
      end
    end
  
  
    # Sends the message to the Database and waits for the reply. 
    def query
      EventMachine.next_tick do
        database << message
      end
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
    # @param [Fieldset] query We must have _something_ to ask the Database
    # @option [Array] fields Only retrieve these fields from documents
    # @option [Integer] limit Only retrieve this many records
    # @option [Integer] skip Start at this position in the DB's matching records
    def self.run(collection, query, options={}, &callback)
      agent = self.new collection, query, options
      agent.callback &callback if callback
      agent.query
      agent
    end
    
    
    
  end
end  