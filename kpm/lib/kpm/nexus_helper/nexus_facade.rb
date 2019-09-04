require_relative 'actions'
module KPM
  module NexusFacade
    class << self
      def logger
        logger       = ::Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger
      end
    end

    class RemoteFactory
      class << self
        def create(overrides, ssl_verify = true, logger = nil)
          Actions.new(overrides, ssl_verify, logger || NexusFacade.logger)
        end
      end
    end
  end
end
