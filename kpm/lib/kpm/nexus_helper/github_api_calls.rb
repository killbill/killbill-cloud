# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'rexml/document'
require 'openssl'

module KPM
  module NexusFacade
    class GithubApiCalls < NexusApiCallsV2
      def pull_artifact_endpoint(coordinates)
        base_path, versioned_artifact, = build_base_path_and_coords(coordinates)
        "#{base_path}/#{versioned_artifact}"
      end

      def get_artifact_info(coordinates)
        super

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
        base_path, = build_base_path_and_coords(coordinates)
        "#{base_path}/maven-metadata.xml"
      end

      def search_for_artifact_endpoint(_coordinates)
        raise NoMethodError, 'GitHub Packages has no search support'
      end

      def build_query_params(_coordinates, _what_parameters = nil)
        ''
      end

      private

      def get_sha1(coordinates)
        base_path, versioned_artifact, = build_base_path_and_coords(coordinates)
        endpoint = "#{base_path}/#{versioned_artifact}.sha1"
        get_response_with_retries(coordinates, endpoint, nil)
      end

      def build_base_path_and_coords(coordinates)
        coords = parse_coordinates(coordinates)

        # The url may contain the org and repo, e.g. 'https://maven.pkg.github.com/killbill/qualpay-java-client'
        org_and_repo = URI.parse(configuration[:url]).path

        [
          "#{org_and_repo}/#{coords[:group_id].gsub('.', '/')}/#{coords[:artifact_id]}",
          "#{coords[:version]}/#{coords[:artifact_id]}-#{coords[:version]}.#{coords[:extension]}",
          coords
        ]
      end
    end
  end
end
