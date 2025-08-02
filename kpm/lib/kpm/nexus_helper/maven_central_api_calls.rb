# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'rexml/document'

module KPM
  module NexusFacade
    class MavenCentralApiCalls
      READ_TIMEOUT_DEFAULT = 60
      OPEN_TIMEOUT_DEFAULT = 60

      attr_reader :configuration
      attr_accessor :logger

      BASE_REPO_URL = 'https://repo1.maven.org/maven2'
      SEARCH_API = 'https://search.maven.org/solrsearch/select'

      def initialize(configuration, logger)
        @configuration = configuration
        @logger = logger
      end

      def search_for_artifacts(coordinates)
        artifact = parse_coordinates(coordinates)
        query = URI.encode_www_form({
                                      q: "g:\"#{artifact[:group_id]}\" AND a:\"#{artifact[:artifact_id]}\"",
                                      rows: 20,
                                      wt: 'json'
                                    })
        url = "#{SEARCH_API}?#{query}"

        logger.debug { "Searching artifacts via Maven Central: #{url}" }
        response = Net::HTTP.get_response(URI(url))
        raise "Search failed: #{response.code}" unless response.code.to_i == 200

        response.body
      end

      def get_artifact_info(coordinates)
        artifact = parse_coordinates(coordinates)
        metadata_url = build_metadata_url(artifact)
        logger.debug { "Fetching metadata: #{metadata_url}" }

        response = Net::HTTP.get_response(URI(metadata_url))
        raise "Metadata fetch failed: #{response.code}" unless response.code.to_i == 200

        response.body
      end

      def pull_artifact(coordinates, destination)
        artifact = parse_coordinates(coordinates)
        version = artifact[:version] || fetch_latest_version(artifact)
        file_name = build_file_name(artifact[:artifact_id], version, artifact[:classifier], artifact[:extension])
        download_url = build_download_url(artifact, version, file_name)

        dest_path = File.join(File.expand_path(destination || '.'), file_name)
        logger.debug { "Downloading artifact from #{download_url} to #{dest_path}" }

        File.open(dest_path, 'wb') do |io|
          io.write(Net::HTTP.get(URI(download_url)))
        end

        {
          file_name: file_name,
          file_path: File.expand_path(dest_path),
          version: version,
          size: File.size(File.expand_path(dest_path))
        }
      end

      private

      def parse_coordinates(coordinates)
        raise 'Invalid coordinates' if coordinates.nil?

        parts = coordinates.split(':')
        raise 'Invalid coordinates format' if parts.size < 3

        {
          group_id: parts[0],
          artifact_id: parts[1],
          extension: parts.size > 3 ? parts[2] : 'jar',
          classifier: parts.size > 4 ? parts[3] : nil,
          version: parts[-1]
        }
      end

      def build_metadata_url(artifact)
        group_path = artifact[:group_id].tr('.', '/')
        "#{BASE_REPO_URL}/#{group_path}/#{artifact[:artifact_id]}/maven-metadata.xml"
      end

      def fetch_latest_version(artifact)
        xml = REXML::Document.new(Net::HTTP.get(URI(build_metadata_url(artifact))))
        xml.elements['//versioning/latest']&.text || xml.elements['//version']&.text
      end

      def build_file_name(artifact_id, version, classifier, extension)
        classifier ? "#{artifact_id}-#{version}-#{classifier}.#{extension}" : "#{artifact_id}-#{version}.#{extension}"
      end

      def build_download_url(artifact, version, file_name)
        group_path = artifact[:group_id].tr('.', '/')
        "#{BASE_REPO_URL}/#{group_path}/#{artifact[:artifact_id]}/#{version}/#{file_name}"
      end
    end
  end
end
