require 'bson'

module Crunch
  
  # The packed binary stuff that goes to MongoDB and comes back. Subclasses implement the specific 
  # header codes and such.
  class Message < BSON::ByteBuffer
    @opcode = 1000  # OP_MSG
    
    @@request_id_generator ||= Fiber.new do
      i = 0
      loop {Fiber.yield i += 1}
    end

    # Generates a new request ID. Monotonically increases across all classes.
    def self.request_id
      @@request_id_generator.resume
    end
    
    def self.opcode
      @opcode
    end
    
    attr_reader :response_id
    
    def initialize
      @response_id = 0
    end
    
    # The content of the message. Will be overridden in every subclass with more interesting behavior.
    def body
      "To sit in sullen silence...\x00".force_encoding(Encoding::BINARY)
    end
    
    # Puts everything together.
    def deliver
      header = [(body.length + 16), 
        self.class.request_id,
        0,
        self.class.opcode].pack('VVVV')
      "#{header}#{body}"
    end
    
  end
end