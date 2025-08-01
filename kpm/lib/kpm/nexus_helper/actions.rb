# frozen_string_literal: true

require_relative 'nexus_api_calls_v2'
require_relative 'github_api_calls'
require_relative 'cloudsmith_api_calls'

module KPM
  module NexusFacade
    class Actions
      DEFAULT_RETRIES = 3
      DEFAULT_CONNECTION_ERRORS = {
        EOFError => 'The remote server dropped the connection',
        Errno::ECONNREFUSED => 'The remote server refused the connection',
        Errno::ECONNRESET => 'The remote server reset the connection',
        Timeout::Error => 'The connection to the remote server timed out',
        Errno::ETIMEDOUT => 'The connection to the remote server timed out',
        SocketError => 'The connection to the remote server could not be established',
        OpenSSL::X509::CertificateError => 'The remote server did not accept the provided SSL certificate',
        OpenSSL::SSL::SSLError => 'The SSL connection to the remote server could not be established',
        Zlib::BufError => 'The remote server replied with an invalid response',
        KPM::NexusFacade::UnexpectedStatusCodeException => nil
      }.freeze

      attr_reader :nexus_api_call

      def initialize(overrides, ssl_verify, logger)
        overrides ||= {}
        overrides[:url] ||= 'https://ossrh-staging-api.central.sonatype.com'
        overrides[:repository] ||= 'releases'

        @logger = logger

        @nexus_api_call = if overrides[:url].start_with?('https://maven.pkg.github.com')
                            GithubApiCalls.new(overrides, ssl_verify, logger)
                          elsif overrides[:url].start_with?('https://dl.cloudsmith.io')
                            CloudsmithApiCalls.new(overrides, ssl_verify, logger)
                          else
                            NexusApiCallsV2.new(overrides, ssl_verify, logger)
                          end
      end

      def pull_artifact(coordinates, destination = nil)
        retry_exceptions("pull_artifact #{coordinates}") { nexus_api_call.pull_artifact(coordinates, destination) }
      end

      def get_artifact_info(coordinates)
        retry_exceptions("get_artifact_info #{coordinates}") { nexus_api_call.get_artifact_info(coordinates) }
      end

      def search_for_artifacts(coordinates)
        retry_exceptions("search_for_artifacts #{coordinates}") { nexus_api_call.search_for_artifacts(coordinates) }
      end

      private

      def retry_exceptions(tag)
        retries = DEFAULT_RETRIES

        begin
          yield
        rescue *DEFAULT_CONNECTION_ERRORS.keys => e
          retries -= 1

          @logger.warn(format('Transient error during %<tag>s, retrying (attempt=%<attempt>d): %<msg>s', tag: tag, attempt: DEFAULT_RETRIES - retries, msg: derived_error_message(DEFAULT_CONNECTION_ERRORS, e)))
          retry unless retries.zero?

          raise
        end
      end

      def derived_error_message(errors, exception)
        key = (errors.keys & exception.class.ancestors).first
        (key ? errors[key] : nil) || exception.message
      end
    end
  end
end
