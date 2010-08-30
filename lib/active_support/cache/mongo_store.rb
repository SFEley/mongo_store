require 'active_support'
require 'mongo'

module MongoStore
  module Cache
    module Rails2
      attr_reader :options
      
      # Inserts the value into the cache collection or updates the existing value.  The value must be a valid
      # MongoDB type.  An *:expires_in* option may be provided, as with MemCacheStore.  If one is _not_ 
      # provided, a default expiration of 1 day is used.
      def write(key, value, local_options=nil)
        super
        opts = local_options ? options.merge(local_options) : options
        expires = Time.now + opts[:expires_in]
        collection.update({'key' => namespaced_key(key, opts)}, {'$set' => {'value' => value, 'expires' => expires}}, :upsert => true)
      end
      
      # Reads the value from the cache collection.
      def read(key, local_options=nil)
        super
        opts = local_options ? options.merge(local_options) : options
        if doc = collection.find_one('key' => namespaced_key(key, opts), 'expires' => {'$gt' => Time.now})
          doc['value']
        end
      end
        
      # Takes the specified value out of the collection.
      def delete(key, local_options=nil)
        super
        opts = local_options ? options.merge(local_options) : options
        collection.remove({'key' => namespaced_key(key,opts)})
      end
      

      # Takes the value matching the pattern out of the collection.
      def delete_matched(key, local_options=nil)
        super
        opts = local_options ? options.merge(local_options) : options
        collection.remove({'key' => key_matcher(key,opts)})
      end

            
      protected

      # Lifted from Rails 3 ActiveSupport::Cache::Store
      def namespaced_key(key, options)
        namespace = options[:namespace] if options
        prefix = namespace.is_a?(Proc) ? namespace.call : namespace
        key = "#{prefix}:#{key}" if prefix
        key
      end
      
      # Lifted from Rails 3 ActiveSupport::Cache::Store
      def key_matcher(pattern, options)
        prefix = options[:namespace].is_a?(Proc) ? options[:namespace].call : options[:namespace]
        if prefix
          source = pattern.source
          if source.start_with?('^')
            source = source[1, source.length]
          else
            source = ".*#{source[0, source.length]}"
          end
          Regexp.new("^#{Regexp.escape(prefix)}:#{source}", pattern.options)
        else
          pattern
        end
      end
      
    end
    
    module Rails3
      def write_entry(key, entry, options)
        expires = Time.now + options[:expires_in]
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
        ActiveSupport::Cache::Entry.new(doc['value']) if doc
      end
      def delete_entry(key, options=nil)
        collection.remove({'key' => key})
      end
      def delete_matched(pattern, options=nil)
        options = merged_options(options)
        instrument(:delete_matched, pattern.inspect) do
          matcher = key_matcher(pattern, options)  # Handles namespacing with regexes
          delete_entry(matcher, options) 
        end
      end
    end
    
    module Store
      rails3 = defined?(::Rails) && ::Rails.version =~ /^3\./
      include rails3 ? Rails3 : Rails2
      
      def expires_in
        options[:expires_in]
      end
      
      def expires_in=(val)
        options[:expires_in] = val
      end
    end
  end
end

module ActiveSupport
  module Cache
    class MongoStore < Store
      include ::MongoStore::Cache::Store
      
      # Returns a MongoDB cache store.  Can take either a Mongo::Collection object or a collection name.
      # If neither is provided, a collection named "rails_cache" is created.
      #
      # An options hash may also be provided with the following options:
      # 
      # * :expires_in - The default expiration period for cached objects. If not provided, defaults to 1 day.
      # * :db - Either a Mongo::DB object or a database name. Not used if a Mongo::Collection object is passed. Otherwise defaults to MongoMapper.database (if MongoMapper is used in the app) or else creates a DB named "rails_cache".
      # * :create_index - Whether to index the key and expiration date on the collection. Defaults to true. Not used if a Mongo::Collection object is passed.
      def initialize(collection = nil, options = nil)
        @options = {
          :collection_name => 'rails_cache',
          :db_name => 'rails_cache',
          :expires_in => 86400,  # That's 1 day in seconds
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