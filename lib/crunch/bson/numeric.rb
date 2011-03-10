module Crunch
  module BSON
    # Returns a binary string representing the given integer in little-endian byte order.
    # Use the `:length` option to specify 4 byte (32-bit) or 8 byte (64-bit) string size.
    # If not specified, will return an arbitrary length string depending on the number's size.
    # @param [Fixnum] val
    # @option [Integer] length Set to 4 or 8 to determine string size.
    # @return [String]
    # @raise [CrunchError] Returns an exception on overflow or underflow.
    def self.from_int(val, opts={})
      # Split the number into 32-bit words
      slice, arr = val, []
      begin
        large = (slice >= 2**31 or slice < -2**31)
        arr << (slice & ((1 << 32) - 1))  # Bitmask 32 bits of 1's
        slice = (slice >> 32)
      end while large or slice > 0 or slice < -1
   
      if opts[:length] 
        size = opts[:length] / 4
        arr << 0 while arr.length < size
        raise BSONError, "BSON conversion overflow: #{val} will not fit into #{opts[:length]} bytes." if arr.length > size  
      end
  
      arr.pack('V*')
    end

    # Returns an integer from the given arbitrary length little-endian binary string.
    # @param [String] str
    # @return [Fixnum]
    def self.to_int(str)
      arr, bits, num = str.unpack('V*'), 0, 0
      arr.each do |int|
        num += int << bits
        bits += 32
      end
      num >= 2**(bits-1) ? num - 2**bits : num  # Convert from unsigned to signed
    end
    
    # Returns an 8-byte binary string representing the given float in little-endian byte order.
    # @param [Float] val
    # @return [String]
    def self.from_float(val)
      Array(val).pack('E')
    end
    
    # Returns a Float from the given 8-byte binary string.
    # @param [String] str
    # @return [Float]
    # @raise BSONError
    def self.to_float(str)
      str.unpack('E').first
    end
  end
end