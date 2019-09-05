# frozen_string_literal: true

module KPM
  module SystemProxy
    module EntropyAvailable
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

        def labels
          [{ label: :entropy },
           { label: :value }]
        end

        private

        def fetch_linux
          entropy_available_data = `cat /proc/sys/kernel/random/entropy_avail 2>&1`.gsub("\n", '')
          build_hash(entropy_available_data)
        end

        def fetch_mac
          build_hash('-')
        end

        def fetch_windows
          build_hash('-')
        end

        def build_hash(data)
          entropy_available = {}
          entropy_available['entropy_available'] = { entropy: 'available', value: data }

          entropy_available
        end
      end
    end
  end
end
