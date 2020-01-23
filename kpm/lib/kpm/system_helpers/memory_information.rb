# frozen_string_literal: true

module KPM
  module SystemProxy
    class MemoryInformation
      attr_reader :memory_info, :labels

      def initialize
        @memory_info = fetch
        @labels = [{ label: :memory_detail },
                   { label: :value }]
      end

      private

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

      def fetch_linux
        mem_data = `cat /proc/meminfo 2>&1`.gsub("\t", '')
        build_hash(mem_data)
      end

      def fetch_mac
        mem_data = `vm_stat 2>&1`.gsub('.', '')
        mem_total_data = `system_profiler SPHardwareDataType | grep "  Memory:" 2>&1`
        build_hash_mac(mem_data, mem_total_data)
      end

      def build_hash_mac(mem_data, mem_total_data)
        mem = build_hash(mem_data)

        mem.each_key do |key|
          mem[key][:value] = ((mem[key][:value].to_i * 4096) / 1024 / 1024).to_s + 'MB'
          mem[key][:memory_detail] = mem[key][:memory_detail].gsub('Pages', 'Memory')
        end

        mem_total = build_hash(mem_total_data)

        mem_total.merge(mem)
      end

      def fetch_windows
        mem_data = `systeminfo | findstr /C:"Total Physical Memory" /C:"Available Physical Memory"`
        build_hash(mem_data)
      end

      def build_hash(data)
        mem = {}
        return mem if data.nil?

        data.split("\n").each do |info|
          infos = info.split(':')
          key = infos[0].to_s.strip.gsub('"', '')
          mem[key] = { memory_detail: key, value: infos[1].to_s.strip }
        end

        mem
      end
    end
  end
end
