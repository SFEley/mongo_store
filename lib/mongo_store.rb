require 'active_support'

module ActiveSupport
  module Cache
    autoload :MongoStore, 'active_support/cache/mongo_store'
  end
end
