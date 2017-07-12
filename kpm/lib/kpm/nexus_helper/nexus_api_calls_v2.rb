require 'httpclient'

module KPM
  module NexusFacade

    class UnexpectedStatusCodeException < StandardError
      def initialize(code)
        @code = code
      end

      def  message
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
      PULL_ARTIFACT_ENDPOINT = 'service/local/artifact/maven/redirect'
      GET_ARTIFACT_INFO_ENDPOINT = 'service/local/artifact/maven/resolve'
      SEARCH_FOR_ARTIFACT_ENDPOINT = 'service/local/data_index'

      attr_reader :version
      attr_reader :configuration
      attr_reader :ssl_verify

      def initialize(configuration, ssl_verify)
        @configuration = configuration
        @ssl_verify = ssl_verify
      end

      def search_for_artifacts(coordinates)
        http_client = get_client
        url = get_url(SEARCH_FOR_ARTIFACT_ENDPOINT, configuration)
        group_id, artifact_id = coordinates.split(":")
        response = http_client.get(url, :query => {:g => group_id, :a => artifact_id})

        case response.status
          when 200
            return response.content
          else
            raise UnexpectedStatusCodeException.new(response.status)
        end
      end

      def get_artifact_info(coordinates)
        http_client = get_client
        query_params = get_query_params(coordinates)
        url = get_url(GET_ARTIFACT_INFO_ENDPOINT, configuration)
        response = http_client.get(url,query_params)

        case response.status
          when 200
            return response.content
          when 404
            raise StandardError.new('The artifact you requested information for could not be found. Please ensure it exists inside the Nexus.')
          when 503
            raise StandardError.new('Could not connect to Nexus. Please ensure the url you are using is reachable.')
          else
            raise UnexpectedStatusCodeException.new(response.status)
        end
      end

      def pull_artifact(coordinates ,destination)
        file_name = get_file_name(coordinates)
        destination = File.join(File.expand_path(destination || "."), file_name)
        http_client = get_client
        query_params = get_query_params(coordinates)
        url = get_url(PULL_ARTIFACT_ENDPOINT, configuration)
        response = http_client.get(url,query_params)

        case response.status
          when 301, 307
            # Follow redirect and stream in chunks.
            File.open(destination, "wb") do |io|
              http_client.get(response.content.gsub(/If you are not automatically redirected use this url: /, "")) do |chunk|
                io.write(chunk)
              end
            end
          when 404
            raise StandardError.new('The artifact you requested information for could not be found. Please ensure it exists inside the Nexus.')
          else
            raise UnexpectedStatusCodeException.new(response.status)
        end
        {
            :file_name => file_name,
            :file_path => File.expand_path(destination),
            :version   => version,
            :size      => File.size(File.expand_path(destination))
        }
      end

      private
        def parse_coordinates(coordinates)
          split_coordinates = coordinates.split(":")
          if(split_coordinates.size < 3 or split_coordinates.size > 5)
            raise ArtifactMalformedException
          end

          artifact = Hash.new

          artifact[:group_id] = split_coordinates[0]
          artifact[:artifact_id] = split_coordinates[1]
          artifact[:extension] = split_coordinates.size > 3 ? split_coordinates[2] : "jar"
          artifact[:classifier] = split_coordinates.size > 4 ? split_coordinates[3] : nil
          artifact[:version] = split_coordinates[-1]

          artifact[:version].upcase! if version == "latest"

          return artifact
        end

        def get_file_name(coordinates)
          artifact = parse_coordinates(coordinates)

          if artifact[:version].casecmp("latest")
             artifact[:version] = REXML::Document.new(get_artifact_info(coordinates)).elements["//version"].text
          end

          if artifact[:classifier].nil?
            "#{artifact[:artifact_id]}-#{artifact[:version]}.#{artifact[:extension]}"
          else
            "#{artifact[:artifact_id]}-#{artifact[:version]}-#{artifact[:classifier]}.#{artifact[:extension]}"
          end
        end

        def get_query_params(coordinates)
          artifact = parse_coordinates(coordinates)
          @version = artifact[:version]
          query = {:g => artifact[:group_id], :a => artifact[:artifact_id], :e => artifact[:extension], :v => version, :r => configuration[:repository]}
          query.merge!({:c => artifact[:classifier]}) unless artifact[:classifier].nil?
          query
        end

        def get_client
          client = HTTPClient.new
          client.send_timeout = 6000
          client.receive_timeout = 6000
          client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE unless ssl_verify
          client
        end

        def get_url(endpoint,configuration)
          File.join(configuration[:url], endpoint)
        end

    end
  end
end