module Crunch
  
  # What the BSON spec describes as a "document" -- a hashlike binary structure.  In practice, a Fieldset
  # is a _lot_ like a Hash, with two major differences:
  #   1. All keys are strings; and
  #   2. It's immutable. (Hence, #[]= and all in-place modifiers like #merge! are missing.)
  #
  # @see http://bsonspec.org/#/specification
  class Fieldset < Hash
  
    # Allow the initializer to call 'replace' before freezing, but nobody else gets to.
    alias_method :private_replace, :replace
    private :private_replace

    # We're immutable!  These pesky modification methods aren't allowed.
    # (If you're wondering WHY we're immutable, consider the difference between MongoDB retrieval techniques
    # and MongoDB value setting techniques. Then consider what it would be like if we had to make every hash
    # in Crunch threadsafe against document changes queued up in EventMachine. Then consider pretty puppies
    # and rainbows, because you're gonna need a break.)
    def []=(*args)
      raise FieldsetError, "Fieldset objects are immutable!"
    end
    alias_method :update,   :[]=
    alias_method :store,    :[]=
    alias_method :shift,    :[]=
    alias_method :replace,  :[]=
    alias_method :reject!,  :[]=
    alias_method :rehash,   :[]=
    alias_method :merge!,   :[]=
    alias_method :delete_if,:[]=
    alias_method :delete,   :[]=
    alias_method :clear,    :[]=

    # @param [optional, Hash, String, Array, BSON::ByteBuffer] data Sets the hash values -- either directly, or after deserializing if a BSON binary string is provided
    def initialize(data=nil)
      super(nil)
      
      hash = case data
      when Fieldset then data   # Don't bother doing anything
      when Hash then stringify_keys(data)
      when String then BSON.to_hash(data)
      when Array then hashify_elements(data)
      when nil then {}
      else raise FieldsetError, "Crunch::Fieldset can only be initialized from a hash, array, or binary data! You supplied: #{data}"
      end
      
      private_replace(hash)
      @string = BSON.from_hash(self)  # Must do this before it's frozen
      self.freeze
    end
    
    
    # Returns the Fieldset as a binary string in BSON format.
    # @see http://bsonspec.org/#/specification
    # @return String
    def to_s
      @string
    end
    alias_method :bin, :to_s
    
    # Returns the Fieldset as an ordinary mutable Hash.
    # @return Hash
    def to_hash
      {}.merge(self)
    end
    
    # Prints the Fieldset with a class identifier.
    # @return String
    def inspect
      "<Fieldset>#{super}"
    end
    
    
    private
    
    # Turns all keys into their string values. Inefficient, but it gets too confusing if we don't.
    def stringify_keys(hash)
      out = {}
      hash.each {|k,v| out[k.to_s] = v}
      out
    end
    
    # Turns an array into a hash in which the elements are keys and the values are all 1.  (Commonly
    # used in MongoDB field and sort orders.)
    def hashify_elements(array)
      out = {}
      array.each {|e| out[e.to_s] = 1}
      out
    end
  end
end