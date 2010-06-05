module Crunch
  class CrunchError < StandardError; end
  
  class DatabaseError < CrunchError; end
  
  class MessageError < CrunchError; end
  
  class DocumentError < CrunchError; end
  
  class FieldsetError < CrunchError; end
end