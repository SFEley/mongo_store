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
        
    after(:all) do
      c = Mongo::Connection.new
      %w(bar mappy rails_cache yuna).each do |db|
        c.drop_database(db)
      end
    end  
  end
  
  describe "caching" do
    before(:all) do
      @store = ActiveSupport::Cache.lookup_store(:mongo_store, 'mongo_store_test')
    end
    
    it "can write values" do
      @store.write('fnord', 'I am vaguely disturbed.')
      @store.collection.find_one(:key => 'fnord')['value'].should == "I am vaguely disturbed."
    end
    
    it "can read values" do
      @store.collection.insert({:key => 'yoo', :value => 'yar', :expires => 1.year.from_now})
      @store.read('yoo').should == 'yar'
    end
    
    it "can delete keys" do
      @store.write('foo', 'bar')
      @store.read('foo').should == 'bar'
      @store.delete('foo')
      @store.read('foo').should be_nil
    end
    
    it "can delete keys matching a regular expression" do
      @store.write('foo', 'bar')
      @store.write('fodder', 'bother')
      @store.write('yoo', 'yar')
      # Initial state
      @store.read('foo').should == 'bar'
      @store.read('fodder').should == 'bother'
      @store.read('yoo').should == 'yar'
      # The work
      @store.delete_matched /oo/
      # Post state
      @store.read('foo').should be_nil
      @store.read('fodder').should == 'bother'
      @store.read('yoo').should be_nil
    end
    
    it "can expire a value with the :expires_in option" do
      @store.write('ray', 'dar', :expires_in => 2.seconds)
      @store.read('ray').should == 'dar'
      sleep(3)
      @store.read('ray').should be_nil
    end
    
    after(:each) do
      @store.collection.remove   # Clear our records
    end
    after(:all) do
      c = Mongo::Connection.new
      c.drop_database('mongo_store_test')
    end
  end
end
