module Crunch
  module Connection
    attr_reader :database, :status, :requests_processed, :last_request
    
    
    # Attaches itself to the database.
    def initialize(database)
      @database = database
      @status = :initializing
      @requests_processed = 0
      super
    end
    
    def post_init
      super
      @status = :active
      database.requests.pop self, :handle_request
    end
    
    def handle_request(request)
      @last_request = request
      if request.is_a?(ShutdownRequest)
        close_connection_after_writing
      else
        send_data(request)
        database.requests.pop self, :handle_request
      end
      @requests_processed += 1
    end
    
    def unbind
      @status = :terminated
    end
    
    def receive_data(bytes)
      # Algorithm shamelessly lifted from EventMachine's ObjectProtocol code.
      (@buffer ||= ''.encode(Encoding::BINARY)) << bytes
      @size ||= @buffer.unpack('V')[0]  # This is nil if we don't have 4 bytes yet
      
      while @size && @buffer.bytesize >= @size
        # We have a complete message!  Send it and take it off the front of the buffer.
        @last_request.sender.accept_response(@buffer.slice!(0..@size-1))
        @size = @buffer.unpack('V')[0]  # Rinse, repeat.
      end
    end
    
  end
end
