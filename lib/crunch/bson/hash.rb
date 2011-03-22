# encoding: BINARY
require 'date'

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
      bson << "\x00"   # Ends with a null
      sizestr = from_int(size, length: 4)
      bson.setbyte 0, sizestr.getbyte(0)  # Crude, but fastest way to replace the START
      bson.setbyte 1, sizestr.getbyte(1)  # of a string.
      bson.setbyte 2, sizestr.getbyte(2)
      bson.setbyte 3, sizestr.getbyte(3)
      bson.force_encoding(Encoding::BINARY)
    end
    
    # Identifies the type of object that's passed to it, converts it to BSON,
    # and returns its type, size, and the BSON string.
    # @param [Object] value Something that _can_ be converted to BSON
    # @return [Array] Type number, size in bytes, and the BSON string
    def self.from_element(value)
      case value
      when BSON::MIN then [255, 0, '']
      when BSON::MAX then [127, 0, '']
      when BSON::Javascript then value.element
      when BSON::Binary then value.element
      when BSON::Timestamp then [17, 8, value.to_s]
      when BSON::ObjectID then [7, 12, value.bin]
      when false then [8, 1, "\x00"]
      when true then [8, 1, "\x01"]
      when nil then [10, 0, ""]
        
      when Float then [1, 8, from_float(value)]
      when String   # Could be an actual string _OR_ binary data
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
      when Array  # Turn it into a hash first
        h = {}
        value.each_with_index {|val, i| h[i] = val}
        out = from_hash(h)
        [4, out.bytesize, out]
      when Time
        msec = (value.to_f * 1000).floor
        [9, 8, from_int(msec, length: 8)]
      when Date
        msec = (value.to_datetime.to_time.to_i * 1000)  # Casting to DateTime first ensures UTC zone
        [9, 8, from_int(msec, length: 8)]
      when Regexp
        out = from_regex(value)
        [11, out.bytesize, out]
      when Symbol
        out = from_string(value.to_s)
        [14, out.bytesize, out]
      else
        raise BSONError, "Could not convert unknown data type to BSON: #{value}"
      end
    end
  end
end
