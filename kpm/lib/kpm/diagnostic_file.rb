require 'yaml'
require 'tmpdir'
require 'zip'
require 'json'
require 'fileutils'
require 'date'


module KPM

    class DiagnosticFile

      # Temporary directory
      TMP_DIR_PREFIX  = 'killbill-diagnostics-'
      TMP_DIR         = Dir.mktmpdir(TMP_DIR_PREFIX)
      TMP_LOGS_DIR    = TMP_DIR + File::Separator + 'logs'

      TENANT_FILE     = 'tenant_config.data'
      SYSTEM_FILE     = 'system_configuration.data'
      ACCOUNT_FILE    = 'account.data'

      TODAY_DATE      = Date.today.strftime('%m-%d-%y')
      ZIP_FILE        = 'killbill-diagnostics-' + TODAY_DATE + '.zip'
      ZIP_LOG_FILE    = 'logs.zip'

      def initialize(config_file = nil, killbill_api_credentials = nil, killbill_credentials = nil, killbill_url = nil,
                     database_name = nil, database_credentials = nil, database_host = nil, kaui_web_path = nil,
                     killbill_web_path = nil, logger = nil)
        @killbill_api_credentials = killbill_api_credentials
        @killbill_credentials = killbill_credentials
        @killbill_url = killbill_url
        @database_name = database_name
        @database_credentials = database_credentials
        @database_host = database_host
        @config_file = config_file
        @kaui_web_path = kaui_web_path;
        @killbill_web_path = killbill_web_path;
        @logger = logger
        @original_logger_level = logger.level;
        @catalina_base = nil
      end

      def export_data(account_id = nil, log_dir = nil)
        set_config(@config_file)

        tenant_export_file  = get_tenant_config
        system_export_file  = get_system_config
        account_export_file = get_account_data(account_id) unless account_id.nil?
        log_files           = get_log_files(log_dir)

        if File.exist?(system_export_file) && File.exist?(tenant_export_file)


          zip_file_name = TMP_DIR + File::Separator + ZIP_FILE

          Zip::File.open(zip_file_name, Zip::File::CREATE) do |zipFile|

            zipFile.add(TENANT_FILE,  tenant_export_file)
            zipFile.add(SYSTEM_FILE,  system_export_file)
            zipFile.add(ACCOUNT_FILE, account_export_file) unless account_id.nil?
            zipFile.add(ZIP_LOG_FILE, log_files)

          end

          @logger.info "\e[32mDiagnostic data exported under #{zip_file_name} \e[0m"

        else
          raise Interrupt, 'Account id or configuration file not found'
        end

      end

      # Private methods

      private

      def get_tenant_config

        @logger.info 'Retrieving tenant configuration'
        # this suppress the message of where it put the account file, this is to avoid confusion
        @logger.level = Logger::WARN

        @killbill_api_credentials ||= [get_config('killbill', 'api_key'), get_config('killbill','api_secret')] unless @config_file.nil?
        @killbill_credentials ||= [get_config('killbill', 'user'), get_config('killbill','password')] unless @config_file.nil?
        @killbill_url ||= 'http://' + get_config('killbill', 'host').to_s + ':' + get_config('killbill','port').to_s unless @config_file.nil?

        tenant_config = KPM::TenantConfig.new(@killbill_api_credentials,
                                              @killbill_credentials, @killbill_url, @logger)
        export_file = tenant_config.export

        final = TMP_DIR + File::Separator + TENANT_FILE
        FileUtils.move(export_file, final)
        @logger.level = @original_logger_level

        final
      end

      def get_system_config

        @logger.info 'Retrieving system configuration'
        system = KPM::System.new
        export_data = system.information(nil, true, @config_file, @kaui_web_path, @killbill_web_path)

        get_system_catalina_base(export_data)

        export_file = TMP_DIR + File::SEPARATOR + SYSTEM_FILE
        File.open(export_file, 'w') { |io| io.puts export_data }
        export_file
      end


      def get_account_data(account_id)

        @logger.info 'Retrieving account data for id: ' + account_id
        # this suppress the message of where it put the account file, this is to avoid confusion
        @logger.level = Logger::WARN

        account = KPM::Account.new(@config_file, @killbill_api_credentials, @killbill_credentials,
                                   @killbill_url, @database_name,
                                   @database_credentials,@database_host,nil, @logger)
        export_file = account.export_data(account_id)

        final  = TMP_DIR + File::Separator + ACCOUNT_FILE
        FileUtils.move(export_file, final)
        @logger.level = @original_logger_level
        final
      end

      def get_log_files(log_dir)

        @logger.info 'Collecting log files'
        log_base = log_dir || @catalina_base
        log_items = Dir.glob(log_base + File::Separator + '*')

        zip_file_name = TMP_DIR + File::Separator + ZIP_LOG_FILE

        Zip::File.open(zip_file_name, Zip::File::CREATE) do |zipFile|

          log_items.each do |file|
            name = file.split('/').last
            zipFile.add(name, file)
          end

        end

        zip_file_name
      end

      # Helpers

      def get_system_catalina_base(export_data)
        system_json = JSON.parse(export_data)
        @catalina_base = system_json['java_system_information']['catalina.base']['value']
        @catalina_base = @catalina_base + File::Separator + 'logs'

      end

      # Utils

      def get_config(parent, child)
        item = nil;

        if not @config.nil?

          config_parent = @config[parent]

          if not config_parent.nil?
            item =config_parent[child]
          end

        end

        item
      end

      def set_config(config_file = nil)
        @config = nil

        if not config_file.nil?
          if not Dir[config_file][0].nil?
            @config = YAML::load_file(config_file)
          end
        end

      end

    end
end