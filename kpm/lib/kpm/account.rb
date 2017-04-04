require 'net/http'
require 'tmpdir'

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

    # Destination database
    DATABASE = 'killbill'
    USERNAME = 'root'
    PASSWORD = 'root'

    # Temporary directory
    TMP_DIR_PEFIX = 'killbill'
    TMP_DIR = Dir.mktmpdir(TMP_DIR_PEFIX);

    # Created By
    WHO = 'kpm_export_import'

    def export_data(account_id = nil)

      if account_id === :export.to_s
        puts "\e[91;1mNeed to specify an account id\e[0m\n\n"
        Dir.rmdir(TMP_DIR)
        return
      end

      uri = URI(KILLBILL_URL.concat('/').concat(KILLBILL_API_VERSION).concat('/kb/export/').concat(account_id))
      export_file = TMP_DIR + File::SEPARATOR + 'kbdump'

      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(KILLBILL_USER,KILLBILL_PASSWORD)
      request['X-Killbill-ApiKey'] = KILLBILL_API_KEY;
      request['X-Killbill-ApiSecret'] = KILLBILL_API_SECRET;
      request['X-Killbill-CreatedBy'] = WHO;

      response = Net::HTTP.start(uri.host,uri.port) do |http|
        http.request(request)
      end

      open (export_file), 'w' do |io|
        io.write response.body
      end if response.is_a?(Net::HTTPSuccess)

      if not File.exist?(export_file)
        puts "\e[91;1mAccount id not found\e[0m\n\n"
        Dir.rmdir(TMP_DIR)
      else
        puts "\e[32mData exported under #{export_file}\e[0m\n\n"
      end
    end

    def import_data(source_file)

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

      sanitize_and_import(source_file)
    end

    def sanitize_and_import(source_file)
      tables = Hash.new

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

            puts "\e[32mImporting #{table_name}\e[0m\n\n"

            rows = []
          else
            cols = line.strip.split("|")
            row = Hash.new

            cols_names.each_with_index { |col_name, index|
              row[col_name] = sanitize(cols[index])
            }

            rows.push(row)
          end
        end

        if not table_name.nil?
          tables[table_name] = rows;
        end

      end

      puts tables.to_json

    end

    def sanitize(value)
      sanitized_value = replace_boolean(value)
      sanitized_value = fill_empty_column(sanitized_value)

      sanitized_value
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