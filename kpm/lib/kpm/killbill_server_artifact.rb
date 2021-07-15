# frozen_string_literal: true

require 'rexml/document'
require 'set'

module KPM
  class KillbillServerArtifact < BaseArtifact
    class << self
      def versions(artifact_id, packaging = KPM::BaseArtifact::KILLBILL_PACKAGING, classifier = KPM::BaseArtifact::KILLBILL_CLASSIFIER, overrides = {}, ssl_verify = true)
        coordinate_map = { group_id: KPM::BaseArtifact::KILLBILL_GROUP_ID, artifact_id: artifact_id, packaging: packaging, classifier: classifier }
        coordinates = KPM::Coordinates.build_coordinates(coordinate_map)
        response    = REXML::Document.new nexus_remote(overrides, ssl_verify).search_for_artifacts(coordinates)
        versions    = SortedSet.new
        response.elements.each('searchNGResponse/data/artifact/version') { |element| versions << element.text }
        versions
      end

      def info(version = 'LATEST', sha1_file = nil, force_download = false, verify_sha1 = true, overrides = {}, ssl_verify = true)
        logger = Logger.new(STDOUT)
        logger.level = Logger::ERROR

        # Initialize as early as possible (used in rescue block below)
        sha1_checker = sha1_file ? Sha1Checker.from_file(sha1_file) : nil

        version = KPM::Installer.get_kb_latest_stable_version if version == 'LATEST'

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
                             sha1_file,
                             force_download,
                             verify_sha1,
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
                              sha1_file,
                              force_download,
                              verify_sha1,
                              overrides,
                              ssl_verify)
          file = File.new(oss_pom_info[:file_path])
          pom = REXML::Document.new(file)
          properties_element = pom.root.elements['properties']
          %w[killbill-api killbill-plugin-api killbill-commons killbill-platform].each do |property|
            versions[property] = properties_element.elements["#{property}.version"].text
            file.close
          end

         sha1_checker.cache_killbill_info(version, versions) if sha1_checker
		 FileUtils.rm_f(oss_pom_info[:file_path])
        end
        versions
      rescue StandardError => e
        # Network down? Hopefully, we have something in the cache
        cached_version = sha1_checker ? sha1_checker.killbill_info(version) : nil
        raise e if force_download || !cached_version

        # Use the cache
        cached_version
      end
    end
  end
end
