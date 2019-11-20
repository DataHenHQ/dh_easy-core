module DhEasy
  module Core
    module Mock
      # Fake finisher that emulates `Datahen` finisher executor.
      class FakeFinisher
        include DhEasy::Core::Mock::FakeExecutor

        # Fake finisher exposed methods to isolated context.
        # @private
        #
        # @return [Array]
        def self.exposed_methods
          real_methods = Datahen::Scraper::RubyFinisherExecutor.exposed_methods.uniq
          mock_methods = [
            :outputs,
            :save_outputs,
            :find_output,
            :find_outputs
          ]
          DhEasy::Core::Mock::FakeExecutor.check_compatibility real_methods, mock_methods
          mock_methods << :job_id
          mock_methods.freeze
          mock_methods
        end
      end
    end
  end
end
