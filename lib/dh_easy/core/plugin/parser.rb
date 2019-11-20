module DhEasy
  module Core
    module Plugin
      module Parser
        include DhEasy::Core::Plugin::InitializeHook
        include DhEasy::Core::Plugin::ParserBehavior

        # Initialize parser and hooks.
        #
        # @param [Hash] opts ({}) Configuration options.
        #
        # @see DhEasy::Core::Plugin::ContextIntegrator#initialize_hook_core_context_integrator
        def initialize opts = {}
          initialize_hooks opts
        end
      end
    end
  end
end
