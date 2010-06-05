require 'crunch/exceptions'
require 'eventmachine'

module Crunch
  # Hey, it's Ruby 1.9.  Autoload is safe again!  Spread the word!
  autoload :Database, 'crunch/database'
  autoload :Collection, 'crunch/collection'
  autoload :CommandCollection, 'crunch/collections/command_collection'
  autoload :Document, 'crunch/document'
  
  # The reason we're autoloading is because not all apps are likely to use all
  # message types or features.  And if you can defer loading until they ARE used
  # the first time, startup is that much faster.
  autoload :Message, 'crunch/message'
  autoload :QueryMessage, 'crunch/messages/query_message'
  autoload :InsertMessage, 'crunch/messages/insert_message'
  autoload :UpdateMessage, 'crunch/messages/update_message'
  
end
