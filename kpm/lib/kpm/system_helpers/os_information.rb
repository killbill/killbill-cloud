# frozen_string_literal: true

module KPM
  module SystemProxy
    module OsInformation
      class << self
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

        def get_labels
          labels = [{ label: :os_detail },
                    { label: :value }]
          labels
        end

        private

        def fetch_linux
          os_data = `lsb_release -a 2>&1`

          if os_data.nil? || os_data.include?('lsb_release: not found')
            os_data = `cat /etc/issue 2>&1`
            os_data = 'Description:' + os_data.gsub('\n \l', '')
          end

          os = get_hash(os_data)
          os
        end

        def fetch_mac
          os_data = `sw_vers`
          os = get_hash(os_data)
          os
        end

        def fetch_windows
          os_data = `systeminfo | findstr /C:"OS"`
          os = get_hash(os_data)
          os
        end

        def get_hash(data)
          os = {}

          data&.split("\n")&.each do |info|
            infos = info.split(':')
            os[infos[0].to_s.strip] = { os_detail: infos[0].to_s.strip, value: infos[1].to_s.strip }
          end

          os
        end
      end
    end
  end
end
