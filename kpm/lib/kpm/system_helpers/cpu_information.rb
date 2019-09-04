module KPM
  module SystemProxy
    module CpuInformation
      class << self
        def fetch
          cpu_info = nil
          if OS.windows?
            cpu_info = fetch_windows
          elsif OS.linux?
            cpu_info = fetch_linux
          elsif OS.mac?
            cpu_info = fetch_mac
          end

          cpu_info
        end

        def get_labels
          labels = [{ :label => :cpu_detail },
                    { :label => :value }]
          labels
        end

          private

        def fetch_linux
          cpu_data = `cat /proc/cpuinfo 2>&1`.gsub("\t", '')
          cpu = get_hash(cpu_data)
          cpu
        end

        def fetch_mac
          cpu_data = `system_profiler SPHardwareDataType | grep -e "Processor" -e "Cores" -e "Cache" 2>&1`
          cpu = get_hash(cpu_data)
          cpu
        end

        def fetch_windows
          cpu_name = `wmic cpu get Name`.split("\n\n")
          cpu_caption = `wmic cpu get Caption`.split("\n\n")
          cpu_max_clock_speed = `wmic cpu get MaxClockSpeed`.split("\n\n")
          cpu_device_id = `wmic cpu get DeviceId`.split("\n\n")
          cpu_status = `wmic cpu get Status`.split("\n\n")

          cpu = Hash.new
          cpu[cpu_name[0].to_s.strip] = { :cpu_detail => cpu_name[0].to_s.strip, :value => cpu_name[1].to_s.strip }
          cpu[cpu_caption[0].to_s.strip] = { :cpu_detail => cpu_caption[0].to_s.strip, :value => cpu_caption[1].to_s.strip }
          cpu[cpu_max_clock_speed[0].to_s.strip] = { :cpu_detail => cpu_max_clock_speed[0].to_s.strip, :value => cpu_max_clock_speed[1].to_s.strip }
          cpu[cpu_device_id[0].to_s.strip] = { :cpu_detail => cpu_device_id[0].to_s.strip, :value => cpu_device_id[1].to_s.strip }
          cpu[cpu_status[0].to_s.strip] = { :cpu_detail => cpu_status[0].to_s.strip, :value => cpu_status[1].to_s.strip }

          cpu
        end

        def get_hash(data)
          cpu = Hash.new

          unless data.nil?
            data.split("\n").each do |info|
              infos = info.split(':')

              unless infos[0].to_s.strip.eql?('flags')
                cpu[infos[0].to_s.strip] = { :cpu_detail => infos[0].to_s.strip, :value => infos[1].to_s.strip }
              end
            end
          end

          cpu
        end
        end
    end
  end
end
