module Crunch
  
  # Passed to EventMachine to handle data received on the client connection.
  # @see http://eventmachine.rubyforge.org/EventMachine.html#M000473
  module Connection
    
    # Maps the request ID of outgoing messages to the sender of the message, so that
    # Mongo replies can go to the proper objects.
    def querist(request_id)
    end
  end
end
