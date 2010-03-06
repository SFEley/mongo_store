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
      # Unless option 1 is used, indexes are created on the key and expiration fields. If you supply your own collection,
      # you are also responsible for making your own indexes.
      def initialize(collection = nil, db_name = nil)
        @collection = case collection
        when Mongo::Collection then collection
        when String
          make_collection(collection, db_name)
        when nil
          make_collection('rails_cache')
        else
          raise TypeError, "MongoStore parameters must be nil, a Mongo::Collection, or a collection name."
        end
      end
      
      # Inserts the value into the cache collection or updates the existing value.  The value must be a valid
      # MongoDB type.  An *:expires_in* option may be provided, as with MemCacheStore.  If one is _not_ 
      # provided, a default expiration of 1 year is used.
      def write(key, value, options=nil)
        super
        expires = Time.now + ((options && options[:expires_in]) || 1.year)
        collection.update({'key' => key}, {'$set' => {'value' => value, 'expires' => expires}}, :upsert => true)
      end
      
      # Reads the value from the cache collection.
      def read(key, options=nil)
        super
        if doc = collection.find_one('key' => key, 'expires' => {'$gt' => Time.now})
          doc['value']
        end
      end
        
      # Takes the specified value out of the collection.
      def delete(key, options=nil)
        super
        collection.remove({'key' => key})
      end
      
      # With MongoDB, there's no difference between querying on an exact value or a regex.  Beautiful, huh?
      alias_method :delete_matched, :delete
      
      private
      def mongomapper?
        Kernel.const_defined?(:MongoMapper) && MongoMapper.respond_to?(:database) && MongoMapper.database
      end
      
      def make_collection(collection, db_name=nil)
         if db_name
           db = Mongo::DB.new(db_name, Mongo::Connection.new)
         elsif mongomapper?
           db = MongoMapper.database
         else
           db = Mongo::DB.new(collection, Mongo::Connection.new)
         end
        coll = db.create_collection(collection)
        coll.create_index('key' => Mongo::ASCENDING, 'expires' => Mongo::DESCENDING)
        coll
      end
        
    end
  end
end