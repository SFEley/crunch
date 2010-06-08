module Crunch
  
  # Represents a single document object in MongoDB. Essentially a hash that knows how to serialize itself
  # into BSON and send updates about itself to the database.
  class Document < Fieldset
    attr_reader :collection
    
    private_class_method :new
    
    # @return [String] The fully qualified collection: "database_name.collection_name"
    def collection_name
      @collection.full_name
    end
    
    private
    
    # New documents are produced by collections when you insert or retrieve something.  Don't try to
    # make your own, or the collection will lose track.
    #
    # @param [Crunch::Collection] collection The collection that owns this document
    # @param [optional, Hash, String, BSON::ByteBuffer] data Sets the hash values -- either directly, or after deserializing if a BSON binary string is provided
    def initialize(collection, data=nil)
      @collection = collection
      
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