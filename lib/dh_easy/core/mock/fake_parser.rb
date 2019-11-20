module DhEasy
  module Core
    module Mock
      # Fake parser that emulates `Datahen` parser executor.
      class FakeParser
        include DhEasy::Core::Mock::FakeExecutor

        # Fake parser exposed methods to isolated context.
        # @private
        #
        # @return [Array]
        def self.exposed_methods
          real_methods = Datahen::Scraper::RubyParserExecutor.exposed_methods.uniq
          mock_methods = [
            :content,
            :failed_content,
            :outputs,
            :pages,
            :page,
            :save_pages,
            :save_outputs,
            :find_output,
            :find_outputs,
            :refetch,
            :reparse
          ].freeze
          DhEasy::Core::Mock::FakeExecutor.check_compatibility real_methods, mock_methods
          mock_methods
        end
      end
    end
  end
end
