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

        def get_labels
          labels = [{ label: :entropy },
                    { label: :value }]
          labels
        end

        private

        def fetch_linux
          entropy_available_data = `cat /proc/sys/kernel/random/entropy_avail 2>&1`.gsub("\n", '')
          entropy_available = get_hash(entropy_available_data)
          entropy_available
        end

        def fetch_mac
          entropy_available = get_hash('-')
          entropy_available
        end

        def fetch_windows
          entropy_available = get_hash('-')
          entropy_available
        end

        def get_hash(data)
          entropy_available = {}
          entropy_available['entropy_available'] = { entropy: 'available', value: data }

          entropy_available
        end
      end
    end
  end
end
