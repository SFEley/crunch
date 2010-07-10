module Crunch
  
  # Represents a single document object in MongoDB. Essentially a hash that knows how to serialize itself
  # into BSON and send updates about itself to the database.
  class Document < Fieldset
    attr_reader :database, :collection
    
    # The fully qualified "database.collection" name.  (We query the Collection for it.)
    def collection_name
      @collection.full_name
    end
    
    private_class_method :new
    
    private

    # Initializes a document with its values. _Never_ called by application code; it's always initialized by a {Crunch::Group},
    # either implicitly by accessing the Group's collection or by calling {Group.document}.
    def initialize(collection, options={})
      @collection = collection
      @database = @collection.database
    end
  end
end