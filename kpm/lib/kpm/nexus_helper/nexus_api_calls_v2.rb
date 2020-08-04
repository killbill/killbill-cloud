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
      READ_TIMEOUT_DEFAULT = 60
      OPEN_TIMEOUT_DEFAULT = 60

      ERROR_MESSAGE_404 = 'The artifact you requested information for could not be found. Please ensure it exists inside the Nexus.'

      attr_reader :version, :configuration, :ssl_verify

      attr_accessor :logger

      def initialize(configuration, ssl_verify, logger)
        @configuration = configuration
        @ssl_verify = ssl_verify
        @logger = logger
      end

      def search_for_artifacts(coordinates)
        logger.debug "Entered - Search for artifact, coordinates: #{coordinates}"
        response = get_response(coordinates, search_for_artifact_endpoint(coordinates), %i[g a])

        case response.code
        when '200'
          logger.debug "response body: #{response.body}"
          response.body
        when '404'
          raise StandardError, ERROR_MESSAGE_404
        else
          raise UnexpectedStatusCodeException, response.code
        end
      end

      def get_artifact_info(coordinates)
        get_response_with_retries(coordinates, get_artifact_info_endpoint(coordinates), nil)
      end

      def pull_artifact(coordinates, destination)
        file_name = get_file_name(coordinates)
        destination = File.join(File.expand_path(destination || '.'), file_name)
        logger.debug { "Downloading to destination: #{destination}" }

        File.open(destination, 'wb') do |io|
          io.write(get_response_with_retries(coordinates, pull_artifact_endpoint(coordinates), nil))
        end

        {
          file_name: file_name,
          file_path: File.expand_path(destination),
          version: version,
          size: File.size(File.expand_path(destination))
        }
      end

      def pull_artifact_endpoint(_coordinates)
        '/service/local/artifact/maven/redirect'
      end

      def get_artifact_info_endpoint(_coordinates)
        '/service/local/artifact/maven/resolve'
      end

      def search_for_artifact_endpoint(_coordinates)
        '/service/local/lucene/search'
      end

      def build_query_params(coordinates, what_parameters = nil)
        artifact = parse_coordinates(coordinates)
        @version = artifact[:version].to_s.upcase

        query = { g: artifact[:group_id], a: artifact[:artifact_id], e: artifact[:extension], v: version, r: configuration[:repository] }
        query.merge!(c: artifact[:classifier]) unless artifact[:classifier].nil?

        params = what_parameters.nil? ? query : {}
        what_parameters.each { |key| params[key] = query[key] unless query[key].nil? } unless what_parameters.nil?

        params.map { |key, value| "#{key}=#{value}" }.join('&')
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
        when '301', '307'
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

      def build_http
        uri = URI.parse(configuration[:url])
        http = Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = configuration[:open_timeout] || OPEN_TIMEOUT_DEFAULT # seconds
        http.read_timeout = configuration[:read_timeout] || READ_TIMEOUT_DEFAULT # seconds
        http.use_ssl = (ssl_verify != false)
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless ssl_verify

        logger.debug { "HTTP connection: #{http.inspect}" }

        http
      end

      def get_raw_response_with_retries(location)
        response = Net::HTTP.get_response(URI(location))
        logger.debug { "Response body: #{response.body}" }
        process_response_with_retries(response)
      end

      def endpoint_with_params(endpoint, query_params)
        "#{endpoint}?#{URI::DEFAULT_PARSER.escape(query_params)}"
      end
    end
  end
end
