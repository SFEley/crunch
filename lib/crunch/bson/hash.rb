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
  end
end
