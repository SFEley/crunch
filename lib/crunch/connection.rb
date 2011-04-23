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
    
  end
end
