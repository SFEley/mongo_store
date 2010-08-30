require 'active_support'
require 'mongo'

module MongoStore
  module Cache
    module Rails2
      # Inserts the value into the cache collection or updates the existing value.  The value must be a valid
      # MongoDB type.  An *:expires_in* option may be provided, as with MemCacheStore.  If one is _not_ 
      # provided, a default expiration of 1 year is used.
      def write(key, value, options=nil)
        super
        expires = Time.now + ((options && options[:expires_in]) || expires_in)
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
    end
    module Rails3
      def write_entry(key, entry, options=nil)
        expires = Time.now + ((options && options[:expires_in]) || expires_in)
        value = entry.value
        value = value.to_mongo if value.respond_to? :to_mongo
        begin
          collection.update({'key' => key}, {'$set' => {'value' => value, 'expires' => expires}}, :upsert => true)
        rescue BSON::InvalidDocument
          value = value.to_s and retry unless value.is_a? String
        end
      end
      def read_entry(key, options=nil)
        doc = collection.find_one('key' => key, 'expires' => {'$gt' => Time.now})
        Entry.new(doc['value']) if doc
      end
      def delete_entry(key, options=nil)
        collection.remove({'key' => key})
      end
    end
    module Store
      rails3 = defined?(::Rails) && ::Rails.version =~ /^3\./
      include rails3 ? Rails3 : Rails2
    end
  end
end

module ActiveSupport
  module Cache
    class MongoStore < Store
      include ::MongoStore::Cache::Store
      attr_accessor :expires_in
      
      # Returns a MongoDB cache store.  Can take either a Mongo::Collection object or a collection name.
      # If neither is provided, a collection named "rails_cache" is created.
      #
      # An options hash may also be provided with the following options:
      # 
      # * :expires_in - The default expiration period for cached objects. If not provided, defaults to 1 year.
      # * :db - Either a Mongo::DB object or a database name. Not used if a Mongo::Collection object is passed. Otherwise defaults to MongoMapper.database (if MongoMapper is used in the app) or else creates a DB named "rails_cache".
      # * :create_index - Whether to index the key and expiration date on the collection. Defaults to true. Not used if a Mongo::Collection object is passed.
      def initialize(collection = nil, options = nil)
        @options = {
          :collection_name => 'rails_cache',
          :db_name => 'rails_cache',
          :expires_in => 1.year,
          :create_index => true
        }
        # @options.merge!(options) if options
        case collection
        when Mongo::Collection
          @collection = collection
        when String
          @options[:collection_name] = collection
        when Hash
          @options.merge!(collection)
        when nil
          # No op
        else
          raise TypeError, "MongoStore parameters must be a Mongo::Collection, a collection name, and/or an options hash."
        end
        
        @options.merge!(options) if options.is_a?(Hash)
        
        # Set the expiration time
        self.expires_in = @options[:expires_in]
      end
      
      # Returns the MongoDB collection described in the options to .new (or else the default 'rails_cache' one.)
      # Lazily creates the object on first access so that we can look for a MongoMapper database _after_ 
      # MongoMapper initializes.
      def collection
        @collection ||= make_collection
      end
            
      # Removes old cached values that have expired.  Set this up to run occasionally in delayed_job, etc., if you
      # start worrying about space.  (In practice, because we favor updating over inserting, space is only wasted
      # if the key itself never gets cached again.  It also means you can _reduce_ efficiency by running this
      # too often.)
      def clean_expired
        collection.remove({'expires' => {'$lt' => Time.now}})
      end
      
      # Wipes the whole cache.
      def clear
        collection.remove
      end

      # With MongoDB, there's no difference between querying on an exact value or a regex.  Beautiful, huh?
      alias_method :delete_matched, :delete
      
      private
      def mongomapper?
        Kernel.const_defined?(:MongoMapper) && MongoMapper.respond_to?(:database) && MongoMapper.database
      end
      
      def make_collection
        db = case options[:db]
        when Mongo::DB then options[:db]
        when String then Mongo::DB.new(options[:db], Mongo::Connection.new)
        else
          if mongomapper?
            MongoMapper.database
          else
            Mongo::DB.new(options[:db_name], Mongo::Connection.new)
          end
        end
        coll = db.create_collection(options[:collection_name])
        coll.create_index([['key',Mongo::ASCENDING], ['expires',Mongo::DESCENDING]]) if options[:create_index]
        coll
      end
        
    end
  end
end