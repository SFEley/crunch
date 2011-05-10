# encoding: BINARY
require 'crunch'

module Crunch
  
  # @see http://www.mongodb.org/display/DOCS/Mongo+Wire+Protocol
  class InsertRequest < Request
    @opcode = BSON.from_int(2002)   # OP_INSERT
    
    def body
      Crunch::ZERO + 
      BSON.cstring(sender.collection_name) + 
      @documents.join('')
    end
    
    # @param [Object] sender The object initiating the request
    # @param [Fieldset] documents One or more Fieldset objects including _id
    def initialize(sender, *documents)
      super(sender)
      @documents = *documents
    end
      
  end
end