require 'tmpdir'

module KPM

  class Database
    class << self

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

      MYSQL_COMMAND_LINE = "mysql #{DATABASE} --user=#{USERNAME} --password=#{PASSWORD} "

      @@mysql_command_line = MYSQL_COMMAND_LINE
      @@username = USERNAME
      @@password = PASSWORD
      @@database = DATABASE
      @@host = HOST
      @@port = PORT

      def set_logger(logger)
        @@logger = logger
      end

      def set_credentials(user = nil, password = nil)
        @@username = user
        @@password = password
      end

      def set_host(host)
        @@host = host
      end

      def set_port(port)
        @@port = port
      end

      def set_database_name(database_name = nil)
        @@database = database_name
      end

      def set_mysql_command_line
        @@mysql_command_line = "mysql #{@@database} --host=#{@@host} --port=#{@@port} --user=#{@@username} --password=#{@@password} "
      end

      def execute_insert_statement(table_name, query, qty_to_insert, table_data, record_id = nil)

        unless record_id.nil?
          query = "set #{record_id[:variable]}=#{record_id[:value]}; #{query}"
        end
        query = "SET autocommit=0; #{query} COMMIT;"
        
        File.open(STATEMENT_TMP_FILE,'w') do |s|
          s.puts query
        end

        response = `#{@@mysql_command_line} < "#{STATEMENT_TMP_FILE}" 2>&1`

        if response.include? 'ERROR'
          @@logger.error "\e[91;1mTransaction that fails to be executed\e[0m"
          @@logger.error "\e[91m#{query}\e[0m"
          raise Interrupt, "Importing table #{table_name}...... \e[91;1m#{response}\e[0m"
        end

        if response.include? 'LAST_INSERT_ID'
          @@logger.info "\e[32mImporting table #{table_name}...... Row 1 of #{qty_to_insert} success\e[0m"

          return response.split("\n")[1]
        end

        if response.include? 'ROW_COUNT'
          response_msg = response.split("\n")
          row_count_inserted = response_msg[response_msg.size - 1]
          @@logger.info "\e[32mImporting table #{table_name}...... Row #{ row_count_inserted || 1} of #{qty_to_insert} success\e[0m"

          return true
        end

        return true
      end

      def generate_insert_statement(tables)

        statements = []
        @@logger.info "\e[32mGenerating statements\e[0m"

        tables.each_key do |table_name|
          table = tables[table_name]
          if !table[:rows].nil? && table[:rows].size > 0
            columns_names = table[:col_names].join(",").gsub(/'/,'')

            rows = []
            table[:rows].each do |row|
              rows << row.map{|value| value.is_a?(Symbol) ? value.to_s : "'#{value.to_s.gsub(/['"]/, "'" => "\\'", '"' => '\\"')}'" }.join(",")
            end

            value_data = rows.map{|row| "(#{row})" }.join(",")

            statements << {:query => get_insert_statement(table_name,columns_names,value_data, rows.size),
                                      :qty_to_insert => rows.size, :table_name => table_name, :table_data => table}

          end

        end

        statements

      end

      private

        def get_insert_statement(table_name, columns_names, values, rows_qty)
          return "INSERT INTO #{table_name} ( #{columns_names} ) VALUES #{values}; #{rows_qty == 1 ? LAST_INSERTED_ID : ROWS_UPDATED}"
        end

    end

  end

end