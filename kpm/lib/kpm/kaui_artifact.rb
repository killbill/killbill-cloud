require 'rexml/document'
require 'set'

module KPM
  class KauiArtifact < BaseArtifact
    class << self
      def versions(overrides={}, ssl_verify=true)
        coordinates = build_coordinates(KPM::BaseArtifact::KAUI_GROUP_ID,
                                        KPM::BaseArtifact::KAUI_ARTIFACT_ID,
                                        KPM::BaseArtifact::KAUI_PACKAGING,
                                        KPM::BaseArtifact::KAUI_CLASSIFIER)
        response    = REXML::Document.new nexus_remote(overrides, ssl_verify).search_for_artifacts(coordinates)
        versions    = SortedSet.new
        response.elements.each('search-results/data/artifact/version') { |element| versions << element.text }
        versions
      end
    end
  end
end
