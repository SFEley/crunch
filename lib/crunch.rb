require 'crunch/exceptions'

module Crunch
  # Hey, it's Ruby 1.9.  Autoload is safe again!  Spread the word.
  autoload :Database, 'crunch/database'
  autoload :Message, 'crunch/message'
  autoload :QueryMessage, 'crunch/messages/query_message'
  
end
