$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'mongo'
require 'mongo_store'
require 'rspec'
require 'rspec/autorun'
require 'mocha'

# Fake out Rails 3 -- for Rails 2 testing, run with a gemset with activesupport ~ 2.3
module Rails
  def self.version
    ActiveSupport::Cache.const_defined?(:Entry) ? '3.0.0' : '2.3.8'
  end
end


RSpec.configure do |config|
  config.mock_with :mocha
end
