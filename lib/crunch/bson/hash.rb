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
    
    # Returns a Ruby hash from the given BSON binary string.
    # @param [String] bson A BSON string. Will be cast to binary if it isn't already.
    # @return [Hash] All keys will be strings; values will be the inverse of the #from_hash method.
    # @see http://bsonspec.org/#/specification
    def self.to_hash(source)
      source.force_encoding Encoding::BINARY
      length = to_int(source.slice!(0,4))
      bson = source.slice!(0,length - 5)
      raise BSONError, "BSON had invalid document structure (expected \\x00 at byte #{length}, got: #{source})" unless source == "\x00"

      hash = {}
      until bson.empty?
        element_type = bson.slice!(0)
        element_name = bson.slice!(/[^\0]+/u)
        throwaway = bson.slice!(0)
        
        # We're inlining this to avoid unnecessary string copying.  I'm not thrilled
        # about it either.  This method is too long!
        case element_type.getbyte(0)
        when 1
          element = to_float(bson.slice!(0,8))
        when 2
          element_length = to_int(bson.slice!(0,4))
          element = bson.slice!(0,element_length - 1).force_encoding(Encoding::UTF_8)
          throwaway = bson.slice!(0)
        when 16
          element = to_int(bson.slice!(0,4))
        when 18
          element = to_int(bson.slice!(0,8))
        end
        hash[element_name] = element
      end
      # Step through keys and types
      # until bson.empty? do
      # end
      hash
    end
  end
end
