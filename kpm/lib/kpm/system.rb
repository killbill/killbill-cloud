
module KPM

  module OS
    def OS.windows?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RbConfig::CONFIG["host_os"]) != nil
    end

    def OS.mac?
      (/darwin/ =~ RbConfig::CONFIG["host_os"]) != nil
    end

    def OS.unix?
      !OS.windows?
    end

    def OS.linux?
      OS.unix? and not OS.mac?
    end
  end

  class System
    def initialize
      @formatter = KPM::Formatter.new
    end

    def information(destination)
      kpm_version = KPM::VERSION
      kaui_version = get_kaui_version
      killbill_version = get_killbill_version

      environment = Hash[:kpm => {:system=>'KPM',:version => kpm_version},
                         :kaui => {:system=>'Kaui',:version => kaui_version},
                         :killbill => {:system=>'Killbill',:version => killbill_version}]

      labels = [{:label => :system},
                {:label => :version}]

      @formatter.format(environment,labels)

      show_environment_information
      show_os_information
      show_java_system_information
      show_plugin_information(destination)
    end

    def show_environment_information
      java_version = `java -version 2>&1`.split("\n")[0].split('"')[1]

      environment = Hash[:ruby => {:environment=>'Ruby',:version => RUBY_VERSION},
                         :java => {:environment=>'Java',:version => java_version}]

      labels = [{:label => :environment},
                {:label => :version}]

      @formatter.format(environment,labels)
    end

    def show_os_information
      os = Hash.new
      os_data = nil

      if OS.windows?
        os_data = `systeminfo | findstr /C:"OS"`

      elsif OS.linux?
        os_data = `lsb_release -a 2>&1`

      elsif OS.mac?
        os_data = `sw_vers`

      end

      if os_data != nil
        os_data.split("\n").each do |info|

          infos = info.split(':')
          os[infos[0]] = {:os_detail => infos[0], :value => infos[1].to_s.strip}

        end
      end

      labels = [{:label => :os_detail},
                {:label => :value}]

      @formatter.format(os,labels)
    end

    def show_java_system_information
      java_system = Hash.new
      property_count = 0;
      `java -XshowSettings:properties -version 2>&1`.split("\n").each do |prop|
        property_count += 1

        if prop.to_s.strip.empty?
          break;
        end

        if property_count > 1
          props = prop.split('=')
          java_system[props[0]] = {:java_property => props[1] == nil ? '' : props[0], :value => props[1] == nil ? props[0] : props[1]}
        end
      end

      labels = [{:label => :java_property},
                {:label => :value}]

      @formatter.format(java_system,labels)
    end

    def show_plugin_information(destination)
      inspector = KPM::Inspector.new
      all_plugins = inspector.inspect(destination)

      @formatter.format(all_plugins)
    end

    def get_kaui_version
      gemfile = Dir['**' + File::SEPARATOR + 'kaui' + File::SEPARATOR + 'WEB-INF' + File::SEPARATOR + 'Gemfile']
      version = nil
      if not gemfile[0].nil?
        absolute_gemfile_path = File.absolute_path(gemfile[0])

        version = open(absolute_gemfile_path) do |f|
          f.each_line.detect do |line|
             if /kaui/.match(line)
                version = /(\d+)\.(\d+)\.(\d+)/.match(line)

                if not version.nil?
                  break;
                end
             end
          end
          version
        end

      end

      version
    end

    def get_killbill_version
      file =  Dir['**' + File::SEPARATOR + 'ROOT' + File::SEPARATOR + 'META-INF' +  File::SEPARATOR + '**' + File::SEPARATOR + 'pom.properties']
      version = nil
      if not file[0].nil?
        absolute_file_path = File.absolute_path(file[0])

        version = open(absolute_file_path) do |f|
          f.each_line.detect do |line|
              version = /(\d+)\.(\d+)\.(\d+)/.match(line)

              if not version.nil?
                break;
              end
          end
          version
        end

      end

      version
    end

  end

end