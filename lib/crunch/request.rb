# encoding: BINARY

module Crunch
  class Request
    # A simple binary string counter; returns a four-byte little-endian string.
    @@counter = Fiber.new do
      counter = "\x00\x00\x00\x00"
      counter.force_encoding('BINARY')
      loop do
        Fiber.yield counter
        if counter.getbyte(0) == 255
          if counter.getbyte(1) == 255
            if counter.getbyte(2) == 255
                counter.setbyte(3, counter.getbyte(3) + 1)
            end
            counter.setbyte(2, counter.getbyte(2) + 1)
          end
          counter.setbyte(1, counter.getbyte(1) + 1)
        end
        counter.setbyte(0, counter.getbyte(0) + 1)
      end
    end
    
    @opcode = BSON.from_int(1000)     # OP_MSG
    
    
    # Assigns an ID from the Request.request_id class method to this particular
    # object, or returns one that has already been assigned.
    # @return Integer
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
      length_bson = BSON.from_int(body.bytesize + 16)
      request_bson = BSON.from_int(self.request_id)
      "#{length_bson}#{request_bson}#{Crunch::ZERO}#{self.class.opcode}"
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
