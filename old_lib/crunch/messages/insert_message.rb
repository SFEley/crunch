module Crunch
  
  # Produces an instruction in the MongoDB Wire Protocol to push a new document into the
  # database.
  class InsertMessage < Message
    @opcode = 2002  # OP_INSERT
    
    attr_reader :collection, :fieldset
  
    # @param [Collection] collection
    # @param [Document] document 
    def initialize(collection, fieldset)
      @collection, @fieldset = collection, fieldset
    end
    
    
    # @see http://www.mongodb.org/display/DOCS/Mongo+Wire+Protocol
    def body     
      raise MessageError, "Trying to insert a fieldset without an _id field! #{@fieldset}" unless @fieldset['_id']
      "\x00\x00\x00\x00#{@collection.full_name}\x00#{@fieldset}"
    end
    
  end
end
