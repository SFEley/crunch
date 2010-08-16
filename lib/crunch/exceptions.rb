module Crunch
  class CrunchError < StandardError; end
  
    class DatabaseError < CrunchError; end
  
    class MessageError < CrunchError; end
  
    class DocumentError < CrunchError; end
  
    class FieldsetError < CrunchError; end

    class RecordsetError < CrunchError; end
  
    class ResponseError < CrunchError; end
  
      class HeaderError < ResponseError; end
      
      class QueryError < ResponseError; end
      
      class TimeoutError < ResponseError; end
    
    class FetchError < CrunchError; end
      
end