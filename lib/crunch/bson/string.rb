# encoding: BINARY

module Crunch
  module BSON
    # A BSON `cstring` is defined simply as a UTF8-encoded string with a null terminator. 
    # We encode to UTF-8, strip out any null characters from the source itself, then 
    # pin one to the end.
    # @param [Object] str Can actually be any type; the `#to_s` method will be called on it.
    # @option opts [Boolean] :normalized If true, assume we have a string that's already UTF-8 encoded, and skip these conversions for speed.
    # @return [String] A UTF8-encoded string ending with the null character "\x00"
    def self.cstring(str, opts={})
      str = str.to_s.encode(Encoding::UTF_8) unless opts[:normalized]
      str.tr("\x00",'') << 0
    end
    
    # Produces a BSON string type, which is defined as:
    # 1. A 32-bit number giving the length in bytes of the _rest_ of the string;
    # 2. The string itself, encoded in UTF-8;
    # 3. A null character, "\x00".
    # @param [Object] str Can actually be any type; the `#to_s` method will be called on it.
    # @option opts [Boolean] :normalized If true, assume we have a string that's already UTF-8 encoded, and skip these conversions for speed.
    # @return [String] A binary BSON string
    def self.from_string(str, opts={})
      str = str.to_s.encode(Encoding::UTF_8) unless opts[:normalized]
      out = str << 0
      (from_int(out.bytesize, length: 4) + out).force_encoding(Encoding::BINARY)
    end
    
  end
end
