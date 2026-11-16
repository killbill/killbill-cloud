# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'rexml/document'
require 'openssl'

module KPM
  module NexusFacade
    class CloudsmithApiCalls < NexusApiCallsV2
      def pull_artifact_endpoint(coordinates)
        version_artifact_details = begin
                                     parent_get_artifact_info(coordinates)
                                   rescue StandardError
                                     ''
                                   end

        # For SNAPSHOTs, we need to figure out the version used as part of the filename
        filename_version = begin
                             REXML::Document.new(version_artifact_details).elements['//versioning/snapshotVersions/snapshotVersion[1]/value'].text
                           rescue StandardError
                             nil
                           end
        coords = parse_coordinates(coordinates)
        coords[:version] = filename_version unless filename_version.nil?
        new_coordinates = coords.values.compact.join(':')

        base_path, versioned_artifact, = build_base_path_and_coords(new_coordinates)
        "#{base_path}/#{versioned_artifact}"
      end

      alias parent_get_artifact_info get_artifact_info
      def get_artifact_info(coordinates)
        coordinates = resolve_latest(coordinates)
        _, versioned_artifact, coords = build_base_path_and_coords(coordinates)
        sha1 = get_sha1(coordinates)
        "<artifact-resolution>
  <data>
    <presentLocally>true</presentLocally>
    <groupId>#{coords[:group_id]}</groupId>
    <artifactId>#{coords[:artifact_id]}</artifactId>
    <version>#{coords[:version]}</version>
    <extension>#{coords[:packaging]}</extension>
    <snapshot>#{!(coords[:version] =~ /-SNAPSHOT$/).nil?}</snapshot>
    <sha1>#{sha1}</sha1>
    <repositoryPath>/#{coords[:group_id].gsub('.', '/')}/#{versioned_artifact}</repositoryPath>
  </data>
</artifact-resolution>"
      end

      def get_artifact_info_endpoint(coordinates)
        base_path, _, coords = build_base_path_and_coords(coordinates)
        # Note: we must retrieve the XML for the version, to support SNAPSHOTs
        "#{base_path}/#{coords[:version]}/maven-metadata.xml"
      end

      def search_for_artifact_endpoint(_coordinates)
        raise NoMethodError, 'Cloudsmith has no search support'
      end

      def build_query_params(_coordinates, _what_parameters = nil)
        ''
      end

      private

      # Cloudsmith has no search nor resolve API: use the artifact level maven-metadata.xml to find the latest version
      def resolve_latest(coordinates)
        base_path, _, coords = build_base_path_and_coords(coordinates)
        return coordinates unless coords[:version].casecmp('latest').zero?

        metadata = REXML::Document.new(get_response_with_retries(nil, "#{base_path}/maven-metadata.xml", nil))
        latest_version = metadata.elements['//versioning/release']&.text || metadata.elements['//versioning/latest']&.text
        raise StandardError, "Unable to find the latest version of #{coords[:group_id]}:#{coords[:artifact_id]}" if latest_version.nil? || latest_version.empty?

        coordinates.sub(/[^:]+\z/, latest_version)
      end

      def get_sha1(coordinates)
        base_path, versioned_artifact, = build_base_path_and_coords(coordinates)
        endpoint = "#{base_path}/#{versioned_artifact}.sha1"
        get_response_with_retries(coordinates, endpoint, nil)
      end

      def build_base_path_and_coords(coordinates)
        coords = parse_coordinates(coordinates)

        token_org_and_repo = URI.parse(configuration[:url]).path

        [
          "#{token_org_and_repo}/#{coords[:group_id].gsub('.', '/')}/#{coords[:artifact_id]}",
          "#{coords[:version]}/#{coords[:artifact_id]}-#{coords[:version]}.#{coords[:extension]}",
          coords
        ]
      end
    end
  end
end
