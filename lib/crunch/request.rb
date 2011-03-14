# encoding: BINARY

module Crunch
  class Request
    # A simple counter; wraps at 2**31-1
    @@counter = Fiber.new do
      counter = 0
      loop do
        Fiber.yield counter
        if counter > 2147483647
          counter = 0
        else
          counter += 1
        end
      end
    end
    
    @opcode = BSON.from_int(1000)     # OP_MSG
    
    
    # Assigns an ID from the Request.request_id class method to this particular
    # object, or returns one that has already been assigned.
    # @return String
    def request_id
      @request_id ||= @@counter.resume
    end
    
    # Returns the MongoDB operation ID for this request type.
    # @return Integer
    def self.opcode
      @opcode
    end
    
    attr_reader :began
    
    # Sets the time that the request first went into the queue.
    # @return Time
    def begin
      @began = Time.now
    end
    
    # The 16-byte header is always part of a MongoDB request.
    def header
      length = body.bytesize + 16
      [length, request_id, Crunch::ZERO, self.class.opcode].pack('VVa4a4')
    end
    
    # Abstract base method -- will be overwritten by specific request classes.
    # The default OP_MSG test request simply sends the message you give it to the DB.
    def body
      (@message || '').encode('BINARY') + "\x00"
    end
    
    # Returns the complete database message as a BSON string.
    def to_s
      "#{header}#{body}"
    end
    
    def initialize(options={})
      # Set any generic options passed; this flexibility keeps us from having to override
      # the initializer in subclasses.
      options.each {|k,v| instance_variable_set "@#{k}".to_sym, v}
    end
  end
end
