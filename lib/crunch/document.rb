module Crunch
  
  # Represents a single document object in MongoDB. Essentially a hash that knows how to serialize itself
  # into BSON and send updates about itself to the database.
  class Document < Fieldset
    attr_reader :database, :collection
    
    # The fully qualified "database.collection" name.  (We query the Collection for it.)
    def collection_name
      @collection.full_name
    end
        
    # When called by the user, produces an unsaved document that won't show up in MongoDB until you call {#save} or {#update}. Depending on your use case, this often isn't
    # what you want.  Consider {Database#insert} or {Collection#insert} instead.
    #
    # @param [Crunch::Database] database The MongoDB database that will store this document (required)
    # @param [Crunch::Collection, String] collection An existing collection in the database; either the object or its name (required)
    # @param [optional, Hash, String, BSON::ByteBuffer] data Sets the hash values -- either directly, or after deserializing if a BSON binary string is provided
    def initialize(database, collection, data=nil)
      @database = database
      @collection = case collection
      when Collection then collection
      when String then Collection.new @database, collection
      else
        raise DocumentError, "Crunch::Document requires a collection! You provided: #{collection.class}"
      end
      
      # Make sure we have an ID
      case data
      when Hash then super(Hash['_id', BSON::ObjectID.new].merge!(data))
      when nil then super(Hash['_id', BSON::ObjectID.new])
      when String, BSON::ByteBuffer then super(data)  # We'll assume the binary data came from Mongo and has an ID in it
      else raise DocumentError, "Crunch::Document can only be initialized from a hash or binary data! You supplied: #{data}"
      end
    end
  end
end