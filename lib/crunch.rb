require 'bindata'
require 'eventmachine'
require 'crunch/exceptions'

module Crunch
  # Hey, it's Ruby 1.9.  Autoload is safe again!  Spread the word!
  autoload :Fieldset, 'crunch/fieldset'
  autoload :Database, 'crunch/database'
  autoload :Request, 'crunch/request'
  autoload :Connection, 'crunch/connection'
  
    
  # @overload oid
  #   Returns a new BSON::ObjectId from the current process ID and timestamp.
  #   @return [BSON::ObjectId]
  #
  # @overload oid(val)
  #   Returns a BSON::ObjectId from a given hex string.
  #   @param [String] val An ObjectId in string form, e.g. '4c2b91d33f1651039f000002'
  #   @return [BSON::ObjectId]
  def self.oid(val=nil)
    if val.nil?
      BSON::ObjectId.new
    else
      BSON::ObjectId.from_string(val)
    end
  end
  
  # Returns a binary string representing the given integer in little-endian byte order.
  # Use the `:length` option to specify 4 byte (32-bit) or 8 byte (64-bit) string size.
  # If not specified, will return an arbitrary length string depending on the number's size.
  # @param [Fixnum] val
  # @option [Integer] length Set to 4 or 8 to determine string size.
  # @return [String]
  # @raise [CrunchError] Returns an exception on overflow or underflow.
  def self.int_to_bson(val, opts={})
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
      raise CrunchError, "BSON conversion overflow: #{val} will not fit into #{opts[:length]} bytes." if arr.length > size  
    end
    
    arr.pack('V*')
  end
  
  # Returns an integer from the given arbitrary length little-endian binary string.
  # @param [String] str
  # @return [Fixnum]
  def self.bson_to_int(str)
    arr, bits, num = str.unpack('V*'), 0, 0
    arr.each do |int|
      num += int << bits
      bits += 32
    end
    num >= 2**(bits-1) ? num - 2**bits : num  # Convert from unsigned to signed
  end
  
  # Let's make a zero constant since it gets looked up so damn much.
  ZERO = self.int_to_bson(0)
  
end
