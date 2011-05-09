#encoding: UTF-8
module Crunch
  
  # Crunch::Collections map directly to named MongoDB collections, and one is
  # required for every Document and Query. Like the Database object, the
  # Collection object is a singleton -- calling Collection.new will raise
  # an exception, and there is only one instance of a Collection object
  # for any given name. Request it using Database#collection.
  class Collection
    
    attr_reader :database, :name
    
    # Singleton pattern -- make .new private and return an exception if
    # called from outside
    class << self
      alias_method :new_from_database, :new
      
      def new(*args)
        raise CollectionError, "Crunch::Collection is a singleton. Call " +
          "Database.collection instead of Collection.new."
      end
    end
    
    def initialize(database, name)
      @database = database
      @name = name
    end
    
    def inspect
      "«#{name}»"
    end
    
  end
end