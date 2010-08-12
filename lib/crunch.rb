require 'crunch/exceptions'
require 'eventmachine'

module Crunch
  # Hey, it's Ruby 1.9.  Autoload is safe again!  Spread the word!
  autoload :Connection, 'crunch/connection'
  autoload :Database, 'crunch/database'
  autoload :Fieldset, 'crunch/fieldset'
  autoload :Recordset, 'crunch/recordset'
  autoload :Document, 'crunch/document'
  autoload :Query, 'crunch/query'
  autoload :Collection, 'crunch/collection'
  autoload :CommandCollection, 'crunch/collections/command_collection'
  
  # The reason we're autoloading is because not all apps are likely to use all
  # message types or features.  And if you can defer loading until they ARE used
  # the first time, startup is that much faster.
  autoload :Message, 'crunch/message'
  autoload :QueryMessage, 'crunch/messages/query_message'
  autoload :InsertMessage, 'crunch/messages/insert_message'
  autoload :UpdateMessage, 'crunch/messages/update_message'

  autoload :Agent, 'crunch/agent'
  autoload :DocumentAgent, 'crunch/agents/document_agent'
  
  # Utility methods
  
  # @overload oid
  #   Returns a new BSON::ObjectID from the current process ID and timestamp.
  #   @return [BSON::ObjectID]
  #
  # @overload oid(val)
  #   Returns a BSON::ObjectID from a given string.
  #   @param [String] val An ObjectID in string form, e.g. '4c2b91d33f1651039f000002'
  #   @return [BSON::ObjectID]
  def self.oid(val=nil)
    if val.nil?
      BSON::ObjectID.new
    else
      BSON::ObjectID.from_string(val)
    end
  end

  
end
