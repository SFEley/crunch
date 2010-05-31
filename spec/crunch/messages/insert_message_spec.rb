require_relative '../../spec_helper'
require_relative '../../shared_examples/message'

module Crunch
  describe InsertMessage do
    
    before(:each) do
      @collection = stub full_name: 'TestDB.TestCollection'
      @class = InsertMessage
      @this = InsertMessage.new(@collection)
    end
    
    it_should_behave_like "a Message"
    
  end    
end