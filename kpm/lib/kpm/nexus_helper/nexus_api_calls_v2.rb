# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'rexml/document'
require 'openssl'

module KPM
  module NexusFacade
    class UnexpectedStatusCodeException < StandardError
      def initialize(code)
        @code = code
      end

      def message
        "The server responded with a #{@code} status code which is unexpected."
      end
    end

    class ArtifactMalformedException < StandardError
      class << self
        def message
          'Please submit your request using 4 colon-separated values. `groupId:artifactId:version:extension`'
        end
      end
    end

    # This is an extract and slim down of functions needed from nexus_cli to maintain the response expected by the base_artifact.
    class NexusApiCallsV2
      PULL_ARTIFACT_ENDPOINT = '/service/local/artifact/maven/redirect'
      GET_ARTIFACT_INFO_ENDPOINT = '/service/local/artifact/maven/resolve'
      SEARCH_FOR_ARTIFACT_ENDPOINT = '/service/local/lucene/search'

      READ_TIMEOUT_DEFAULT = 60
      OPEN_TIMEOUT_DEFAULT = 60

      ERROR_MESSAGE_404 = 'The artifact you requested information for could not be found. Please ensure it exists inside the Nexus.'
      ERROR_MESSAGE_503 = 'Could not connect to Nexus. Please ensure the url you are using is reachable.'

      attr_reader :version
      attr_reader :configuration
      attr_reader :ssl_verify
      attr_accessor :logger

      def initialize(configuration, ssl_verify, logger)
        @configuration = configuration
        @ssl_verify = ssl_verify
        @logger = logger
      end

      def search_for_artifacts(coordinates)
        logger.debug "Entered - Search for artifact, coordinates: #{coordinates}"
        response = get_response(coordinates, SEARCH_FOR_ARTIFACT_ENDPOINT, %i[g a])

        case response.code
        when '200'
          logger.debug "response body: #{response.body}"
          return response.body
        else
          raise UnexpectedStatusCodeException, response.code
        end
      end

      def get_artifact_info(coordinates)
        logger.debug "Entered - Get artifact info, coordinates: #{coordinates}"
        response = get_response(coordinates, GET_ARTIFACT_INFO_ENDPOINT, nil)

        case response.code
        when '200'
          logger.debug "response body: #{response.body}"
          return response.body
        when '404'
          raise StandardError, ERROR_MESSAGE_404
        when '503'
          raise StandardError, ERROR_MESSAGE_503
        else
          raise UnexpectedStatusCodeException, response.code
        end
      end

      def pull_artifact(coordinates, destination)
        logger.debug "Entered - Pull artifact, coordinates: #{coordinates}"
        file_name = get_file_name(coordinates)
        destination = File.join(File.expand_path(destination || '.'), file_name)
        logger.debug "destination: #{destination}"
        response = get_response(coordinates, PULL_ARTIFACT_ENDPOINT, nil)

        case response.code
        when '301', '307'
          location = response['Location'].gsub!(configuration[:url], '')
          logger.debug 'fetching artifact'
          file_response = get_response(nil, location, nil)

          File.open(destination, 'wb') do |io|
            io.write(file_response.body)
          end
        when 404
          raise StandardError, ERROR_MESSAGE_404
        else
          raise UnexpectedStatusCodeException, response.code
        end
        {
          file_name: file_name,
          file_path: File.expand_path(destination),
          version: version,
          size: File.size(File.expand_path(destination))
        }
      end

      private

      def parse_coordinates(coordinates)
        raise ArtifactMalformedException if coordinates.nil?

        split_coordinates = coordinates.split(':')
        raise ArtifactMalformedException if split_coordinates.empty? || (split_coordinates.size > 5)

        artifact = {}

        artifact[:group_id] = split_coordinates[0]
        artifact[:artifact_id] = split_coordinates[1]
        artifact[:extension] = split_coordinates.size > 3 ? split_coordinates[2] : 'jar'
        artifact[:classifier] = split_coordinates.size > 4 ? split_coordinates[3] : nil
        artifact[:version] = split_coordinates[-1]

        artifact[:version].upcase! if version == 'latest'

        artifact
      end

      def get_file_name(coordinates)
        artifact = parse_coordinates(coordinates)

        artifact[:version] = REXML::Document.new(get_artifact_info(coordinates)).elements['//version'].text if artifact[:version].casecmp('latest')

        if artifact[:classifier].nil?
          "#{artifact[:artifact_id]}-#{artifact[:version]}.#{artifact[:extension]}"
        else
          "#{artifact[:artifact_id]}-#{artifact[:version]}-#{artifact[:classifier]}.#{artifact[:extension]}"
        end
      end

      def get_query_params(coordinates, what_parameters = nil)
        artifact = parse_coordinates(coordinates)
        @version = artifact[:version].to_s.upcase

        query = { g: artifact[:group_id], a: artifact[:artifact_id], e: artifact[:extension], v: version, r: configuration[:repository] }
        query.merge!(c: artifact[:classifier]) unless artifact[:classifier].nil?

        params = what_parameters.nil? ? query : {}
        what_parameters.each { |key| params[key] = query[key] unless query[key].nil? } unless what_parameters.nil?

        params.map { |key, value| "#{key}=#{value}" }.join('&')
      end

      def get_response(coordinates, endpoint, what_parameters)
        http = get_http
        query_params = get_query_params(coordinates, what_parameters) unless coordinates.nil?
        endpoint = get_endpoint_with_params(endpoint, query_params) unless coordinates.nil?
        request = Net::HTTP::Get.new(endpoint)

        logger.debug "request endpoint: #{endpoint}"

        response = http.request(request)
        response
      end

      def get_http
        uri = URI.parse(configuration[:url])
        http = Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = configuration[:open_timeout] || OPEN_TIMEOUT_DEFAULT # seconds
        http.read_timeout = configuration[:read_timeout] || READ_TIMEOUT_DEFAULT # seconds
        http.use_ssl = (ssl_verify != false)
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless ssl_verify
        http
      end

      def get_endpoint_with_params(endpoint, query_params)
        "#{endpoint}?#{URI::DEFAULT_PARSER.escape(query_params)}"
      end
    end
  end
end
