require File.dirname(__FILE__) + '/../spec_helper'

module Crunch
  describe Request do
    before(:each) do
      @this = Request.new
    end
    behaves_like "a Request"
  end
end