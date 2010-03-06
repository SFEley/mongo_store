require 'active_support'
require 'mongo'

module ActiveSupport
  module Cache
    class MongoStore < Store
      attr_reader :collection
      
      # Returns a MongoDB cache store.  Takes several possible combinations of parameters.  In order of
      # escalating guesswork:
      #
      # 1. *a Mongo::Collection object* - No guessing. The collection is used as the cache store.
      # 2. *a collection name and a database name* - Mongo objects are created for both.  The default 'localhost:27017' connection is used.
      # 3. *a collection name* - Uses either MongoMapper.database (if MongoMapper is defined in the app) or a DB with the same name.
      # 4. *no parameters* - A collection named 'rails_cache' is created, using either MongoMapper.database (if MongoMapper is defined in the app) or a DB also named 'rails_cache'.
      #
      # Unless option 1 is used, the collection is a capped collection sized at 100 MB.  If you don't
      # like this, pass in your own Mongo::Collection.
      def initialize(collection = nil, db_name = nil)
        @collection = case collection
        when Mongo::Collection then collection
        when String
          if db_name
            db = Mongo::DB.new(db_name, Mongo::Connection.new)
          elsif mongomapper?
            db = MongoMapper.database
          else
            db = Mongo::DB.new(collection, Mongo::Connection.new)
          end
         db.create_collection(collection, :capped => true, :size => 104_857_600)
        when nil
          if mongomapper?
            db = MongoMapper.database
          else
            db = Mongo::DB.new('rails_cache', Mongo::Connection.new)
          end
          db.create_collection('rails_cache', :capped => true, :size => 104_857_600)
        else
          raise TypeError, "MongoStore parameters must be nil, a Mongo::Collection, or a collection name."
        end
      end
      
      private
      def mongomapper?
        Kernel.const_defined?(:MongoMapper) && MongoMapper.respond_to?(:database) && MongoMapper.database
      end
    end
  end
end