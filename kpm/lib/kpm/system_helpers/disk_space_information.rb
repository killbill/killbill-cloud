# frozen_string_literal: true

module KPM
  module SystemProxy
    module DiskSpaceInformation
      class << self
        def fetch
          disk_space_info = nil
          if OS.windows?
            disk_space_info = fetch_windows
          elsif OS.linux?
            disk_space_info = fetch_linux_mac(5)
          elsif OS.mac?
            disk_space_info = fetch_linux_mac(8)
          end

          disk_space_info
        end

        def get_labels
          labels = []
          @@data_keys.each { |key| labels.push(label: key.gsub(' ', '_').to_sym) }
          labels
        end

        private

        def fetch_linux_mac(cols_count)
          disk_space_info = `df 2>&1`
          disk_space = get_hash(disk_space_info, cols_count, true)
          disk_space
        end

        def fetch_windows
          disk_space_info = `wmic logicaldisk get size,freespace,caption 2>&1`
          disk_space = get_hash(disk_space_info, 3, false)
          disk_space
        end

        def get_hash(data, cols_count, merge_last_two_columns)
          disk_space = {}

          unless data.nil?

            data_table = data.split("\n")

            @@data_keys = data_table[0].split(' ')

            if merge_last_two_columns
              @@data_keys[@@data_keys.length - 2] = @@data_keys[@@data_keys.length - 2] + ' ' + @@data_keys[@@data_keys.length - 1]
              @@data_keys.delete_at(@@data_keys.length - 1)
            end

            row_num = 0
            data_table.each do |row|
              cols = row.split(' ')
              row_num += 1
              next if cols[0].to_s.eql?(@@data_keys[0])

              key = 'DiskInfo_' + row_num.to_s
              disk_space[key] = {}
              cols.each_index do |idx|
                break if idx > cols_count

                value = cols[idx].to_s.strip
                if idx == cols_count && cols.length - 1 > idx
                  (cols_count + 1..cols.length).each do |i|
                    value += ' ' + cols[i].to_s.strip
                  end
                end

                disk_space[key][@@data_keys[idx].gsub(' ', '_').to_sym] = value
              end
            end
          end

          disk_space
        end
      end
    end
  end
end
