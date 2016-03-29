require 'rexml/document'
require 'set'

module KPM
  class KauiArtifact < BaseArtifact
    class << self
      def versions(overrides={}, ssl_verify=true)

        coordinate_map = {:group_id => KPM::BaseArtifact::KAUI_GROUP_ID, :artifact_id => KPM::BaseArtifact::KAUI_ARTIFACT_ID, :packaging => KPM::BaseArtifact::KAUI_PACKAGING, :classifier => KPM::BaseArtifact::KAUI_CLASSIFIER}

        coordinates = KPM::Coordinates.build_coordinates(coordinate_map)
        response    = REXML::Document.new nexus_remote(overrides, ssl_verify).search_for_artifacts(coordinates)
        versions    = SortedSet.new
        response.elements.each('search-results/data/artifact/version') { |element| versions << element.text }
        versions
      end
    end
  end
end
