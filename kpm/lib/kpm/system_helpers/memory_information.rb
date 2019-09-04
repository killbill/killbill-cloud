# frozen_string_literal: true

module KPM
  module SystemProxy
    module MemoryInformation
      class << self
        def fetch
          memory_info = nil
          if OS.windows?
            memory_info = fetch_windows
          elsif OS.linux?
            memory_info = fetch_linux
          elsif OS.mac?
            memory_info = fetch_mac
          end

          memory_info
        end

        def get_labels
          labels = [{ label: :memory_detail },
                    { label: :value }]
          labels
        end

        private

        def fetch_linux
          mem_data = `cat /proc/meminfo 2>&1`.gsub("\t", '')
          mem = get_hash(mem_data)
          mem
        end

        def fetch_mac
          mem_data = `vm_stat 2>&1`.gsub('.', '')
          mem = get_hash(mem_data)

          mem.each_key do |key|
            mem[key][:value] = ((mem[key][:value].to_i * 4096) / 1024 / 1024).to_s + 'MB'
            mem[key][:memory_detail] = mem[key][:memory_detail].gsub('Pages', 'Memory')
          end

          mem_total_data = `system_profiler SPHardwareDataType | grep "  Memory:" 2>&1`
          mem_total = get_hash(mem_total_data)

          mem = mem_total.merge(mem)

          mem
        end

        def fetch_windows
          mem_data = `systeminfo | findstr /C:"Total Physical Memory" /C:"Available Physical Memory"`
          mem = get_hash(mem_data)
          mem
        end

        def get_hash(data)
          mem = {}

          unless data.nil?
            data.split("\n").each do |info|
              infos = info.split(':')
              mem[infos[0].to_s.strip] = {memory_detail: infos[0].to_s.strip, value: infos[1].to_s.strip}
            end
          end

          mem
        end
      end
    end
  end
end
