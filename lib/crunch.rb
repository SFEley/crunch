require 'bson'
require 'eventmachine'
require 'crunch/exceptions'

module Crunch
  # Hey, it's Ruby 1.9.  Autoload is safe again!  Spread the word!
  autoload :Fieldset, 'crunch/fieldset'
  autoload :Database, 'crunch/database'
  autoload :Request, 'crunch/request'
  autoload :Connection, 'crunch/connection'
  
  
  # Utility methods
  
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
  # If not specified, will return 4 bytes or 8 bytes depending on the number's size.
  # @param [Fixnum] val
  # @option [Integer] length Set to 4 or 8 to determine string size.
  # @return [String]
  # @raise [CrunchError] Returns an exception on overflow or underflow.
  def self.int_to_bson(val, opts={})
    # Assume 4 bytes to start with
    max, min = 2147483647, -2147483648
    bytes = opts[:length] || ((val >= min && val <= max) ? 4 : 8)
    max, min = 9223372036854775807, -9223372036854775808 if bytes == 8
  
    raise CrunchError, "BSON conversion overflow: #{val} won't fit in #{bytes} bytes." if val > max
    raise CrunchError, "BSON conversion underflow: #{val} won't fit in #{bytes} bytes." if val < min
      
    i, s = val, ""
    s.force_encoding(Encoding::BINARY)
    bytes.times do 
      s << i % 256
      i = i >> 8
    end
    s
  end
  
  # Returns an integer from the given little-endian binary string (which must be either
  # 4 or 8 bytes in size).
  # @param [String] str
  # @return [Fixnum]
  def self.bson_to_int(str)
    raise CrunchError, "Invalid BSON conversion on '#{str}': must be 4 or 8 bytes in size." unless str.bytesize == 4 or str.bytesize == 8
    
    i, b = 0, 0
    i
  end

end
