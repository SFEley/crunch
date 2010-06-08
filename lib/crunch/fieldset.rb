require 'bson'

module Crunch
  
  # What the BSON spec describes as a "document" -- a hashlike binary structure capable of storing 
  # specific forms of binary data.  Crunch uses a different classname because the Document class 
  # represents an actual record in the Mongo database and has special behavior.  (It does inherit
  # from Fieldset, however.)
  # @see http://bsonspec.org/#/specification
  class Fieldset < Hash
    # Returns the document as a binary string in BSON format.
    # @see http://bsonspec.org/#/specification
    # @return BSON::ByteBuffer
    def to_s
      BSON.serialize(self).to_s
    end
    
    # Keys are converted into strings on their way in -- this keeps input and output consistent, as BSON serialization forces keys
    # into strings anyway.
    def []=(key, value)
      super(key.to_s, value)
    end
    
    # Keys are converted into strings.
    def merge!(hash)
      super stringify_keys(hash)
    end
    
    # @param [optional, Hash, String, BSON::ByteBuffer] data Sets the hash values -- either directly, or after deserializing if a BSON binary string is provided
    def initialize(data=nil)
      super(nil)
      
      hash = case data
      when Hash then stringify_keys(data)
      when String then BSON.deserialize(BSON::ByteBuffer.new(data))
      when BSON::ByteBuffer then BSON.deserialize(data)
      when nil then nil
      else raise FieldsetError, "Crunch::Fieldset can only be initialized from a hash or binary data! You supplied: #{data}"
      end
      
      self.replace(hash) if hash
    end
    
    private
    
    # Turns all keys into their string values. Inefficient, but it gets too confusing if we don't.
    def stringify_keys(hash)
      out = {}
      hash.each {|k,v| out[k.to_s] = v}
      out
    end
  end
end