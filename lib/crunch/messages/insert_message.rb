module Crunch
  
  # Produces an instruction in the MongoDB Wire Protocol to push a new document into the
  # database.  It's assumed that the document has already been serialized to MongoDB
  # compatible values and has an _id field. If a document isn't supplied on
  # initialization or with the #document attribute, a MessageError will be
  # raised.
  class InsertMessage < Message
    @opcode = 2002  # OP_INSERT
    
    attr_reader :collection_name
    attr_accessor :document
  
    # @param [Collection] collection What we're querying against
    # @param [optional, Hash] document The fields to be inserted
    def initialize(collection, document={})
      @collection_name, @document = collection.full_name, document
    end
    
      
    
    # @see http://www.mongodb.org/display/DOCS/Mongo+Wire+Protocol
    def body     
      raise MessageError, "Trying to insert a document without an _id field! #{@document}" unless @document['_id'] || @document[:_id]
      document_bson = BSON.serialize @document
      "\x00\x00\x00\x00#{collection_name}\x00#{document_bson}"
    end
    
  #   
  #   private
  #   # Produces the hash of {field => 1} values required by the wire protocol
  #   def field_bson
  #     return nil if @fields.nil? || @fields.empty?
  #     hash = {'_id' => 1}
  #     @fields.each {|field| hash[field] = 1}
  #     BSON.serialize hash
  #   end
  end
end
