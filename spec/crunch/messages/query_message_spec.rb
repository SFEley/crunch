require_relative '../../spec_helper'
require_relative '../../shared_examples/message'

module Crunch
  describe QueryMessage do
    before(:each) do
      @this = QueryMessage.new
    end
    it_should_behave_like "a Message"
  end
end