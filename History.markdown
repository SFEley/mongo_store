0.3.0 / 2010-08-30 
==================
  * We have a History file now
  * Converted license to Don't Be a Dick License v0.2
  * Updated README
  * Removed 'key' field; using '_id' instead (thanks wpiekutowski)
  * Added namespace support to Rails 2 methods
  * Finished Rails 3 fixes, added more specs
  * Replace Entry with explicit ActiveSupport::Cache::Entry (thanks openhood)
  * Updating for Rails2/Rails3 compatibility (thanks openhood)
  * Fix working with Rails 3
  * Updating specs for RSpec 2

0.2.1 / 2010-04-13
==================
* Updated for Mongo gem 0.20.1 compatibility

0.2.0 / 2010-03-06
==================
* Provided a proper README.
* Rewrote initialization and made options more flexible. Added #clean_expired 
* Moved specs around
* Fixed error on 'nil' options being passed from Rails
* Fixing load paths for Rails
* Fixing path loading for Rails
* Embedding proper path

0.1.0 / 2010-03-06
==================
* All necessary methods implemented now
* Basic cache operations complete
* Collections work
* Docs started and dependencies
* Initial commit to mongo_store.
