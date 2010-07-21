module Crunch
  
  # Passed to EventMachine to handle data received on the client connection.
  # @see http://eventmachine.rubyforge.org/EventMachine.html#M000473
  module Connection
    def receive_data(data)
    end
  end
end
