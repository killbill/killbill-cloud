require 'rexml/document'
require 'set'

module KPM
  class KillbillServerArtifact < BaseArtifact
    class << self
      def versions(artifact_id, packaging=KPM::BaseArtifact::KILLBILL_PACKAGING, classifier=KPM::BaseArtifact::KILLBILL_CLASSIFIER, overrides={}, ssl_verify=true)
        coordinates = build_coordinates(KPM::BaseArtifact::KILLBILL_GROUP_ID, artifact_id, packaging, classifier)
        response    = REXML::Document.new nexus_remote(overrides, ssl_verify).search_for_artifacts(coordinates)
        versions    = SortedSet.new
        response.elements.each('search-results/data/artifact/version') { |element| versions << element.text }
        versions
      end
    end
  end
end
