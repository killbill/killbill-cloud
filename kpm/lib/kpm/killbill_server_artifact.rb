require 'rexml/document'
require 'set'

module KPM
  class KillbillServerArtifact < BaseArtifact
    class << self
      KILLBILL_SERVER_ARTIFACT_ID = 'killbill-server'
      KILLBILL_SERVER_WAR = "#{KILLBILL_GROUP_ID}:#{KILLBILL_SERVER_ARTIFACT_ID}:war:jar-with-dependencies"

      def pull(version='LATEST', destination=nil, overrides={}, ssl_verify=true)
        nexus_remote(overrides, ssl_verify).pull_artifact("#{KILLBILL_SERVER_WAR}:#{version}", destination)
      end

      def versions(overrides={}, ssl_verify=true)
        response = REXML::Document.new nexus_remote(overrides, ssl_verify).search_for_artifacts(KILLBILL_SERVER_WAR)
        versions = SortedSet.new
        response.elements.each("search-results/data/artifact/version") { |element| versions << element.text }
        versions
      end
    end
  end
end