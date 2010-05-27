module Crunch
  
  # A special case of Crunch::Collection that knows how to execute database commands.
  class CommandCollection < Collection
    
    def get_nonce
      query = QueryMessage.new(self, query: {getnonce: 1}, limit: 1)
    end
    
    private
    def initialize(database)
      super database, '$cmd'
    end
    
    
  end
end