module Crunch
  
  # Represents a single document object in MongoDB. Essentially a hash that knows how to serialize itself
  # into BSON and send updates about itself to the database.
  class Document < Fieldset
    attr_reader :database, :collection_name
        
    # When called by the user, produces an unsaved document that won't show up in MongoDB until you call {#save} or {#update}. Depending on your use case, this often isn't
    # what you want.  Consider {Database#insert} or {Collection#insert} instead.
    #
    # @param [Crunch::Database] database The MongoDB database that will store this document (required)
    # @param [String] collection The name of an existing collection in the database
    # @param [optional, Hash, String, BSON::ByteBuffer] data Sets the hash values -- either directly, or after deserializing if a BSON binary string is provided
    def initialize(database, collection, data=nil)
      @database = database
      @collection_name = "#{@database.name}.#{collection}"
      
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