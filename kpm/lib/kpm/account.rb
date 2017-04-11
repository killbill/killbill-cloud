require 'net/http'
require 'tmpdir'
require 'yaml'
require 'date'

module KPM

  class Account

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
    TMP_DIR = Dir.mktmpdir(TMP_DIR_PEFIX);

    # Created By
    WHO = 'kpm_export_import'

    # safe payment method
    SAFE_PAYMENT_METHOD = '__EXTERNAL_PAYMENT__'
    PLUGIN_NAME_COLUMN = 'plugin_name'

    # fields to remove from the export files
    REMOVE_DATA_FROM = {:accounts => [:name, :address1, :address2, :city, :state_or_providence, :phone, :email],
                       :account_history => [:name, :address1, :address2, :city, :state_or_providence, :phone, :email]}

    DATE_COLUMNS_TO_FIX = ['created_date','updated_date','processing_available_date']

    def initialize(config_file = nil, killbill_api_credentials = nil, killbill_credentials = nil, killbill_url = nil,
                   database_name = nil, database_credentials = nil, logger = nil)
      @killbill_api_key = KILLBILL_API_KEY
      @killbill_api_secrets = KILLBILL_API_SECRET
      @killbill_url = KILLBILL_URL
      @killbill_user = KILLBILL_USER
      @killbill_password = KILLBILL_PASSWORD
      @logger = logger


      set_killbill_options(killbill_api_credentials,killbill_credentials,killbill_url)
      set_database_options(database_name,database_credentials,logger)

      load_config_from_file(config_file)

    end

    def export_data(account_id = nil)

      if account_id === :export.to_s
        raise Interrupt, "\e[91;1mNeed to specify an account id\e[0m"
      end

      export_data = fetch_export_data(account_id)
      export_file = export(export_data)

      if not File.exist?(export_file)
        raise Interrupt, "\e[91;1mAccount id not found\e[0m"
      else
        @logger.info "\e[32mData exported under #{export_file}\e[0m"
      end

      export_file
    end

    def import_data(source_file,reuse_record_id,tenant_record_id, skip_payment_methods)

      @reuse_record_id = reuse_record_id
      @tenant_record_id = tenant_record_id

      if source_file === :import.to_s
        raise Interrupt, "\e[91;1mNeed to specify a file\e[0m"
      end

      if not File.exist?(source_file)
        raise Interrupt, "\e[91;1mNeed to specify a valid file\e[0m"
      end

      sanitize_and_import(source_file, skip_payment_methods)
    end

    private

      # export helpers: fetch_export_data; export; process_export_data; remove_export_data;
      def fetch_export_data(account_id)
        uri = URI("#{@killbill_url}/#{KILLBILL_API_VERSION}/kb/export/#{account_id}")

        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth(@killbill_user,@killbill_password)
        request['X-Killbill-ApiKey'] = @killbill_api_key;
        request['X-Killbill-ApiSecret'] = @killbill_api_secrets;
        request['X-Killbill-CreatedBy'] = WHO;

        response = Net::HTTP.start(uri.host,uri.port) do |http|
          http.request(request)
        end

        if response.to_s.include? 'HTTPUnauthorized'
          raise Interrupt, "User is unauthorized -> \e[93mUser[#{@killbill_user}],password[#{@killbill_password}],api_key[#{@killbill_api_key}],api_secret[#{@killbill_api_secrets}]\e[0m"
        end

        if not response.is_a?(Net::HTTPSuccess)
          raise Interrupt, "\e[91;1mAccount id not found\e[0m"
        end

        response.body
      end

      def export(export_data)
        export_file = TMP_DIR + File::SEPARATOR + 'kbdump'

        open (export_file), 'w' do |io|

          table_name = nil
          cols_names = nil
          export_data.split("\n").each do |line|
            clean_line = process_export_data(line,table_name,cols_names)
            io.puts clean_line
          end

        end

        export_file
      end

      def process_export_data(line_to_process, table_name, cols_names)
        words = line_to_process.strip.split(" ")
        clean_line = line_to_process

        if /--/.match(words[0])

          table_name = words[1]
          cols_names = words[2].strip.split("|")

        elsif not table_name.nil?

          row = []
          cols = line.strip.split("|")
          cols_names.each_with_index { |col_name, index|
            sanitized_value = remove_export_data(table_name,col_name,cols[index])

            row << sanitized_value

          }

          clean_line = row.join("|")
        end

        clean_line
      end

      def remove_export_data(table_name,col_name,value)

        if not REMOVE_DATA_FROM[table_name.to_sym].nil?


          if REMOVE_DATA_FROM[table_name.to_sym].include? col_name.to_sym
            return nil
          end

        end

        value
      end

      # import helpers: sanitize_and_import; import; sanitize; replace_tenant_record_id; replace_account_record_id; replace_boolean;
      # fix_dates; fill_empty_column;
      def sanitize_and_import(source_file, skip_payment_methods)
        tables = Hash.new
        error_importing_data = false

        open (source_file), 'r' do |data|

          rows = nil;
          table_name = nil;
          cols_names = nil;

          data.each_line do |line|
            words = line.strip.split(" ")

            if /--/.match(words[0])
              if not table_name.nil?
                if not @reuse_record_id
                  cols_names.shift
                end

                tables[table_name] = { :col_names => cols_names, :rows => rows};
              end

              table_name = words[1]
              cols_names = words[2].strip.split("|")

              rows = []
            elsif not table_name.nil?
              row = process_import_data(line, table_name,cols_names, skip_payment_methods, rows)

              next if row.nil?

              rows.push(row)
            else
              error_importing_data = true
              break
            end
          end

          if tables.empty?
            error_importing_data = true
          end

          if not ( table_name.nil? || error_importing_data )
            if not @reuse_record_id
              cols_names.shift
            end

            tables[table_name] = { :col_names => cols_names, :rows => rows};
          end

        end

        if not error_importing_data
          import(tables)
        else
          raise Interrupt, "\e[91;1mData on #{source_file} is invalid\e[0m\n\n"
        end

      end

      def process_import_data(line, table_name, cols_names, skip_payment_methods, rows)
        cols = line.strip.split("|")

        if cols_names.size != cols.size
          return nil
        end

        row = []

        cols_names.each_with_index do |col_name, index|
          sanitized_value = sanitize(table_name,col_name,cols[index], skip_payment_methods)

          if not sanitized_value.nil?
            row << sanitized_value
          end
        end

        if table_name == 'payment_methods' && skip_payment_methods
          if rows.size > 0
            return nil
          end
        end

        return row
      end

      def import(tables)
        record_id = nil;
        statements = Database.generate_insert_statement(tables)
        statements.each do |statement|
          response = Database.execute_insert_statement(statement[:table_name],statement[:query], statement[:qty_to_insert],record_id)

          if statement[:table_name] == 'accounts' && response.is_a?(String)
            record_id = {:variable => '@account_record_id', :value => response}
          end

          if response === false
            break
          end
        end

      end

      def sanitize(table_name,column_name,value,skip_payment_methods)
        sanitized_value = replace_boolean(value)
        sanitized_value = fill_empty_column(sanitized_value)

        if table_name == 'payment_methods' && skip_payment_methods && column_name == PLUGIN_NAME_COLUMN
          sanitized_value = SAFE_PAYMENT_METHOD
        end

        if DATE_COLUMNS_TO_FIX.include? column_name
          sanitized_value = fix_dates(sanitized_value)
        end

        if not @tenant_record_id.nil?
          sanitized_value = replace_tenant_record_id(table_name,column_name,sanitized_value)
        end

        if not @reuse_record_id
          sanitized_value = replace_account_record_id(table_name,column_name,sanitized_value)
        end

        sanitized_value
      end

      def replace_tenant_record_id(table_name,column_name,value)
        if column_name == 'tenant_record_id'
          return @tenant_record_id
        end

        if column_name == 'search_key2' && table_name == 'bus_ext_events_history'
          return @tenant_record_id
        end

        if column_name == 'search_key2' && table_name == 'bus_events_history'
          return @tenant_record_id
        end

        value
      end

      def replace_account_record_id(table_name,column_name,value)

        if column_name == 'account_record_id'

          return :@account_record_id
        end

        if column_name == 'record_id'
          return nil
        end

        if column_name == 'target_record_id'

          if table_name == 'account_history'
            return :@account_record_id
          end
        end

        if column_name == 'search_key1' && table_name == 'bus_ext_events_history'
            return :@account_record_id
        end

        if column_name == 'search_key1' && table_name == 'bus_events_history'
          return :@account_record_id
        end

        value

      end

      def replace_boolean(value)
        if value.to_s === 'true'
          return 1
        elsif value.to_s === 'false'
          return 0
        else
          return value
        end
      end

      def fix_dates(value)
        dt = DateTime.parse(value)
        return dt.strftime('%F %T').to_s
      end

      def fill_empty_column(value)
        if value.to_s.strip.empty?
          return :DEFAULT
        else
          return value
        end
      end

      # helper methods that set up killbill and database options: load_config_from_file; set_config; set_database_options;
      # set_killbill_options;
      def load_config_from_file(config_file)

        set_config(config_file)

        if not @config.nil?
          config_killbill = @config['killbill']

          if not config_killbill.nil?
            set_killbill_options([config_killbill['api_key'],config_killbill['api_secret']],
                                 [config_killbill['user'],config_killbill['password']],
                                 "http://#{config_killbill['host']}:#{config_killbill['port']}")
          end

          config_db = @config['database']

          if not config_db.nil?
            set_database_options(config_db['database'],
                                 [config_db['username'],config_db['password']],
                                 @logger)

          end
        end
      end

      def set_config(config_file = nil)
        @config = nil

        if not config_file.nil?
          if not Dir[config_file][0].nil?
            @config = YAML::load_file(config_file)
          end
        end

      end

      def set_database_options(database_name = nil, database_credentials = nil, logger)

        Database.set_logger(logger)

        if not database_credentials.nil?
          Database.set_credentials(database_credentials[0],database_credentials[1])
        end

        if not database_name.nil?
          Database.set_database_name(database_name)
        end
      end

      def set_killbill_options(killbill_api_credentials, killbill_credentials, killbill_url)

        if not killbill_api_credentials.nil?

          @killbill_api_key = killbill_api_credentials[0]
          @killbill_api_secrets = killbill_api_credentials[1]

        end

        if not killbill_credentials.nil?

          @killbill_user = killbill_credentials[0]
          @killbill_password = killbill_credentials[1]

        end

        if not killbill_url.nil?

          @killbill_url = killbill_url

        end
      end

  end

end