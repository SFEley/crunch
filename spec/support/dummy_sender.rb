# A stub for connection testing, to act as the 'sender' parameter for.  
# test requests. Its only real functionality is to accept responses
# from connections and present them when asked.

class DummySender
  attr_reader :header, :response
  
  def accept_response(response)
    @header = response.slice!(0..15)
    @response = response
  end
    
end