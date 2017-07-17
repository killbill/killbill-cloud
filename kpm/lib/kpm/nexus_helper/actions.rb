require_relative 'nexus_api_calls_v2'
#require_relative 'nexus_api_calls_v3'

module KPM
  module NexusFacade
    class Actions
      attr_reader :nexus_api_call

      def initialize(overrides, ssl_verify, logger)
        overrides ||=
          {
              url:        'https://oss.sonatype.org',
              repository: 'releases'
          }

        #this is where the version is verified
        #example if
        #@nexus_api_call = overrides['version'] == '3' ? NexusApiCallsV3.new(overrides, ssl_verify) : NexusApiCallsV2.new(overrides, ssl_verify)
        @nexus_api_call = NexusApiCallsV2.new(overrides, ssl_verify, logger)
      end

      def pull_artifact(coordinates, destination=nil)
        nexus_api_call.pull_artifact(coordinates, destination)
      end

      def get_artifact_info(coordinates)
        nexus_api_call.get_artifact_info(coordinates)
      end

      def search_for_artifacts(coordinates)
        nexus_api_call.search_for_artifacts(coordinates)
      end

    end
  end
end
