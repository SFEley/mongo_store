require 'active_support'
require 'mongo'

module ActiveSupport
  module Cache
    class MongoStore < Store
      attr_reader :database
      
      # Can take one or two parameters:
      # 1. The database to use, in the form of a Mongo::DB object.  If nil, defaults to MongoMapper.database if MongoMapper is used in the app, or else a new Mongo::DB object to a database named 'rails_cache'.
      # 2. The name of the collection to use.  Defaults to 'rails_cache', and will be created if it doesn't already exist.
      def initialize(db = nil)
        @database = db || 
          (Kernel.const_defined?(:MongoMapper) && MongoMapper.respond_to?(:database) && MongoMapper.database) ||
          Mongo::DB.new("rails_cache", Mongo::Connection.new)
      end
    end
  end
end