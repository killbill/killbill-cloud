# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'rexml/document'

module KPM
  module NexusFacade
    class MavenCentralApiCalls < NexusApiCallsV2
      READ_TIMEOUT_DEFAULT = 60
      OPEN_TIMEOUT_DEFAULT = 60

      attr_reader :configuration
      attr_accessor :logger

      BASE_REPO_URL = 'https://repo1.maven.org/maven2'
      SEARCH_API = 'https://search.maven.org/solrsearch/select'

      def initialize(configuration, _ssl_verify, logger)
        @configuration = configuration
        @configuration[:url] ||= BASE_REPO_URL
        @logger = logger
      end

      def search_for_artifacts(coordinates)
        artifact = parse_coordinates(coordinates)
        query = URI.encode_www_form({
                                      q: "g:\"#{artifact[:group_id]}\" AND a:\"#{artifact[:artifact_id]}\"",
                                      rows: 200,
                                      wt: 'json',
                                      core: 'gav'
                                    })
        url = "#{SEARCH_API}?#{query}"

        response = Net::HTTP.get_response(URI(url))
        raise "Search failed: #{response.code}" unless response.code.to_i == 200

        json = JSON.parse(response.body)
        docs = json['response']['docs']
        artifacts_xml = "<searchNGResponse><data>"
        docs.each do |doc|
          artifacts_xml += "<artifact>"
          artifacts_xml += "<groupId>#{doc['g']}</groupId>"
          artifacts_xml += "<artifactId>#{doc['a']}</artifactId>"
          artifacts_xml += "<version>#{doc['v']}</version>"
          artifacts_xml += "<repositoryId>central</repositoryId>"
          artifacts_xml += "</artifact>"
        end
        artifacts_xml += "</data></searchNGResponse>"
        artifacts_xml
      end

      def get_artifact_info(coordinates)
        _, versioned_artifact, coords = build_base_path_and_coords(coordinates)
        sha1 = get_sha1(coordinates)
        artifact_xml = "<artifact-resolution><data>"
        artifact_xml += "<presentLocally>true</presentLocally>"
        artifact_xml += "<groupId>#{coords[:group_id]}</groupId>"
        artifact_xml += "<artifactId>#{coords[:artifact_id]}</artifactId>"
        artifact_xml += "<version>#{coords[:version]}</version>"
        artifact_xml += "<extension>#{coords[:packaging]}</extension>"
        artifact_xml += "<snapshot>#{!(coords[:version] =~ /-SNAPSHOT$/).nil?}</snapshot>"
        artifact_xml += "<sha1>#{sha1}</sha1>"
        artifact_xml += "<repositoryPath>/#{coords[:group_id].gsub('.', '/')}/#{versioned_artifact}</repositoryPath>"
        artifact_xml += "</data></artifact-resolution>"
        artifact_xml
      end

      def pull_artifact(coordinates, destination)
        artifact = parse_coordinates(coordinates)
        version = artifact[:version] || fetch_latest_version(artifact)
        file_name = build_file_name(artifact[:artifact_id], version, artifact[:classifier], artifact[:extension])
        download_url = build_download_url(artifact, version, file_name)

        dest_path = File.join(File.expand_path(destination || '.'), file_name)

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

      def build_base_path_and_coords(coordinates)
        coords = parse_coordinates(coordinates)

        token_org_and_repo = URI.parse(configuration[:url]).path

        [
          "#{token_org_and_repo}/#{coords[:group_id].gsub('.', '/')}/#{coords[:artifact_id]}",
          "#{coords[:version]}/#{coords[:artifact_id]}-#{coords[:version]}.#{coords[:extension]}",
          coords
        ]
      end

      def get_sha1(coordinates)
        base_path, versioned_artifact, = build_base_path_and_coords(coordinates)
        endpoint = "#{base_path}/#{versioned_artifact}.sha1"
        puts "Fetching SHA1 from: #{endpoint}"
        get_response_with_retries(nil, endpoint, nil)
      end

      def get_response_with_retries(coordinates, endpoint, what_parameters)
        logger.debug { "Fetching coordinates=#{coordinates}, endpoint=#{endpoint}, params=#{what_parameters}" }
        response = get_response(coordinates, endpoint, what_parameters)
        logger.debug { "Response body: #{response.body}" }
        process_response_with_retries(response)
      end

      def process_response_with_retries(response)
        case response.code
        when '200'
          response.body
        when '301', '302', '307'
          location = response['Location']
          logger.debug { "Following redirect to #{location}" }

          new_path = location.gsub!(configuration[:url], '')
          if new_path.nil?
            # Redirect to another domain (e.g. CDN)
            get_raw_response_with_retries(location)
          else
            get_response_with_retries(nil, location, nil)
          end
        when '404'
          raise StandardError, ERROR_MESSAGE_404
        else
          raise UnexpectedStatusCodeException, response.code
        end
      end

      def get_response(coordinates, endpoint, what_parameters)
        http = build_http
        query_params = build_query_params(coordinates, what_parameters) unless coordinates.nil?
        endpoint = endpoint_with_params(endpoint, query_params) unless coordinates.nil?
        request = Net::HTTP::Get.new(endpoint)
        if configuration.key?(:username) && configuration.key?(:password)
          request.basic_auth(configuration[:username], configuration[:password])
        elsif configuration.key?(:token)
          request['Authorization'] = "token #{configuration[:token]}"
        end

        logger.debug do
          http.set_debug_output(logger)
          "HTTP path: #{endpoint}"
        end

        http.request(request)
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
