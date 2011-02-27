module Crunch
  class Request
    attr_reader :began
    
    # Sets the time that the request first went into the queue.
    # @return Time
    def begin
      @began = Time.now
    end
  end
end
