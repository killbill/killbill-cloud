require 'net/http'
require 'tmpdir'
require 'yaml'
require 'date'
require 'securerandom'

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
    REMOVE_DATA_FROM = {:accounts => [:name, :address1, :address2, :city, :state_or_province, :phone, :email],
                       :account_history => [:name, :address1, :address2, :city, :state_or_province, :phone, :email]}

    DATE_COLUMNS_TO_FIX = ['created_date','updated_date','processing_available_date','effective_date',
                           'boot_date','start_timestamp','last_access_time','payment_date','original_created_date',
                           'last_sys_update_date','charged_through_date','bundle_start_date','start_date']

    # round trip constants duplicate record
    ROUND_TRIP_EXPORT_IMPORT_MAP = {:accounts => {:id => :accounts_id, :external_key => :accounts_id}, :all => {:account_id => :accounts_id},
                                    :account_history => {:id => :account_history_id, :external_key => :accounts_id, :payment_method_id => :payment_methods_id},
                                    :account_emails => {:id => :account_emails_id}, :account_email_history => {:id => :account_email_history_id},
                                    :subscription_events => {:id => :subscription_events_id},:subscriptions => {:id => :subscriptions_id},
                                    :bundles => {:id => :bundles_id},:blocking_states => {:id => :blocking_states_id, :blockable_id => nil},
                                    :invoice_items => {:id => :invoice_items_id, :child_account_id => nil, :invoice_id => :invoices_id, :bundle_id => :bundles_id, :subscription_id => :subscriptions_id },
                                    :invoices => {:id => :invoices_id},
                                    :invoice_payments => {:id => :invoice_payments_id, :invoice_id => :invoices_id, :payment_id => :payments_id},
                                    :invoice_parent_children => {:id => :invoice_parent_children_id, :parent_invoice_id  => nil, :child_invoice_id  => nil, :child_account_id => nil},
                                    :payment_attempts => {:id => :payment_attempts_id, :payment_method_id  => :payment_methods_id, :transaction_id   => :payment_transactions_id},
                                    :payment_attempt_history => {:id => :payment_attempt_history_id, :payment_method_id  => :payment_methods_id, :transaction_id   => :payment_transactions_id},
                                    :payment_methods => {:id => :payment_methods_id, :external_key => :generate},:payment_method_history => {:id => :payment_method_history_id},
                                    :payments => {:id => :payments_id, :payment_method_id  => :payment_methods_id},
                                    :payment_history => {:id => :payment_history_id, :payment_method_id  => :payment_methods_id},
                                    :payment_transactions => {:id => :payment_transactions_id, :payment_id   => :payments_id},
                                    :payment_transaction_history => {:id => :payment_transaction_history_id, :payment_id   => :payments_id},
                                    :_invoice_payment_control_plugin_auto_pay_off  => {:payment_method_id => :payment_methods_id, :payment_id   => :payments_id},
                                    :rolled_up_usage => {:id => :rolled_up_usage_id, :subscription_id  => :subscriptions_id, :tracking_id => nil},
                                    :custom_fields  => {:id => :custom_fields_id},:custom_field_history  => {:id => :custom_field_history_id},
                                    :tag_definitions => {:id => :tag_definitions_id},:tag_definition_history => {:id => :tag_definition_history_id},
                                    :tags => {:id => :tags_id, :object_id => nil},
                                    :tag_history => {:id => :tag_history_id, :object_id => nil},
                                    :audit_log => {:id => :audit_log_id}
    }
    
    #delimeters to sniff
    DELIMITERS = [',','|']
    DEFAULT_DELIMITER = "|"

    def initialize(config_file = nil, killbill_api_credentials = nil, killbill_credentials = nil, killbill_url = nil,
                   database_name = nil, database_credentials = nil, data_delimiter = nil, logger = nil)
      @killbill_api_key = KILLBILL_API_KEY
      @killbill_api_secrets = KILLBILL_API_SECRET
      @killbill_url = KILLBILL_URL
      @killbill_user = KILLBILL_USER
      @killbill_password = KILLBILL_PASSWORD
      @delimiter = data_delimiter || DEFAULT_DELIMITER
      @logger = logger
      @tables_id = Hash.new


      set_killbill_options(killbill_api_credentials,killbill_credentials,killbill_url)
      set_database_options(database_name,database_credentials,logger)

      load_config_from_file(config_file)

    end

    def export_data(account_id = nil)

      if account_id === :export.to_s
        raise Interrupt, 'Need to specify an account id'
      end

      export_data = fetch_export_data(account_id)
      export_file = export(export_data)

      if not File.exist?(export_file)
        raise Interrupt, 'Account id not found'
      else
        @logger.info "\e[32mData exported under #{export_file}\e[0m"
      end

      export_file
    end

    def import_data(source_file,tenant_record_id, skip_payment_methods, round_trip_export_import = false, generate_record_id = false)

      @generate_record_id = generate_record_id
      @tenant_record_id = tenant_record_id
      @round_trip_export_import = round_trip_export_import

      if source_file === :import.to_s
        raise Interrupt, 'Need to specify a file'
      end

      if not File.exist?(source_file)
        raise Interrupt, 'Need to specify a valid file'
      end

      @delimiter = sniff_delimiter(source_file) || @delimiter 

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
          raise Interrupt, 'Account id not found'
        end

        response.body
      end

      def export(export_data)
        export_file = TMP_DIR + File::SEPARATOR + 'kbdump'

        open (export_file), 'w' do |io|

          table_name = nil
          cols_names = nil
          export_data.split("\n").each do |line|
            words = line.strip.split(" ")
            clean_line = line
            if not /--/.match(words[0]).nil?
              table_name = words[1]
              cols_names = words[2].strip.split(@delimiter)
            elsif not table_name.nil?
              clean_line = process_export_data(line,table_name,cols_names)
            end
            io.puts clean_line

          end

        end

        export_file
      end

      def process_export_data(line_to_process, table_name, cols_names)
        clean_line = line_to_process

        row = []
        cols = clean_line.strip.split(@delimiter)
        cols_names.each_with_index { |col_name, index|
          sanitized_value = remove_export_data(table_name,col_name,cols[index])

          row << sanitized_value

        }

        clean_line = row.join(@delimiter)

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
                if @generate_record_id
                  cols_names.shift
                end

                tables[table_name] = { :col_names => cols_names, :rows => rows};
              end

              table_name = words[1]
              cols_names = words[2].strip.split(@delimiter)

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

          if not ( table_name.nil? || error_importing_data )
            if @generate_record_id
              cols_names.shift
            end

            tables[table_name] = { :col_names => cols_names, :rows => rows};
          end

          if tables.empty?
            error_importing_data = true
          end
        end

        if not error_importing_data
          import(tables)
        else
          raise Interrupt, "Data on #{source_file} is invalid"
        end

      end

      def process_import_data(line, table_name, cols_names, skip_payment_methods, rows)
        cols = line.strip.split(@delimiter)

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
          response = Database.execute_insert_statement(statement[:table_name],statement[:query], statement[:qty_to_insert], statement[:table_data],record_id)

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

        if @generate_record_id
          sanitized_value = replace_account_record_id(table_name,column_name,sanitized_value)
        end

        if @round_trip_export_import
          sanitized_value = replace_uuid(table_name,column_name,sanitized_value)
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
        if !value.equal?(:DEFAULT)
          
          dt = DateTime.parse(value)
          return dt.strftime('%F %T').to_s
        
        end
        
        value
      end

      def fill_empty_column(value)
        if value.to_s.strip.empty?
          return :DEFAULT
        else
          return value
        end
      end

      def replace_uuid(table_name,column_name,value)

        if column_name == 'id'
          @tables_id["#{table_name}_id"] = SecureRandom.uuid
        end

        if ROUND_TRIP_EXPORT_IMPORT_MAP[table_name.to_sym] && ROUND_TRIP_EXPORT_IMPORT_MAP[table_name.to_sym][column_name.to_sym]
          key = ROUND_TRIP_EXPORT_IMPORT_MAP[table_name.to_sym][column_name.to_sym]

          if key.equal?(:generate)
            new_value = SecureRandom.uuid
          else
            new_value = @tables_id[key.to_s]
          end

          if new_value.nil?
            new_value = SecureRandom.uuid
            @tables_id[key.to_s] = new_value
          end
          return new_value
        end

        if not ROUND_TRIP_EXPORT_IMPORT_MAP[:all][column_name.to_sym].nil?
          key = ROUND_TRIP_EXPORT_IMPORT_MAP[:all][column_name.to_sym]
          new_value = @tables_id[key.to_s]

          return new_value
        end

        value
      end

      def sniff_delimiter(file)
        
        return nil if File.size?(file).nil?
        
        first_line = File.open(file) {|f| f.readline}
        
        return nil if first_line.nil?
        
        sniff = {}
        
        DELIMITERS.each do |delimiter|
          sniff[delimiter] = first_line.count(delimiter)
        end
        
        sniff = sniff.sort {|a,b| b[1]<=>a[1]}
        sniff.size > 0 ? sniff[0][0] : nil
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

        Database.set_mysql_command_line
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