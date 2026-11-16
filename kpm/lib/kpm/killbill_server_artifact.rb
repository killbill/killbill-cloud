# frozen_string_literal: true

require 'rexml/document'

module KPM
  class KillbillServerArtifact < BaseArtifact
    class << self
      def versions(artifact_id, packaging = KPM::BaseArtifact::KILLBILL_PACKAGING, classifier = KPM::BaseArtifact::KILLBILL_CLASSIFIER, overrides = {}, ssl_verify = true)
        coordinate_map = { group_id: KPM::BaseArtifact::KILLBILL_GROUP_ID, artifact_id: artifact_id, packaging: packaging, classifier: classifier }
        coordinates = KPM::Coordinates.build_coordinates(coordinate_map)
        response    = REXML::Document.new nexus_remote(overrides, ssl_verify).search_for_artifacts(coordinates)
        versions    = []
        response.elements.each('searchNGResponse/data/artifact/version') { |element| versions << element.text }
        versions.sort!.uniq
      end

      def info(version = 'LATEST', sha1_file = nil, force_download = false, verify_sha1 = true, overrides = {}, ssl_verify = true)
        logger = Logger.new(STDOUT)
        logger.level = Logger::ERROR

        # Initialize as early as possible (used in rescue block below)
        sha1_checker = sha1_file ? Sha1Checker.from_file(sha1_file) : nil

        versions = {}
        Dir.mktmpdir do |dir|
          oss_parent_version = 'LATEST'

          # killbill-oss-parent is the source of truth for the versions: use the one declared by the Kill Bill release.
          # For LATEST, the repository may not host the Kill Bill pom (e.g. different groupId): use the latest killbill-oss-parent instead.
          kb_pom = nil
          begin
            kb_pom = pull_killbill_pom(logger, dir, version, sha1_file, force_download, verify_sha1, overrides, ssl_verify)
          rescue StandardError
            raise unless version == 'LATEST'
          end
          if kb_pom
            oss_parent_version = kb_pom[:parent_version]
            versions['killbill'] = kb_pom[:version]
          end

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
          begin
            pom = REXML::Document.new(file)
            versions['killbill-oss-parent'] = pom.root.elements['version']&.text || oss_parent_version
            properties_element = pom.root.elements['properties']
            %w[killbill-api killbill-plugin-api killbill-commons killbill-platform].each do |property|
              versions[property] = properties_element.elements["#{property}.version"].text
            end
          ensure
            file.close
            FileUtils.rm_f(oss_pom_info[:file_path])
          end
          sha1_checker.cache_killbill_info(version, versions) if sha1_checker
        end
        versions
      rescue StandardError => e
        # Network down? Hopefully, we have something in the cache
        cached_version = sha1_checker ? sha1_checker.killbill_info(version) : nil
        raise e if force_download || !cached_version

        # Use the cache
        cached_version
      end

      private

      # Retrieve the main Kill Bill pom and extract its version and the killbill-oss-parent version it declares
      def pull_killbill_pom(logger, dir, version, sha1_file, force_download, verify_sha1, overrides, ssl_verify)
        pom_info = pull(logger, KPM::BaseArtifact::KILLBILL_GROUP_ID, 'killbill', 'pom', nil, version, dir, sha1_file, force_download, verify_sha1, overrides, ssl_verify)
        file = File.new(pom_info[:file_path])
        begin
          pom = REXML::Document.new(file)
          { version: pom.root.elements['version'].text, parent_version: pom.root.elements['parent/version'].text }
        ensure
          file.close
          FileUtils.rm_f(pom_info[:file_path])
        end
      end
    end
  end
end
