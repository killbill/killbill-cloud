# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'rexml/document'
require 'openssl'

module KPM
  module NexusFacade
    class GithubApiCalls < NexusApiCallsV2
      def pull_artifact_endpoint(coordinates)
        coords = parse_coordinates(coordinates)
        resolved = resolve_snapshot_version(coordinates)
        filename_version = resolved || coords[:version]
        "#{artifact_base_path(coords)}/#{coords[:version]}/#{coords[:artifact_id]}-#{filename_version}.#{coords[:extension]}"
      end

      alias parent_get_artifact_info get_artifact_info
      def get_artifact_info(coordinates)
        coords = parse_coordinates(coordinates)
        resolved = resolve_snapshot_version(coordinates)
        filename_version = resolved || coords[:version]

        versioned_artifact = "#{coords[:version]}/#{coords[:artifact_id]}-#{filename_version}.#{coords[:extension]}"
        sha1 = fetch_sha1(coordinates, versioned_artifact)

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
        coords = parse_coordinates(coordinates)
        base_path = artifact_base_path(coords)
        if coords[:version] =~ /-SNAPSHOT$/
          "#{base_path}/#{coords[:version]}/maven-metadata.xml"
        else
          "#{base_path}/maven-metadata.xml"
        end
      end

      def search_for_artifact_endpoint(_coordinates)
        raise NoMethodError, 'GitHub Packages has no search support'
      end

      def build_query_params(_coordinates, _what_parameters = nil)
        ''
      end

      private

      # Resolves a SNAPSHOT version to its timestamped form using maven-metadata.xml.
      # Returns nil for non-SNAPSHOT versions or when metadata is unavailable.
      def resolve_snapshot_version(coordinates)
        coords = parse_coordinates(coordinates)
        return nil unless coords[:version] =~ /-SNAPSHOT$/

        version_metadata = begin
                             parent_get_artifact_info(coordinates)
                           rescue StandardError
                             return nil
                           end

        doc = REXML::Document.new(version_metadata)
        timestamp = begin
                      doc.elements['//versioning/snapshot/timestamp'].text
                    rescue StandardError
                      nil
                    end
        build_number = begin
                         doc.elements['//versioning/snapshot/buildNumber'].text
                       rescue StandardError
                         nil
                       end
        return nil if timestamp.nil? || build_number.nil?

        base_version = coords[:version].sub(/-SNAPSHOT$/, '')
        "#{base_version}-#{timestamp}-#{build_number}"
      end

      def fetch_sha1(coordinates, versioned_artifact)
        coords = parse_coordinates(coordinates)
        endpoint = "#{artifact_base_path(coords)}/#{versioned_artifact}.sha1"
        get_response_with_retries(coordinates, endpoint, nil)
      end

      def artifact_base_path(coords)
        org_and_repo = URI.parse(configuration[:url]).path
        "#{org_and_repo}/#{coords[:group_id].gsub('.', '/')}/#{coords[:artifact_id]}"
      end
    end
  end
end
