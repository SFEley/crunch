module Crunch
  
  # Passed to EventMachine to handle data received on the client connection.
  # @see http://eventmachine.rubyforge.org/EventMachine.html#M000473
  module Connection
    attr_reader :database
    
    def initialize(database)
      @database = database
      super
    end
    
    # Start checking the request queue
    def post_init
      database.requests.pop self, :process_message
    end
    
    # The handler for a queue pop. Sends the message to the Mongo database, and if a
    # reply is expected, tracks it to make sure we don't close before receiving it. Then
    # pops again to get the next message.
    def process_message(message)
      send_data(message)
      database.requests.pop self, :process_message
    end
    
    # Receives replies to messages we've sent and forwards them on to the database when
    # complete. The database then routes it to the original sending object.
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
