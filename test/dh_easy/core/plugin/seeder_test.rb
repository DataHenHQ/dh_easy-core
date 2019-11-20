require 'test_helper'

describe 'seeder' do
  before do
    # Seeder object
    @object = Object.new
    class << @object
      include DhEasy::Core::Plugin::Seeder
    end

    # Seeder context
    exposed_methods = Datahen::Scraper::RubySeederExecutor.exposed_methods
    @context, @message_queue = DhEasy::Core::Mock.context_vars exposed_methods
  end

  describe 'integration test' do
    it 'should mock context on initialize' do
      default_methods = DhEasy::Core.instance_methods_from @object

      class << @object
        define_method :mock_initialize, lambda{|*args|initialize *args}
      end
      @object.mock_initialize context: @context
      mixed_methods = DhEasy::Core.instance_methods_from @object

      mock_methods = mixed_methods - default_methods - [:mock_initialize]
      expected_methods = DhEasy::Core.instance_methods_from @context
      assert_equal mock_methods.sort, expected_methods.sort
    end
  end
end
