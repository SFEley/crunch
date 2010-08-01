module Crunch
  
  # Passed to EventMachine to handle data received on the client connection.
  # @see http://eventmachine.rubyforge.org/EventMachine.html#M000473
  module Connection
    def initialize(database)
      @database = database
      super
    end
    
    def receive_data(data)
      # Algorithm shamelessly lifted from EventMachine's ObjectProtocol code.
      (@buffer ||= ''.encode(Encoding::BINARY)) << data
      @size ||= @buffer.unpack('V')[0]  # This is nil if we don't have 4 bytes yet
      
      while @size && @buffer.bytesize >= @size
        # We have a complete message!  Send it and take it off the front of the buffer.
        @database.receive_reply(@buffer.slice!(0..@size-1))
        @size = @buffer.unpack('V')[0]  # Rinse, repeat.
      end
    end
    
  end
  
end
