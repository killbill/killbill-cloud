
module KPM

  class Database
    class << self

      # Destination database
      DATABASE = 'killbill'
      USERNAME = 'root'
      PASSWORD = 'root'

      MYSQL_COMMAND_LINE = "mysql #{DATABASE} --user=#{USERNAME} --password=#{PASSWORD} -e"

      @@mysql_command_line = MYSQL_COMMAND_LINE

      def set_configuration(database = nil, user = nil, password = nil)

        if database && user && password
          @@mysql_command_line = "mysql #{database} --user=#{user} --password=#{password} -e"
        end

      end

      def execute_insert_statement(table_name, query)
        response = `#{@@mysql_command_line} "#{query}" 2>&1`

        if response.include? 'ERROR'
          puts "Importing #{table_name}...... \e[91;1m#{response}\e[0m"

          return false
        end

        if response.include? 'LAST_INSERT_ID'
          puts "\e[32mImporting #{table_name}...... success\e[0m"

          return response.split("\n")[1]
        end

        return true
      end

      def generate_insert_statement(tables)

        statements = Hash.new
        puts "\e[32mGenerating statements\e[0m\n\n"
        tables.each_key { |table_name|
          rows = tables[table_name]
          statements[table_name] = []

          rows.each { |row|
            columns = []
            values = []

            row.each_key { |name|
              columns << name
              values << row[name]
            }

            columns_names = columns.join(",").gsub(/'/,'')
            value_data = values.map{|value| "'#{value}'"}.join(",")

            statements[table_name] << get_insert_statement(table_name,columns_names,value_data)
          }
        }

        statements

      end

      def get_insert_statement(table_name, columns_names, values)
        return "INSERT INTO #{table_name} ( #{columns_names} ) VALUES ( #{values}); SELECT LAST_INSERT_ID();"
      end

    end

  end

end