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
  #   Returns a BSON::ObjectId from a given string.
  #   @param [String] val An ObjectId in string form, e.g. '4c2b91d33f1651039f000002'
  #   @return [BSON::ObjectId]
  def self.oid(val=nil)
    if val.nil?
      BSON::ObjectId.new
    else
      BSON::ObjectId.from_string(val)
    end
  end

end
