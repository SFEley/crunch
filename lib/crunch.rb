require 'eventmachine'
require 'crunch/exceptions'
require 'crunch/bson'

module Crunch
  # Hey, it's Ruby 1.9.  Autoload is safe again!  Spread the word!
  autoload :Fieldset, 'crunch/fieldset'
  autoload :Database, 'crunch/database'
  autoload :Connection, 'crunch/connection'

  # Requests
  autoload :Request, 'crunch/request'
  autoload :ShutdownRequest, 'crunch/requests/shutdown_request'
  
  
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
