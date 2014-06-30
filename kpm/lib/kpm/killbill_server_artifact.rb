require 'rexml/document'
require 'set'

module KPM
  class KillbillServerArtifact < BaseArtifact
    KILLBILL_ARTIFACT_ID = 'killbill-profiles-killbill'
    KILLBILL_PACKAGING   = 'war'
    KILLBILL_CLASSIFIER  = 'jar-with-dependencies'

    KILLPAY_ARTIFACT_ID = 'killbill-profiles-killpay'
    KILLPAY_PACKAGING   = 'war'
    KILLPAY_CLASSIFIER  = 'jar-with-dependencies'

    class << self
      def pull(group_id, artifact_id, packaging=BaseArtifact::KILLBILL_PACKAGING, classifier=BaseArtifact::KILLBILL_CLASSIFIER, version='LATEST', destination=nil, overrides={}, ssl_verify=true)
        coordinates = build_coordinates(group_id, artifact_id, packaging, classifier, version)
        nexus_remote(overrides, ssl_verify).pull_artifact(coordinates, destination)
      end

      def versions(group_id, artifact_id, packaging=BaseArtifact::KILLBILL_PACKAGING, classifier=BaseArtifact::KILLBILL_CLASSIFIER, overrides={}, ssl_verify=true)
        coordinates = build_coordinates(group_id, artifact_id, packaging, classifier)
        response = REXML::Document.new nexus_remote(overrides, ssl_verify).search_for_artifacts(coordinates)
        versions = SortedSet.new
        response.elements.each("search-results/data/artifact/version") { |element| versions << element.text }
        versions
      end
    end
  end
end
