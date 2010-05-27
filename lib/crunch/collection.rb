require 'revactor'

module Crunch
  
  # Represents a collection within a database.  Cannot be created directly; instead, use the
  # Database#collection method.
  class Collection < Actor
    attr_reader :database, :name, :full_name
    
    private_class_method :new
    
    private
    # Takes the database, the name, and any options.
    def initialize(database, name)
      @database, @name = database, name
      @full_name = "#{database.name}.#{name}"
    end
  end

end