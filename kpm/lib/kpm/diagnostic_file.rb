require 'yaml'
require 'logger'
require 'tmpdir'
require 'rubygems'
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

      TENANT_FILE     = 'tenant_config'
      SYSTEM_FILE     = 'system_configuration'
      ACCOUNT_FILE    = 'account_data'

      TODAY_DATE      = Date.today.strftime('%m-%d-%y')
      ZIP_FILE        = 'killbill-diagnostics-' + TODAY_DATE + '.zip'
      ZIP_LOG_FILE    = 'logs.zip'

      @@catalina_base

      def export_data(account_id, config_file = nil, log_dir = nil)

        puts TODAY_DATE

        set_config(config_file)

        tenant_export_file  = get_tenant_config
        system_export_file  = get_system_config(config_file)
        account_export_file = get_account_data(config_file, account_id)
        log_files           = get_log_files(log_dir)

        if File.exist?(account_export_file) && File.exist?(system_export_file) && File.exist?(tenant_export_file)


          zip_file_name = TMP_DIR + File::Separator + ZIP_FILE

          Zip::File.open(zip_file_name, Zip::File::CREATE) do |zipFile|

            zipFile.add(TENANT_FILE,  tenant_export_file)
            zipFile.add(SYSTEM_FILE,  system_export_file)
            zipFile.add(ACCOUNT_FILE, account_export_file)
            zipFile.add(ZIP_LOG_FILE, log_files)

          end

          File.delete(tenant_export_file)
          File.delete(system_export_file)
          File.delete(account_export_file)
          File.delete(log_files)

        logger.info "\e[32mDiagnostic data exported under #{zip_file_name} \e[0m"

        else
          raise Interrupt, 'Account id or configuration file not found'
        end

      end

      # Private methods

      private

      def get_tenant_config

        logger.info 'Retrieving tenant configuration'

        kb_api_credentials = [get_config('killbill', 'api_key'), get_config('killbill','api_secret')]
        kb_credentials = [get_config('killbill', 'user'), get_config('killbill','password')]
        kb_url = 'http://' + get_config('killbill', 'host').to_s + ':' + get_config('killbill','port').to_s

        tenant_config = KPM::TenantConfig.new(kb_api_credentials, kb_credentials, kb_url, logger_suppressed)
        export_file = tenant_config.export

        final = TMP_DIR + File::Separator + TENANT_FILE
        FileUtils.cp(export_file, final)

        FileUtils.rm_r(export_file.gsub(export_file.split('/').last, ''))

        final
      end

      def get_system_config(config_file)

        logger.info 'Retrieving system configuration'

        system = KPM::System.new
        export_data = system.information(nil, true, config_file, nil, nil)

        get_system_catalina_base(export_data)

        export_file = TMP_DIR + File::SEPARATOR + SYSTEM_FILE
        File.open(export_file, 'w') { |io| io.puts export_data }

        export_file
      end


      def get_account_data(config_file, account_id)

        logger.info 'Retrieving account data for id: ' + account_id


        account = KPM::Account.new(config_file, nil, nil, nil, nil,
                                   nil,nil,nil, logger_suppressed)
        export_file = account.export_data(account_id)


        final  = TMP_DIR + File::Separator + ACCOUNT_FILE
        FileUtils.cp(export_file, final)

        FileUtils.rm_r(export_file.gsub(export_file.split('/').last, ''))

        final
      end

      def get_log_files(log_dir)

        logger.info 'Collecting log files'

        log_base = log_dir || @@catalina_base
        log_items = Dir.glob(log_base + File::Separator + 'logs' + File::Separator + '*')


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
        @@catalina_base = system_json['java_system_information']['catalina.base']['value']

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

      def logger
        logger       = ::Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger
      end

      def logger_suppressed
        logger_s       = ::Logger.new(STDOUT)
        logger_s.level = Logger::WARN
        logger_s
      end

    end
end