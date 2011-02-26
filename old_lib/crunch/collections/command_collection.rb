module Crunch
  
  # A special case of Crunch::Collection that knows how to execute database commands.
  class CommandCollection < Collection
    
    def getnonce
      query = QueryMessage.new(self, query: {getnonce: 1}, limit: 1)
      Fiber.new{|m| database << m}.resume
      database << query
    end
    
    private
    def initialize(database)
      super database, '$cmd'
    end
    
    
  end
end