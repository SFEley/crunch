require 'crunch/exceptions'
require 'eventmachine'
require 'bson'

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
  autoload :QueryAgent, 'crunch/agents/query_agent'
  
  # Global options
  @@options = {
    host: 'localhost',      # Default host for MongoDB server
    port: 27017,            # Default port for MongoDB server
    timeout: 10,            # Database requests will error out after this many seconds
    heartbeat: 1,           # Frequency (in seconds) to check for timeouts and maintain connection counts
    min_connections: 1,     # Create more connections if we ever drop below this value
    max_connections: 10     # Never create more than this many connections
  }
  
  # The global options hash. This is primarily defined as a convenience for other Crunch classes to inherit
  # the options on initialization. If you want to change any of these options yourself, use one of the
  # defined attribute methods.
  def self.options
    @@options
  end
  
  @@options.keys.each do |o|
    instance_eval <<-END_DEF
      def #{o}
        @@options[:#{o}]
      end
      
      def #{o}=(val)
        @@options[:#{o}] = val
      end
    END_DEF
  end
    
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
