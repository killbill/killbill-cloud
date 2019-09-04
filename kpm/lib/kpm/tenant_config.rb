# frozen_string_literal: true

require 'tmpdir'
require 'json'
require 'killbill_client'

module KPM
  class TenantConfig
    # Killbill server
    KILLBILL_HOST = ENV['KILLBILL_HOST'] || '127.0.0.1'
    KILLBILL_URL = 'http://'.concat(KILLBILL_HOST).concat(':8080')
    KILLBILL_API_VERSION = '1.0'

    # USER/PWD
    KILLBILL_USER = ENV['KILLBILL_USER'] || 'admin'
    KILLBILL_PASSWORD = ENV['KILLBILL_PASSWORD'] || 'password'

    # TENANT KEY
    KILLBILL_API_KEY = ENV['KILLBILL_API_KEY'] || 'bob'
    KILLBILL_API_SECRET = ENV['KILLBILL_API_SECRET'] || 'lazar'

    # Temporary directory
    TMP_DIR_PEFIX = 'killbill'
    TMP_DIR = Dir.mktmpdir(TMP_DIR_PEFIX)

    # Tenant key prefixes
    KEY_PREFIXES = %w[PLUGIN_CONFIG PUSH_NOTIFICATION_CB PER_TENANT_CONFIG
                      PLUGIN_PAYMENT_STATE_MACHINE CATALOG OVERDUE_CONFIG
                      INVOICE_TRANSLATION CATALOG_TRANSLATION INVOICE_TEMPLATE INVOICE_MP_TEMPLATE].freeze

    def initialize(killbill_api_credentials = nil, killbill_credentials = nil, killbill_url = nil, logger = nil)
      @killbill_api_key = KILLBILL_API_KEY
      @killbill_api_secrets = KILLBILL_API_SECRET
      @killbill_url = KILLBILL_URL
      @killbill_user = KILLBILL_USER
      @killbill_password = KILLBILL_PASSWORD
      @logger = logger

      set_killbill_options(killbill_api_credentials, killbill_credentials, killbill_url)
    end

    def export(key_prefix = nil)
      export_data = fetch_export_data(key_prefix)

      raise Interrupt, 'key_prefix not found' if export_data.empty?

      export_file = store_into_file(export_data)

      if !File.exist?(export_file)
        raise Interrupt, 'key_prefix not found'
      else
        @logger.info "\e[32mData exported under #{export_file}\e[0m"
      end

      export_file
    end

    private

    def fetch_export_data(key_prefix)
      tenant_config = []
      pefixes = key_prefix.nil? ? KEY_PREFIXES : [key_prefix]

      pefixes.each do |prefix|
        config_data = call_client(prefix)

        if !config_data.empty?
          config_data.each { |data| tenant_config << data }
          @logger.info "Data for key prefix \e[1m#{prefix}\e[0m was \e[1mfound and is ready to be exported\e[0m."
        else
          @logger.info "Data for key prefix \e[1m#{prefix}\e[0m was \e[31mnot found\e[0m."
        end
      end

      tenant_config
    end

    def call_client(key_prefix)
      KillBillClient.url = @killbill_url
      options = {
        username: @killbill_user,
        password: @killbill_password,
        api_key: @killbill_api_key,
        api_secret: @killbill_api_secrets
      }

      tenant_config_data = KillBillClient::Model::Tenant.search_tenant_config(key_prefix, options)

      tenant_config_data
    end

    def store_into_file(export_data)
      export_file = TMP_DIR + File::SEPARATOR + 'kbdump'

      File.open(export_file, 'w') { |io| io.puts export_data.to_json }

      export_file
    end

    def set_killbill_options(killbill_api_credentials, killbill_credentials, killbill_url)
      unless killbill_api_credentials.nil?

        @killbill_api_key = killbill_api_credentials[0]
        @killbill_api_secrets = killbill_api_credentials[1]

      end

      unless killbill_credentials.nil?

        @killbill_user = killbill_credentials[0]
        @killbill_password = killbill_credentials[1]

      end

      @killbill_url = killbill_url unless killbill_url.nil?
    end
  end
end
