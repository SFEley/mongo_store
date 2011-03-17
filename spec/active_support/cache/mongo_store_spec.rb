require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

# Stubbing MongoMapper out so that we don't have to have it installed for testing
class MongoMapper
end

module ActiveSupport 
  module Cache
    describe MongoStore do
      describe "initializing" do
        it "can take a Mongo::Collection object" do
          db = Mongo::DB.new('mongo_store_test', Mongo::Connection.new)
          coll = Mongo::Collection.new('foostore', db)
          store = ActiveSupport::Cache.lookup_store(:mongo_store, coll)
          store.collection.should == coll
        end
        
        it "can take a collection name" do
          store = ActiveSupport::Cache.lookup_store(:mongo_store, 'foo')
          store.collection.name.should == 'foo'
        end
        
        it "defaults the collection name to 'rails_cache'" do
          store = ActiveSupport::Cache.lookup_store(:mongo_store)
          store.collection.name.should == 'rails_cache'
        end
        
        it "can take a Mongo::DB object for a :db option" do
          deebee = Mongo::DB.new('mongo_store_test_deebee', Mongo::Connection.new)
          store = ActiveSupport::Cache.lookup_store(:mongo_store, :db => deebee)
          store.collection.db.should == deebee
        end
        
        it "can take a database name for a :db option" do
          store = ActiveSupport::Cache.lookup_store(:mongo_store, :db => 'mongo_store_test_name')
          store.collection.db.name.should == 'mongo_store_test_name'
        end
        
        it "uses MongoMapper if no other DB is provided" do
          mappy = Mongo::DB.new('mongo_store_test_mappy', Mongo::Connection.new)
          MongoMapper.expects(:database).at_least_once.returns(mappy)
          store = ActiveSupport::Cache.lookup_store(:mongo_store)
          store.collection.db.should == mappy
        end
        
        it "lazy loads so that MongoMapper can be initialized first" do
          store = ActiveSupport::Cache.lookup_store(:mongo_store)
          # Notice the order! It's what differentiates this test from the above.
          lazy = Mongo::DB.new('mongo_store_test_lazy', Mongo::Connection.new)
          MongoMapper.expects(:database).at_least_once.returns(lazy)
          store.collection.db.should == lazy
        end
        
        it "defaults the database name to 'rails_cache'" do
          store = ActiveSupport::Cache.lookup_store(:mongo_store)
          store.collection.db.name.should == 'rails_cache'
        end
        
        it "defaults to creating an index" do
          Mongo::Collection.any_instance.expects(:create_index)
          store = ActiveSupport::Cache.lookup_store(:mongo_store)
          store.collection.should_not be_nil
        end
        
        it "can turn off index creation" do
          Mongo::Collection.any_instance.expects(:create_index).never
          store = ActiveSupport::Cache.lookup_store(:mongo_store, :create_index => false)
          store.collection.should_not be_nil
        end
          
        it "defaults to an expiration of 1 day" do
          store = ActiveSupport::Cache.lookup_store(:mongo_store)
          store.expires_in.should == 1.day
        end
        
        it "can override expiration time with the :expires_in option" do
          store = ActiveSupport::Cache.lookup_store(:mongo_store, :expires_in => 1.week)
          store.expires_in.should == 1.week
        end
        
        it "can take options as the first parameter" do
          store = ActiveSupport::Cache.lookup_store(:mongo_store, :expires_in => 1.minute)
          store.expires_in.should == 1.minute
        end
        
        it "can take options as the second parameter" do
          store = ActiveSupport::Cache.lookup_store(:mongo_store, 'foo', :expires_in => 1.day)
          store.expires_in.should == 1.day
        end
        
        after(:all) do
          c = Mongo::Connection.new
          %w(rails_cache mongo_store_test_name mongo_store_test_deebee mongo_store_test_mappy mongo_store_test_lazy).each do |db|
            c.drop_database(db)
          end
        end  
      end
      
      describe "caching" do
        before(:all) do
          @store = ActiveSupport::Cache.lookup_store(:mongo_store, 'mongo_store_test', :db => 'mongo_store_test')
        end
        
        it "can write values" do
          @store.write('fnord', 'I am vaguely disturbed.')
          @store.collection.find_one('_id' => 'fnord')['value'].should == "I am vaguely disturbed."
        end
        
        it "can read values" do
          @store.collection.insert({'_id' => 'yoo', :value => 'yar', :expires => (Time.now + 10)})
          @store.read('yoo').should == 'yar'
        end
        
        it "can read multiple values" do
          @store.collection.insert({'_id' => 'multi1', :value => 'weee', :expires => (Time.now + 10)})
          @store.collection.insert({'_id' => 'multi2', :value => 'wooo', :expires => (Time.now + 10)})
          @store.read_multi('multi1','multi2').should == { 'multi1' => 'weee', 'multi2' => 'wooo' }
          @store.read_multi('multi1','multi2','multi3').should == { 'multi1' => 'weee', 'multi2' => 'wooo', 'multi3' => nil }
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
        
        it "can expire a value from the global setting" do
          old_expires = @store.expires_in
          @store.expires_in = 2.seconds
          @store.write('foo', 'bar')
          @store.write('yoo', 'yar', :expires_in => 5.minutes)
          @store.read('foo').should == 'bar'
          @store.read('yoo').should == 'yar'
          sleep(3)
          @store.read('foo').should be_nil
          @store.read('yoo').should == 'yar'
          @store.expires_in = old_expires
        end
        
        it "can clean up expired values" do
          @store.write('foo', 'bar', :expires_in => 2.seconds)
          @store.write('yoo', 'yar', :expires_in => 2.days)
          sleep(3)
          @store.collection.count.should == 2
          @store.clean_expired
          @store.collection.count.should == 1
        end
        
        it "can clear the whole cache" do
          @store.write('foo', 'bar')
          @store.write('yoo', 'yar', :expires_in => 2.days)
          @store.collection.count.should == 2
          @store.clear
          @store.collection.count.should == 0
        end
        
        describe "namespacing" do
          before(:each) do
            @store.options[:namespace] = 'ns1'
            @store.write 'foo', 'bar'
            @store.write 'too', 'tar'
            @store.write 'foz', 'baz'
            @store.write 'foo', 'yar', :namespace => 'ns2'
            @store.write 'too', 'car', :namespace => 'ns2'
            @store.write 'foz', 'bat', :namespace => 'ns2'
          end
          
          it "uses the default namespace" do
            @store.collection.find_one('_id' => /ns1.*foo/)['value'].should == "bar"
          end
          
          it "can override the namespace" do
            @store.collection.find_one('_id' => /ns2.*foo/)['value'].should == "yar"
          end
          
          it "can have different values in different namespaces" do
            @store.read('foo').should == 'bar'
            @store.read('foo', :namespace => 'ns2').should == 'yar'
          end
          
          it "deletes from the default namespace" do
            @store.delete('foo')
            @store.read('foo').should be_nil
            @store.read('foo', :namespace => 'ns2').should == 'yar'
          end
          
          it "deletes from an overridden namespace" do
            @store.delete('foo', :namespace => 'ns2')
            @store.read('foo').should == 'bar'
            @store.read('foo', :namespace => 'ns2').should be_nil
          end
          
          it "deletes matching patterns from the default namespace" do
            @store.delete_matched(/oo/)
            @store.read('foo').should be_nil
            @store.read('too').should be_nil
            @store.read('foz').should == 'baz'
            @store.read('foo', :namespace => 'ns2').should == 'yar'
            @store.read('too', :namespace => 'ns2').should == 'car'
            @store.read('foz', :namespace => 'ns2').should == 'bat'
          end
          
          it "deletes matching patterns from the overridden namespace" do
            @store.delete_matched(/oo/, :namespace => "ns2")
            @store.read('foo').should == 'bar'
            @store.read('too').should == 'tar'
            @store.read('foz').should == 'baz'
            @store.read('foo', :namespace => 'ns2').should be_nil
            @store.read('too', :namespace => 'ns2').should be_nil
            @store.read('foz', :namespace => 'ns2').should == 'bat'
          end
          
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
  end
end