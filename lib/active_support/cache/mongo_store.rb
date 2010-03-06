require 'active_support'
require 'mongo'

module ActiveSupport
  module Cache
    class MongoStore < Store
      attr_reader :collection
      
      # Returns a MongoDB cache store.  Can take either a Mongo::Collection object or a collection name.
      # If neither is provided, a collection named "rails_store" is created.
      #
      # An options hash may also be provided with the following options:
      # 
      # * :expires_in - The default expiration period for cached objects. If not provided, defaults to 1 year.
      # * :db - Either a Mongo::DB object or a database name. Not used if a Mongo::Collection object is passed. Otherwise defaults to MongoMapper.database (if MongoMapper is used in the app) or else creates a DB named 'rails_cache'.
      # * :create_index - Whether to index the key and expiration date on the collection. Defaults to true. Not used if a Mongo::Collection object is passed.
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