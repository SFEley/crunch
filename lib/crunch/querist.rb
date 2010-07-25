# Defines a helper object that serves as an intermediary between Documents or
# Groups and the Database.  It creates a query to retrieve whatever data's
# asked for and sends it to the Database, them sets up callbacks to receive the
# response. This is an abstract class; by itself it does nothing useful with
# the responses, but subclasses will parse the responses and replace data
# within the Document or Group that owns them. Querists are short-lived, and
# die off after their request has succeeded or failed.
#
# This separates concerns rather nicely. Documents that are prepopulated with
# data (say, from a Group) don't have to worry about how to talk to the
# Database.  And the Database doesn't have to care whether it's routing
# traffic for a document or a group.  It's talking to a Querist, and what
# happens next is the Querist's problem.  Think of it like a mortgage broker,
# only without the sorts of incentives that can bring down the global economy.
module Crunch
  class Querist
    include EventMachine::Deferrable
    
    attr_reader :database, :collection, :query, :fields, :limit, :skip

    # Our base Querist is created with whatever information is necessary to 
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
        header[:cursor_id],
        header[:starting_from],
        header[:number_returned],
        documents = mongo_data.unpack('VVVVVQVVa*')
        
        # Fail early, fail often
        fail HeaderError.new("Incomplete reply! Expected #{mongo_data.bytesize} bytes, got #{header[:message_length]}.") unless header[:message_length] == mongo_data.bytesize
        
        fail HeaderError.new("Wrong reply! The handler for request #{@message.request_id} got an answer to request #{header[:response_to]}.") unless header[:response_to] == @message.request_id
        
        fail "MongoDB reports query failure. Response code: #{header[:response_flag]}" unless header[:response_flag] == 0
        
        # Pass on our parsed results
        set_deferred_status :succeeded, header, documents
      end
    end
  
    # The fully qualified "database.collection" name.  (We query the Collection for it.)
    def collection_name
      @collection.full_name
    end
  
    # Reloads (or loads for the first time) the current data. 
    def refresh
      EventMachine.next_tick do
        database << @message
      end
    end
    
    protected
    
    
    
  end
end  