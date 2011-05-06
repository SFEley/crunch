# encoding: BINARY

module Crunch
  class Request
    @@counter = 0
    
    @opcode = BSON.from_int(1000)     # OP_MSG
    
    
    # Assigns an ID from the Request.request_id class method to this particular
    # object, or returns one that has already been assigned. The ID is global
    # and increases across all request classes, wrapping at the 32-bit boundary.
    # @return String
    def request_id
      @request_id ||= begin
        if @@counter > 2147483647
          @@counter = 0
        else
          @@counter += 1
        end
      end
    end
    
    # Returns the MongoDB operation ID for this request type.
    # @return Integer
    def self.opcode
      @opcode
    end
    
    attr_reader :began, :sender
    
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
    
    
    # @param [Object] sender The object initiating the request. Must implement
    #   the `#accept_response` method to get any data back from MongoDB 
    #   if a reply is expected.
    # @param [Hash] options Subclass-specific.
    def initialize(sender, options={})
      # Set any generic options passed; this flexibility keeps us from 
      # having to override the initializer in every subclasses.
      @sender = sender
      options.each {|k,v| instance_variable_set "@#{k}".to_sym, v}
    end
  end
end
