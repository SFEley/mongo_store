require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# Stubbing MongoMapper out so that we don't have to have it installed for testing
class MongoMapper
end
    
describe "MongoStore" do
  describe "collection" do
    it "can be specified as a Mongo::Collection object" do
      db = Mongo::DB.new('mongo_store_test', Mongo::Connection.new)
      coll = Mongo::Collection.new(db, 'foostore')
      store = ActiveSupport::Cache.lookup_store(:mongo_store, coll)
      store.collection.should == coll
    end
    
    it "can take a collection name and a database name" do
      store = ActiveSupport::Cache.lookup_store(:mongo_store, 'foo', 'bar')
      store.collection.name.should == 'foo'
      store.collection.db.name.should == 'bar'
    end
    
    describe "with MongoMapper" do
      before(:each) do
        db = Mongo::DB.new('mappy', Mongo::Connection.new)
        MongoMapper.expects(:database).twice.returns(db)
      end
      
      it "can take a collection name" do
        store = ActiveSupport::Cache.lookup_store(:mongo_store, 'happy')
        store.collection.name.should == 'happy'
        store.collection.db.name.should == 'mappy'
      end
        
      it "defaults to a 'rails_cache' collection" do
        store = ActiveSupport::Cache.lookup_store(:mongo_store)
        store.collection.name.should == 'rails_cache'
        store.collection.db.name.should == 'mappy'
      end
    end
    
    describe "without MongoMapper" do
      it "can take a collection name" do
        store = ActiveSupport::Cache.lookup_store(:mongo_store, 'yuna')
        store.collection.name.should == 'yuna'
        store.collection.db.name.should == 'yuna'
      end
        
      it "defaults to a 'rails_cache' collection" do
        store = ActiveSupport::Cache.lookup_store(:mongo_store)
        store.collection.name.should == 'rails_cache'
        store.collection.db.name.should == 'rails_cache'
      end
    end
    
    it "raises an exception if an unusable parameter is passed" do
      lambda{ActiveSupport::Cache.lookup_store(:mongo_store, 5)}.should raise_error(TypeError)
    end
    
    it "creates a capped collection of 100 MB" do
      store = ActiveSupport::Cache.lookup_store(:mongo_store)
      store.collection.options['capped'].should be_true
      store.collection.options['size'].should == 104_857_600
    end
    
    after(:all) do
      c = Mongo::Connection.new
      %w(bar mappy rails_cache yuna).each do |db|
        c.drop_database(db)
      end
    end  
  end
end
