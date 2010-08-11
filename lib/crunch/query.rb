module Crunch
  
  # Abstracts a MongoDB query result set with multiple documents.  The driving goals are:
  # 1. Be as array-like as possible (including indexed access of elements);
  # 2. Offer both synchronous and asynchronous operation;
  # 3. Eliminate any need to worry about Mongo cursor maintenance.
  class Query
    attr_reader :database, :collection, :full_collection_name, :options, :conditions
    
    
    
    protected
    
    # Initializes the result set. _Never_ called by application code; get to
    # it from the Collection object.  Data loading is asynchronous and
    # semi-eager: the first record retrieval happens on initialization, but if
    # more than one cursor fetch is required, subsequent "GET_MORE" fetches
    # will be performed the first time a document from the prior batch is
    # accessed.
    #
    # @param [Crunch::Collection] collection 
    def initialize(collection, options={})
      @collection, @options = collection, options
      @database, @full_collection_name = collection.database, collection.full_name
      @conditions = @options.delete(:conditions) || {}
    end
    
  end
  
end