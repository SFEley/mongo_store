# MongoStore

It's **ActiveSupport::Cache::MongoStore** -- a [MongoDB](http://mongodb.org)-based provider for the standard Rails 2 or Rails 3 cache mechanism.  With an emphasis on fast writes and a memory-mapped architecture, Mongo is well-suited to caching. This gem aims to give you what the ubiquitous **MemCacheStore** does, but with Mongo's persistence.  (And without having to put a second RAM devourer in an environment already running Mongo.)


## Getting Started

The only prerequisites are [ActiveSupport](http://rubygems.org/gems/activesupport) and the [mongo](http://rubygems.org/gems/mongo) gem.  If your app uses [MongoMapper](htp://rubygems.org/gems/mongo_mapper) we can detect it and use the same database connection, but we don't require it.

    $ gem install mongo_store   # or 'sudo' as required
    
In your Rails application, just configure your **config/environments/production.rb** (and/or **staging.rb** and any other environment you want to cache) like so:

    config.cache_store = :mongo_store
    
This default behavior creates a collection called **rails\_cache** in either the Mongo database referenced by `MongoMapper.database` (if you're using MM) or a database also called **rails\_cache**.  You can override these:

    config.cache_store = :mongo_store, "foo"  # Collection name is "foo"
    config.cache_store = :mongo_store, "foo", :db => "bar"  # DB name is "bar"
    
    # You can pass a DB object instead of a database name...
    deebee = Mongo::DB.new("bar", Mongo::Connection.new)
    config.cache_store = :mongo_store, "foo", :db => deebee
    
    # Or just pass in a Collection object and you're covered...
    collie = Mongo::Collection.new(deebee, "foo")
    config.cache_store = :mongo_store, collie
    
We don't have a separate option for connecting to a different server.  If you don't intend to use localhost, make a new Mongo::Collection or Mongo::DB object from a different connection.
    
## Options

The following hash options are recognized on initialization:

* `:db` - A Mongo::DB object or the name of one to create. Defaults to **rails_cache**.
* `:create_index` - By default, we create an index on the *_id* and *expires* fields for fast returns on cache misses. Set to **false** to override.
* `:expires_in` - The global length of time a cache key remains valid. Defaults to 1 year. Can also be set on individual cache writes.
* `:namespace` - Set this if you want different applications to share the same Mongo collection without key collisions. (Namespacing is baked into Rails 3, but MongoStore implements it manually for Rails 2 as well.)

## Other Goodness

MongoStore is a drop-in caching store and doesn't require any special treatment. The only extra behavior on top of what you get from ActiveSupport::Cache::Store is as follows:

### :expires_in option on the #write method
This was built into all stores in Rails 3. In Rails 2, we implement it with same behavior as the option in MemCacheStore. Specify a number of seconds or an ActiveSupport helper equivalent, e.g.: `:expires_in => 5.minutes`.  Keys past their expiration date are not returned on reads.

_**NOTE:** This behavior is fairly dumb and uses `Time.now` on the application side.  If you have a number of app servers hitting one database and their times aren't in sync, expect unwarranted cache misses._

### #clean_expired method
If the collection size starts to explode from old cached values that are never being written again, you can set up a delayed job or Rake task to run `Rails.cache.clean_expired` every few weeks or such.  Cached values that _are_ reused are updated in place, so running this too frequently may actually impair performance.

### #clear method
Empties the cache. The moral equivalent of `Rails.cache.delete_matched(/.*/)` but faster.

## Limitations

* Keys and values must be valid Mongo types. In practice, caching seems mostly to be used on strings, so this probably doesn't hurt you. Just be aware that no attempt is made to serialize complex Ruby objects. That's what ORMs are for. (See my [Candy](http://rubygems.org/gems/candy) gem for some work I've been doing in this direction, however.)

* Upserts and atomic operators are used for performance and simplicity. Writing to an existing key will change the value and expiration date. This is fast, but expired keys that are never written again _will_ keep hanging around until you delete them explicitly or run `#clean_expired`. This may or may not matter depending on how numerous and reusable your keys are. For typical Rails app use cases, you're probably fine. If you really care about every byte of disk space, you probably ought to reconsider using MongoDB anyway.

* Mongo documents have a size limit of 4 MB. No attempt is made to work around this. If you're trying to trying to stuff anything larger than that into Rails caching, you're on your own.

* Do not use a capped collection. Doing so will prevent deletes from deleting, some updates from updating, and the trees and flowers from growing in the Spring.

* This code and specs were written for Ruby 1.9.1.  I tried to make sure it works fine for you anachronists (Ruby 1.8), but didn't confirm it. Please register an issue if I forgot your quaint historical syntax. I also didn't test it in JRuby, Rubinius, IronRuby, or your roommate's HP-48 calculator. 

* I am optimistic about performance but have not benchmarked it, apart from  "It's faster than not using a cache."

## Support

You can find the docs here: 
http://rdoc.info/projects/SFEley/mongo_store/

Other than that, there is no email list, forum, wiki, Google Wave, or international convention for this gem. Come on. It's a hundred lines of code.

## Contributing

Please leave an issue. Or fork, fix, and pull-request. Or send me an email (sfeley@gmail.com). Or buy me a whisky at the hotel bar. (Single malt only, please.)

You can also [check out my podcast](http://escapepod.org) if you like science fiction stories.

And Have Fun.

## License

This project is licensed under the [Don't Be a Dick License](http://dbad-license.org), version 0.2, and is copyright
2010 by Stephen Eley. See the [LICENSE.markdown](http://github.com/SFEley/mongo_store/blob/master/LICENSE.markdown)
file for elaboration on not being a dick. (But you probably already know.)

