$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'crunch'
require 'rspec/autorun'
require 'mocha'
require 'mongo'  # For verification only!

# Perform the requested action, but then don't come back until at least X EventMachine ticks have passed.
def tick(times=5)
  result = block_given? ? yield : true
  tick, timeout = 0, Time.now + 3
  times.times {EventMachine.next_tick {tick += 1}}
  while tick < times and Time.now < timeout do
    sleep 0.0001
  end
  raise "Tick timed out!" unless tick == times
  result
end
    
def verifier
  @verifier_db.collection('TestCollection')
end

Rspec.configure do |config|
  config.mock_with :mocha
  config.alias_it_should_behave_like_to :behaves_like, 'behaving like'
  
  config.before(:all) do
    @verifier_db = Mongo::Connection.new.db('crunch_test') # For verification while we bootstrap
    @verifier_collection = @verifier_db.create_collection 'TestCollection'
  end
  
  config.before(:each) do
    Crunch::Database.class_variable_get(:@@databases).clear  # Reinitialize each time
  end
    
  config.after(:each) do
    # Clean up our database
    @verifier_db.collections.each do |collection|
      case collection.name
      when 'TestCollection' then collection.remove  # Keep the collection, remove all data
      when /^system\./ then nil   # Leave system collections alone
      else 
        @verifier_db.drop_collection collection
      end
    end
  end

end
