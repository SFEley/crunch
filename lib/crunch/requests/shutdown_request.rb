# encoding: BINARY

require 'crunch'

module Crunch
  # A "pseudo-request" class used internally to tell Crunch::Connection objects 
  # to commit harakiri in an orderly fashion.  Unlike other Request subclasses,
  # ShutdownRequest instances are _not_ sent to the Mongo database.  They exist
  # to ensure that a connection does not die in mid-request, but rather the next
  # time it gets a request off the queue.
  class ShutdownRequest < Request
    @opcode = BSON.from_int(0)   # internal use only (Mongo opcodes are 1000+)
    
    # Seppuku!
    def body
      "SHUTDOWN"
    end
  end
end

  