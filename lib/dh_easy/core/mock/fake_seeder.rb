module DhEasy
  module Core
    module Mock
      # Fake seeder that emulates `Datahen` seeder executor.
      class FakeSeeder
        include DhEasy::Core::Mock::FakeExecutor

        # Fake seeder exposed methods to isolated context.
        # @private
        #
        # @return [Array]
        def self.exposed_methods
          real_methods = Datahen::Scraper::RubySeederExecutor.exposed_methods.uniq
          mock_methods = [
            :outputs,
            :pages,
            :save_pages,
            :save_outputs,
            :find_output,
            :find_outputs
          ].freeze
          DhEasy::Core::Mock::FakeExecutor.check_compatibility real_methods, mock_methods
          mock_methods
        end
      end
    end
  end
end
