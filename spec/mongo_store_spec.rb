require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# Stubbing MongoMapper out so that we don't have to have it installed for testing
class MongoMapper
end
    
describe "MongoStore" do
  describe "database" do
    it "can be specified as an option" do
      db = Mongo::DB.new("tsetse", Mongo::Connection.new('example.org', 11111, :connect => false))
      store = ActiveSupport::Cache.lookup_store(:mongo_store, db)
      store.database.should == db
    end
    
    it "will find MongoMapper's if it exists" do
      db = Mongo::DB.new("foobar", Mongo::Connection.new('example.org', 11111, :connect => false))
      MongoMapper.expects(:database).returns(db)
      store = ActiveSupport::Cache.lookup_store(:mongo_store)
      store.database.should == db
    end
    
    it "will create a sensible default if nothing else is provided" do
      store = ActiveSupport::Cache.lookup_store(:mongo_store)
      store.database.should be_a(Mongo::DB)
    end
    
    it "uses 'rails_cache' as the default database name" do
      store = ActiveSupport::Cache.lookup_store(:mongo_store)
      store.database.name.should == 'rails_cache'
    end
      
      
  end
end
