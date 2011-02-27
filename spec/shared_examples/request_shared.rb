module Crunch
  shared_examples_for "a Request" do
    it "can start the 'begin' timer" do
      @this.begin
      @this.began.should be_within(1).of(Time.now)
    end
  end
end