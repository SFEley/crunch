# encoding: BINARY

module Crunch
  module BSON
    # Represents a string of binary data in BSON. We need a separate type for this 
    # to differentiate it from ordinary strings, which must be in UTF-8.  For 
    # performance reasons, this is a fairly 'dumb' class and doesn't do much
    # calculation or validation.  Users should use the `BSON.binary` method
    # to generate binary BSON classes.
    class Binary
      GENERIC   = "\x00"    # Default subtype
      FUNCTION  = "\x01"    # 'Function' subtype (not well explained in BSON spec)
      OLD       = "\x02"    # Deprecated former binary subtype; encodes length at start of data
      UUID      = "\x03"    # UUID subtype (no special treatment)
      MD5       = "\x05"    # MD5 subtype (no special treatment)
      USER      = "\x80"    # User-defined data subtype (no special treatment)
      
      attr_reader :data, :subtype, :length
      
      # Creates a new BSON binary object from its parameter hash.  The `:length` 
      # option is only likely to be given if we are being given input _from_
      # BSON source.  Likewise, users are unlikely to provide the `:type` option
      # under ordinary circumstances.  (Though they can if they want to.)
      # @param [String] data A binary encoded string. (Convert before passing!)
      # @option opts [String] :subtype A single byte indicating the BSON binary subtype. Use the built-in constants for easy reference. Defaults to Binary::GENERIC.
      # @option opts [String] :length Four little-endian bytes indicating the bytesize of the _data_ (not the full type string).
      def initialize(data, opts={})
        @data = data
        @subtype = opts[:subtype] || GENERIC
        @length = opts[:length] || BSON.from_int(@data.bytesize)
      end
      
      # Returns itself as a BSON-valid binary string.
      # @see http://bsonspec.org/#/specification
      def to_s
        @string ||= @length << @subtype << @data
      end
      
      # Returns a three-element array with:
      # 1. The binary BSON type identifier, 5
      # 2. The length of the full binary string, including the length and subtype
      # 3. The binary string itself
      def element
        @element ||= [5, to_s.bytesize, to_s]
      end
    end
    
    # Produces a BSON binary type, which is defined as:
    # 1. A 32-bit number giving the length in bytes of the binary string (not including the subtype from #2);
    # 2. A binary data subtype, which for right now we're simply forcing to the default of 0;
    # 3. The binary data string itself, with no null terminators or such.
    # @param [String] data The binary data; will be cast to Encoding::BINARY if it isn't already.
    # @option opts [String] :subtype A single-byte binary subtype. (See the constants in the BSON::Binary class.) If you specify Binary::OLD special treatment will be given to the 
    # data string, adding its length again.
    # @return [String] A binary BSON data string
    def self.binary(str, opts={})
      str = BSON.from_int(str.bytesize) << str if opts[:subtype] == Binary::OLD
      Binary.new(str.force_encoding(Encoding::BINARY), opts)
    rescue NoMethodError
      raise BSONError, "A binary string input is required; instead you gave: #{str}"
    end
    
  end
end