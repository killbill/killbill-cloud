# frozen_string_literal: true

module KPM
  module SystemProxy
    class OsInformation
      attr_reader :os_info, :labels

      def initialize
        @os_info = fetch
        @labels =  [{ label: :os_detail },
                    { label: :value }]
      end

      private

      def fetch
        os_information = nil
        if OS.windows?
          os_information = fetch_windows
        elsif OS.linux?
          os_information = fetch_linux
        elsif OS.mac?
          os_information = fetch_mac
        end

        os_information
      end

      def fetch_linux
        os_data = `lsb_release -a 2>&1`

        if os_data.nil? || os_data.include?('lsb_release: not found')
          os_data = `cat /etc/issue 2>&1`
          os_data = 'Description:' + os_data.gsub('\n \l', '')
        end

        build_hash(os_data)
      end

      def fetch_mac
        os_data = `sw_vers`
        build_hash(os_data)
      end

      def fetch_windows
        os_data = `systeminfo | findstr /C:"OS"`
        build_hash(os_data)
      end

      def build_hash(data)
        os = {}

        unless data.nil?
          data.split("\n").each do |info|
            infos = info.split(':')
            os[infos[0].to_s.strip] = { os_detail: infos[0].to_s.strip, value: infos[1].to_s.strip }
          end
        end

        os
      end
    end
  end
end
