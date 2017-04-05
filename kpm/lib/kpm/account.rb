require 'net/http'
require 'tmpdir'
require 'yaml'

module KPM

  class Account

    # Killbill server
    KILLBILL_HOST = '127.0.0.1'
    KILLBILL_URL = 'http://'.concat(KILLBILL_HOST).concat(':8080')
    KILLBILL_API_VERSION = '1.0'

    # USER/PWD
    KILLBILL_USER = 'admin'
    KILLBILL_PASSWORD = 'password'

    # TENANT KEY
    KILLBILL_API_KEY = 'bob'
    KILLBILL_API_SECRET = 'lazar'

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

    def initialize(config_file = nil, killbill_api_credentials = nil, killbill_credentials = nil, killbill_url = nil, database = nil)
      @killbill_api_key = KILLBILL_API_KEY
      @killbill_api_secrets = KILLBILL_API_SECRET
      @killbill_url = KILLBILL_URL
      @killbill_user = KILLBILL_USER
      @killbill_password = KILLBILL_PASSWORD

      set_config(config_file)

      if not @config.nil?
        config_killbill = @config['killbill']

        if not config_killbill.nil?
          @killbill_api_key = config_killbill['api_key']
          @killbill_api_secrets = config_killbill['api_secret']
          @killbill_url = "http://#{config_killbill['host']}:#{config_killbill['port']}"
          @killbill_user = config_killbill['user']
          @killbill_password = config_killbill['password']
        end

        config_db = @config['database']

        if not config_db.nil?
          Database.set_configuration(config_db['database'], config_db['username'], config_db['password'])
        end
      end

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

      if not database.nil?

        Database.set_configuration(database[0], database[1], database[2])

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

    def export_data(account_id = nil)

      if account_id === :export.to_s
        puts "\e[91;1mNeed to specify an account id\e[0m\n\n"
        Dir.rmdir(TMP_DIR)
        return
      end

      uri = URI("#{@killbill_url}/#{KILLBILL_API_VERSION}/kb/export/#{account_id}")
      export_file = TMP_DIR + File::SEPARATOR + 'kbdump'

      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(@killbill_user,@killbill_password)
      request['X-Killbill-ApiKey'] = @killbill_api_key;
      request['X-Killbill-ApiSecret'] = @killbill_api_secrets;
      request['X-Killbill-CreatedBy'] = WHO;

      response = Net::HTTP.start(uri.host,uri.port) do |http|
        http.request(request)
      end

      if response.to_s.include? 'HTTPUnauthorized'
        raise Interrupt, "User is unauthorized -> \e[93mUser[#{@killbill_user}],password[#{@killbill_password}],api_key[#{@killbill_api_key}],api_secret[#{@killbill_api_secrets}]"
      end

      open (export_file), 'w' do |io|
        #io.write response.body
        table_name = nil
        cols_names = nil
        response.body.split("\n").each do |line|
          words = line.strip.split(" ")
          clean_line = line

          if /--/.match(words[0])

            table_name = words[1]
            cols_names = words[2].strip.split("|")

          elsif not table_name.nil?

            row = []
            cols = line.strip.split("|")
            cols_names.each_with_index { |col_name, index|
              sanitized_value = sanitize_export(table_name,col_name,cols[index])

              row << sanitized_value

            }

            clean_line = row.join("|")
          end

          io.puts clean_line
        end

      end if response.is_a?(Net::HTTPSuccess)

      if not File.exist?(export_file)
        puts "\e[91;1mAccount id not found\e[0m\n\n"
        Dir.rmdir(TMP_DIR)
      else
        puts "\e[32mData exported under #{export_file}\e[0m\n\n"
      end

      export_file
    end

    def sanitize_export(table_name,col_name,value)

      if not REMOVE_DATA_FROM[table_name.to_sym].nil?


        if REMOVE_DATA_FROM[table_name.to_sym].include? col_name.to_sym
          return nil
        end

      end

      value
    end

    def import_data(source_file,account_record_id,tenant_record_id, skip_payment_methods)

      @account_record_id = account_record_id
      @tenant_record_id = tenant_record_id

      if source_file === :import.to_s
        puts "\e[91;1mNeed to specify a file\e[0m\n\n"
        Dir.rmdir(TMP_DIR)
        return
      end

      if not File.exist?(source_file)
        puts "\e[91;1mNeed to specify a valid file\e[0m\n\n"
        Dir.rmdir(TMP_DIR)
        return
      end

      sanitize_and_import(source_file, skip_payment_methods)
    end

    def sanitize_and_import(source_file, skip_payment_methods)
      tables = Hash.new
      error_importing_data = false
      safe_payment_method_found = false

      open (source_file), 'r' do |data|

        rows = nil;
        table_name = nil;
        cols_names = nil;

        data.each_line do |line|
          words = line.strip.split(" ")

          if /--/.match(words[0])
            if not table_name.nil?
              tables[table_name] = rows;
            end

            table_name = words[1]
            cols_names = words[2].strip.split("|")

            rows = []
          elsif not table_name.nil?

            cols = line.strip.split("|")

            if cols_names.size != cols.size
              error_importing_data = true
              break
            end

            row = Hash.new

            cols_names.each_with_index { |col_name, index|
              sanitized_value = sanitize(table_name,col_name,cols[index])

              if not sanitized_value.nil?
                row[col_name] = sanitized_value
              end

            }

            ok_to_push = false

            if table_name == 'payment_methods' && skip_payment_methods
              row[PLUGIN_NAME_COLUMN] = SAFE_PAYMENT_METHOD

              if not safe_payment_method_found

                safe_payment_method_found = true
                ok_to_push = true
              else
                of_to_push = false
              end
            else
              ok_to_push = true
            end

            if ok_to_push
              rows.push(row)
            end

          else
            error_importing_data = true
            break
          end
        end

        if tables.empty?
          error_importing_data = true
        end

        if not ( table_name.nil? || error_importing_data )
          tables[table_name] = rows;
        end

      end

      if not error_importing_data
        import(tables)
      else
        puts "\e[91;1mData on #{source_file} is invalid\e[0m\n\n"
      end

    end

    def import(tables)
      statements = Database.generate_insert_statement(tables)
      response = nil

      statements.each_key do |table_name|
        statements_completed = 0
        statements[table_name].each do |statement|
          response = Database.execute_insert_statement(table_name,statement)

          if response === false
            break
          else
            statements_completed += 1
          end
        end

        puts "\e[32m#{statements_completed} inserts completed of #{statements[table_name].size}\e[0m\n\n"

        if response === false
          break
        end
      end


    end

    def sanitize(table_name,column_name,value)
      sanitized_value = replace_boolean(value)
      sanitized_value = fill_empty_column(sanitized_value)

      if not @tenant_record_id.nil?
        sanitized_value = replace_tenant_record_id(column_name,sanitized_value)
      end

      if not @account_record_id.nil?
        sanitized_value = replace_account_record_id(table_name,column_name,sanitized_value)
      end

      sanitized_value
    end

    def replace_tenant_record_id(column_name,value)
      if column_name == 'tenant_record_id'
        return @tenant_record_id
      end

      value
    end

    def replace_account_record_id(table_name,column_name,value)

      if column_name == 'account_record_id'

        return @account_record_id
      end

      if column_name == 'record_id'

        if table_name == 'accounts'
          return @account_record_id
        else
          return nil
        end
      end

      if column_name == 'target_record_id'

        if table_name == 'account_history'
          return @account_record_id
        end
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

    def fill_empty_column(value)
      if value.to_s.strip.empty?
        return nil
      else
        return value
      end
    end

  end

end