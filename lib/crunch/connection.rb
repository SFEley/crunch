module Crunch
  module Connection
    attr_reader :database
    
    # Attaches itself to the database.
    def initialize(database)
      @database = database
      super
    end
  end
end
