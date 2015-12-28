require 'rexml/document'
require 'set'

module KPM
  class KillbillServerArtifact < BaseArtifact
    class << self
      def versions(artifact_id, packaging=KPM::BaseArtifact::KILLBILL_PACKAGING, classifier=KPM::BaseArtifact::KILLBILL_CLASSIFIER, overrides={}, ssl_verify=true)
        coordinate_map = {:group_id => KPM::BaseArtifact::KILLBILL_GROUP_ID, :artifact_id => artifact_id, :packaging => packaging, :classifier => classifier}
        coordinates = build_coordinates(coordinate_map)
        response    = REXML::Document.new nexus_remote(overrides, ssl_verify).search_for_artifacts(coordinates)
        versions    = SortedSet.new
        response.elements.each('search-results/data/artifact/version') { |element| versions << element.text }
        versions
      end

      def info(version='LATEST', overrides={}, ssl_verify=true)
        logger = Logger.new(STDOUT)
        logger.level = Logger::ERROR

        versions = {}
        Dir.mktmpdir do |dir|
          # Retrieve the main Kill Bill pom
          kb_pom_info = pull(logger,
                             KPM::BaseArtifact::KILLBILL_GROUP_ID,
                             'killbill',
                             'pom',
                             nil,
                             version,
                             dir,
                             nil,
                             false,
                             true,
                             overrides,
                             ssl_verify)

          # Extract the killbill-oss-parent version
          pom = REXML::Document.new(File.new(kb_pom_info[:file_path]))
          oss_parent_version = pom.root.elements['parent/version'].text
          kb_version = pom.root.elements['version'].text

          versions['killbill'] = kb_version
          versions['killbill-oss-parent'] = oss_parent_version

          # Retrieve the killbill-oss-parent pom
          oss_pom_info = pull(logger,
                              KPM::BaseArtifact::KILLBILL_GROUP_ID,
                              'killbill-oss-parent',
                              'pom',
                              nil,
                              oss_parent_version,
                              dir,
                              nil,
                              false,
                              true,
                              overrides,
                              ssl_verify)

          pom = REXML::Document.new(File.new(oss_pom_info[:file_path]))
          properties_element = pom.root.elements['properties']
          %w(killbill-api killbill-plugin-api killbill-commons killbill-platform).each do |property|
            versions[property] = properties_element.elements["#{property}.version"].text
          end
        end
        versions
      end
    end
  end
end
