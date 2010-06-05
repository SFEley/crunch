require 'bson'

module Crunch
  
  # Represents a single document object in MongoDB. Essentially a hash that knows how to serialize itself
  # into BSON and send updates about itself to the database.
  class Document < Hash
    attr_reader :collection
    
    private_class_method :new
    
    # Returns the document as a binary string in BSON format.
    # @see http://bsonspec.org/#/specification
    # @return BSON::ByteBuffer
    def to_s
      BSON.serialize(self).to_s
    end
    
    private
    
    # New documents are produced by collections when you insert or retrieve something.  Don't try to
    # make your own, or the collection will lose track.
    #
    # @param [Crunch::Collection] collection The collection that owns this document
    # @param [optional, Hash, String, BSON::ByteBuffer] data Sets the hash values -- either directly, or after deserializing if a BSON binary string is provided
    def initialize(collection, data=nil)
      super(nil)
      @collection = collection
      hash = case data
      when Hash then data
      when String then BSON.deserialize(BSON::ByteBuffer.new(data))
      when BSON::ByteBuffer then BSON.deserialize(data)
      when nil then nil
      else raise DocumentError, "Crunch::Document can only be initialized from a hash or binary data! You supplied: #{data}"
      end
      
      # We want the _id to come first
      self['_id'] = BSON::ObjectID.new unless hash && hash.has_key?('_id')
      self.merge!(hash) if hash
    end
  end
end