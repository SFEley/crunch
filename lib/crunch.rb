require 'eventmachine'
require 'crunch/exceptions'
require 'crunch/bson'

module Crunch
  # Hey, it's Ruby 1.9.  Autoload is safe again!  Spread the word!
  autoload :Fieldset, 'crunch/fieldset'
  autoload :Database, 'crunch/database'
  autoload :Request, 'crunch/request'
  autoload :Connection, 'crunch/connection'

  # A simple binary string counter.
  Counter = Fiber.new do
    counter = "\x00\x00\x00\x00"
    counter.force_encoding('BINARY')
    loop do
      Fiber.yield counter
      if counter.getbyte(3) == 255
        if counter.getbyte(2) == 255
          if counter.getbyte(1) == 255
              counter.setbyte(0, counter.getbyte(0) + 1)
          end
          counter.setbyte(1, counter.getbyte(1) + 1)
        end
        counter.setbyte(2, counter.getbyte(2) + 1)
      end
      counter.setbyte(3, counter.getbyte(3) + 1)
    end
  end
  
  
  # @overload oid
  #   Returns a new BSON::ObjectId from the current process ID and timestamp.
  #   @return [BSON::ObjectId]
  #
  # @overload oid(val)
  #   Returns a BSON::ObjectId from a given hex string.
  #   @param [String] val An ObjectId in string form, e.g. '4c2b91d33f1651039f000002'
  #   @return [BSON::ObjectId]
  def self.oid(val=nil)
    BSON::ObjectID.new(val)
  end
  
  # Let's make a zero constant since it gets looked up so damn much.
  ZERO = BSON.from_int(0)
  
end
