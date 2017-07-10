module SystemProxy
  module OsInformation
    class << self

      def fetch
        entropy_available = nil
        if OS.windows?
          entropy_available = fetch_windows
        elsif OS.linux?
          entropy_available = fetch_linux
        elsif OS.mac?
          entropy_available = fetch_mac
        end

        entropy_available
      end

      def get_labels
        labels = [{:label => :os_detail},
                  {:label => :value}]
        labels
      end

      private
        def fetch_linux
          os_data = `lsb_release -a 2>&1`

          if os_data.nil? || os_data.include?('lsb_release: not found')
            os_data = `cat /etc/issue 2>&1`
            os_data = 'Description:'+os_data.gsub('\n \l','')
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
          os = Hash.new

          unless data.nil?
            data.split("\n").each do |info|
              infos = info.split(':')
              os[infos[0].to_s.strip] = {:os_detail => infos[0].to_s.strip, :value => infos[1].to_s.strip}
            end
          end

          os
        end

    end
  end
end