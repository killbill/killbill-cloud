require_relative 'actions'
module KPM
  module NexusFacade
    class RemoteFactory
      class << self
        def create(overrides, ssl_verify=true)
          Actions.new(overrides, ssl_verify)
        end

      end
    end
  end
end