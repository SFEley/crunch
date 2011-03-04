module Crunch
  class Request
    
    # This class variable is shared with all subclasses
    @@request_id = 0
    
    # Returns an integer that increases monotonically across every subclass of Request.
    # MongoDB uses the request ID in responses, so it's important that no two IDs
    # within a connection are the same.
    # @return Integer
    def self.request_id
      @@request_id += 1
    end
    
    # Assigns an ID from the Request.request_id class method to this particular
    # object, or returns one that has already been assigned.
    # @return Integer
    def request_id
      @request_id ||= self.class.request_id
    end
    
    attr_reader :began
    
    # Sets the time that the request first went into the queue.
    # @return Time
    def begin
      @began = Time.now
    end
  end
end
