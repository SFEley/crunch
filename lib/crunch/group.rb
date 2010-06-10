module Crunch
  
  # Abstracts a MongoDB collection or query result set.  The driving goals are:
  # 1. Be as array-like as possible (including indexed access of elements);
  # 2. Offer both synchronous and asynchronous operation;
  # 3. Eliminate any need to worry about Mongo cursor maintenance.
  class Group
    attr_reader :database, :collection_name, :full_collection_name
    
    # Always requires a collection name. Everything else is an option.  Data
    # loading is asynchronous and semi-eager: the first record retrieval happens 
    # on initialization, but if more than one cursor fetch is required, 
    # subsequent "GET_MORE" fetches will be performed the first time a document
    # from the prior batch is accessed.
    #
    # @param [Database] database Maintains all communication with MongoDB. 
    # @param [String] collection_name The Mongo collection we're querying against.
    def initialize(database, collection_name)
      @database, @collection_name = database, collection_name
      @full_collection_name = "#{@database.name}.#{@collection_name}"
    end
    
  end
  
end