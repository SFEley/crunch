# encoding: BINARY
module Crunch
  module BSON
    # Returns the BSON document corresponding to the given Ruby hash.
    # @param [Hash] hash
    # @option opts [Boolean] :normalized If true, we assume keys are already UTF-8 strings and don't waste time with conversions (e.g., if coming from a Fieldset)
    def self.from_hash(hash, opts={})
      size, bson = 5, "\x00\x00\x00\x00"
      hash.each do |key, value|
        keystring = cstring(key, opts)
        valtype, valsize, valstring = from_element(value)
        size += keystring.bytesize + valsize + 1
        bson << valtype << keystring << valstring
      end
      bson << 0   # Ends with a null
      sizestr = from_int(size, length: 4)
      bson.setbyte 0, sizestr.getbyte(0)  # Crude, but fastest way to replace the START
      bson.setbyte 1, sizestr.getbyte(1)  # of a string.
      bson.setbyte 2, sizestr.getbyte(2)
      bson.setbyte 3, sizestr.getbyte(3)
      bson
    end
    
    # Identifies the type of object that's passed to it, converts it to BSON,
    # and returns its type, size, and the BSON string.
    # @param [Object] value Something that _can_ be converted to BSON
    # @return [Array] Type number, size in bytes, and the BSON string
    def self.from_element(value)
      case value
      when Float then [1, 8, from_float(value)]
      when String 
        out = from_string(value)
        [2, out.bytesize, out]
      when Hash
        out = from_hash(value)
        [3, out.bytesize, out]
      when Integer
        out = from_int(value)
        if out.bytesize == 4
          [16, 4, out]
        elsif out.bytesize == 8
          [18, 8, out]
        else 
          raise BSONError, "BSON integer overflow: #{value} is larger than 64 bits."
        end
      end
    end
  end
end
