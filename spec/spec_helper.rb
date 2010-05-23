$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'crunch'
require 'spec'
require 'spec/autorun'
require 'mocha'

Spec::Runner.configure do |config|
  config.mock_with :mocha
end
