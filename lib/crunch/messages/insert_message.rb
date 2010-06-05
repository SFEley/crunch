module Crunch
  
  # Produces an instruction in the MongoDB Wire Protocol to push a new document into the
  # database.
  class InsertMessage < Message
    @opcode = 2002  # OP_INSERT
    
    attr_reader :document
  
    # @param [Document] document The document to be inserted
    def initialize(document)
      @document = document
    end
    
    
    # @see http://www.mongodb.org/display/DOCS/Mongo+Wire+Protocol
    def body     
      raise MessageError, "Trying to insert a document without an _id field! #{@document}" unless @document['_id']
      "\x00\x00\x00\x00#{@document.collection_name}\x00#{@document}"
    end
    
  end
end
