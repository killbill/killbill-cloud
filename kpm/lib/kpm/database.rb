# frozen_string_literal: true

require 'tmpdir'

module KPM
  class Database
    # Mysql Information functions
    LAST_INSERTED_ID = 'SELECT LAST_INSERT_ID();'
    ROWS_UPDATED = 'SELECT ROW_COUNT();'

    # Destination database
    DATABASE = ENV['DATABASE'] || 'killbill'
    USERNAME = ENV['USERNAME'] || 'root'
    PASSWORD = ENV['PASSWORD'] || 'root'
    HOST = ENV['HOST'] || 'localhost'
    PORT = ENV['PORT'] || '3306'

    COLUMN_NAME_POS = 3

    STATEMENT_TMP_FILE = Dir.mktmpdir('statement') + File::SEPARATOR + 'statement.sql'

    def initialize(database_name, host, port, username, password, logger)
      @database_name = database_name || DATABASE
      @host = host || HOST
      @port = port || PORT
      @username = username || USERNAME
      @password = password || PASSWORD
      @mysql_command_line = "mysql --max_allowed_packet=128M #{@database_name} --host=#{@host} --port=#{@port} --user=#{@username} --password=#{@password} "

      @logger = logger
    end

    def execute_insert_statement(table_name, query, qty_to_insert, _table_data, record_id = nil)
      query = "set #{record_id[:variable]}=#{record_id[:value]}; #{query}" unless record_id.nil?
      query = "SET sql_mode = ''; SET autocommit=0; #{query} COMMIT; SHOW WARNINGS;"

      File.open(STATEMENT_TMP_FILE, 'w') do |s|
        s.puts query
      end

      response = `#{@mysql_command_line} < "#{STATEMENT_TMP_FILE}" 2>&1`

      if response.include? 'ERROR'
        @logger.error "\e[91;1mTransaction that fails to be executed (first 1,000 chars)\e[0m"
        # Queries can be really big (bulk imports)
        @logger.error "\e[91m#{query[0..1000]}\e[0m"
        if response.include?('Table') && response.include?('doesn\'t exist')
          @logger.warn "Skipping unknown table #{table_name}...."
        else
          raise Interrupt, "Importing table #{table_name}...... \e[91;1m#{response}\e[0m"
        end
      end

      if response.include? 'LAST_INSERT_ID'
        @logger.info "\e[32mImporting table #{table_name}...... Row 1 of #{qty_to_insert} success\e[0m"

        return response.split("\n")[1]
      end

      if response.include? 'ROW_COUNT'
        # Typically, something like: "mysql: [Warning] Using a password on the command line interface can be insecure.\nROW_COUNT()\n3\n"
        # With warning: "mysql: [Warning] Using a password on the command line interface can be insecure.\nROW_COUNT()\n1743\nLevel\tCode\tMessage\nWarning\t1264\tOut of range value for column 'amount' at row 582\n"
        response_msg = response.split("\n")
        idx_row_count_inserted = response_msg.index('ROW_COUNT()') + 1
        row_count_inserted = response_msg[idx_row_count_inserted]
        @logger.info "\e[32mImporting table #{table_name}...... Row #{row_count_inserted || 1} of #{qty_to_insert} success\e[0m"
        if idx_row_count_inserted < response_msg.size - 1
          warning_msg = response_msg[response_msg.size - 1]
          @logger.warn "\e[91m#{warning_msg}\e[0m"
        end
      end

      true
    end

    def generate_insert_statement(tables)
      statements = []
      @logger.info "\e[32mGenerating statements\e[0m"

      tables.each_key do |table_name|
        table = tables[table_name]
        next unless !table[:rows].nil? && !table[:rows].empty?

        columns_names = table[:col_names].join(',').gsub(/'/, '')

        rows = []
        table[:rows].each do |row|
          rows << row.map do |value|
            case value
            when Symbol
              value.to_s
            when Blob
              value.value
            else
              escaped_value = value.to_s.gsub(/['"]/, "'" => "\\'", '"' => '\\"')
                                   .gsub('\N{LINE FEED}', "\n")
                                   .gsub('\N{VERTICAL LINE}', '|')
              "'#{escaped_value}'"
            end
          end.join(',')
        end

        # Break the insert statement into small chunks to avoid timeouts
        rows.each_slice(1000).each do |subset_of_rows|
          value_data = subset_of_rows.map { |row| "(#{row})" }.join(',')

          statements << { query: build_insert_statement(table_name, columns_names, value_data, subset_of_rows.size),
                          qty_to_insert: subset_of_rows.size, table_name: table_name, table_data: table }
        end
      end

      statements
    end

    private

    def build_insert_statement(table_name, columns_names, values, rows_qty)
      "INSERT INTO #{table_name} ( #{columns_names} ) VALUES #{values}; #{rows_qty == 1 ? LAST_INSERTED_ID : ROWS_UPDATED}"
    end
  end
end
