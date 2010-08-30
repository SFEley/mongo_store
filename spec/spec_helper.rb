$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'mongo'
require 'mongo_store'
require 'rspec'
require 'rspec/autorun'
require 'mocha'

# Fake out Rails 3 -- comment out for Rails 2 testing and use a gemset with activesupport ~ 2.3
module Rails
  def self.version
    '3.0.0'
  end
end


RSpec.configure do |config|
  config.mock_with :mocha
end
