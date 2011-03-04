module Crunch
  module Connection
    attr_reader :database, :status
    
    # Attaches itself to the database.
    def initialize(database)
      @database = database
      @status = :initializing
      super
    end
    
    def post_init
      @status = :active
    end
  end
end
