require 'yaml'

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

    MAX_VALUE_COLUMN_WIDTH = 60
    DEFAULT_BUNDLE_DIR = Dir['/var' + File::SEPARATOR + 'lib' + File::SEPARATOR + 'killbill' + File::SEPARATOR + 'bundles'][0] || Dir['/var' + File::SEPARATOR + 'tmp' + File::SEPARATOR + 'bundles'][0]
    DEFAULT_KAUI_SEARCH_BASE_DIR = '**' + File::SEPARATOR + 'kaui'
    DEFAULT_KILLBILL_SEARCH_BASE_DIR = '**' + File::SEPARATOR + 'ROOT'

    def initialize
      @formatter = KPM::Formatter.new
    end

    def information(bundles_dir = nil, output_as_json = false, config_file = nil, kaui_web_path = nil, killbill_web_path = nil)
      puts 'Retrieving system information'
      set_config(config_file)
      killbill_information = show_killbill_information(kaui_web_path,killbill_web_path,output_as_json)

      java_version = `java -version 2>&1`.split("\n")[0].split('"')[1]

      environment_information = show_environment_information(java_version, output_as_json)
      os_information = show_os_information(output_as_json)

      if not java_version.nil?
        command = get_command
        java_system_information = show_java_system_information(command,output_as_json)
      end

      plugin_information = show_plugin_information(get_plugin_path || bundles_dir || DEFAULT_BUNDLE_DIR, output_as_json)

      if output_as_json
        json_data = Hash.new
        json_data[:killbill_information] = killbill_information
        json_data[:environment_information] = environment_information
        json_data[:os_information] = os_information
        json_data[:java_system_information] = java_system_information
        json_data[:plugin_information] = plugin_information

        puts json_data.to_json
      end
    end

    def show_killbill_information(kaui_web_path, killbill_web_path, output_as_json)

      kpm_version = KPM::VERSION
      kaui_version = get_kaui_version(get_kaui_web_path || kaui_web_path)
      killbill_version = get_killbill_version(get_killbill_web_path || killbill_web_path)

      environment = Hash[:kpm => {:system=>'KPM',:version => kpm_version},
                         :kaui => {:system=>'Kaui',:version => kaui_version.nil? ? 'not found' : kaui_version},
                         :killbill => {:system=>'Killbill',:version => killbill_version.nil? ? 'not found' : killbill_version}]

      labels = [{:label => :system},
                {:label => :version}]

      if not output_as_json
        @formatter.format(environment,labels)
      end

      environment
    end

    def show_environment_information(java_version, output_as_json)

      environment = Hash[:ruby => {:environment=>'Ruby',:version => RUBY_VERSION},
                         :java => {:environment=>'Java',:version => java_version.nil? ? 'no version found' : java_version}]

      labels = [{:label => :environment},
                {:label => :version}]

      if not output_as_json
        @formatter.format(environment,labels)
      end

      environment
    end

    def show_os_information(output_as_json)
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

      if not output_as_json
        @formatter.format(os,labels)
      end

      os
    end

    def show_java_system_information(command, output_as_json)
      java_system = Hash.new
      property_count = 0;
      last_key = ''

      `#{command}`.split("\n").each do |prop|

        if prop.to_s.strip.empty?
          break;
        end

        if property_count > 0
          props = prop.split('=')

          if (not props[1].nil? && props[1].to_s.strip.size > MAX_VALUE_COLUMN_WIDTH) && output_as_json == false

            chunks = ".{1,#{MAX_VALUE_COLUMN_WIDTH}}"
            props[1].to_s.scan(/#{chunks}/).each_with_index do |p, index|

              java_system[property_count] = {:java_property => index.equal?(0) ? props[0] : '', :value => p}
              property_count += 1

            end
          elsif output_as_json
            key = (props[1].nil? ? last_key : props[0]).to_s.strip
            value = props[1].nil? ? props[0] : props[1]

            if java_system.has_key?(key)
              java_system[key][:value] = java_system[key][:value].to_s.concat(' ').concat(value)
            else
              java_system[key] = {:java_property => key, :value => value}
            end

          else

            java_system[property_count] = {:java_property => props[1].nil? ? '' : props[0], :value => props[1].nil? ? props[0] : props[1]}

          end

          last_key = props[1].nil? ? last_key : props[0]
        end

        property_count += 1

      end
      labels = [{:label => :java_property},
                  {:label => :value}]


      if not output_as_json
        @formatter.format(java_system,labels)
      end

      java_system

    end

    def show_plugin_information(bundles_dir, output_as_json)

      if bundles_dir.nil?
        all_plugins = nil
      else
        inspector = KPM::Inspector.new
        all_plugins = inspector.inspect(bundles_dir)
      end

      if not output_as_json
        if all_plugins.nil? || all_plugins.size == 0
          puts "\e[91;1mNo KB plugin information available\e[0m\n\n"
        else
          @formatter.format(all_plugins)
        end
      end

      if output_as_json && (all_plugins.nil? || all_plugins.size == 0)
        all_plugins = 'No KB plugin information available'
      end
      all_plugins
    end

    def get_kaui_version(kaui_web_path = nil)
      puts kaui_web_path
      kaui_search_default_dir = Dir[kaui_web_path.nil? ? '' : kaui_web_path][0] || DEFAULT_KAUI_SEARCH_BASE_DIR
      version = nil

      gemfile = Dir[kaui_search_default_dir + File::SEPARATOR + 'WEB-INF' + File::SEPARATOR + 'Gemfile']

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

    def get_killbill_version(killbill_web_path = nil)
      killbill_search_default_dir = Dir[killbill_web_path.nil? ? '' : killbill_web_path][0] || DEFAULT_KILLBILL_SEARCH_BASE_DIR

      file =  Dir[killbill_search_default_dir + File::SEPARATOR + 'META-INF' +  File::SEPARATOR + '**' + File::SEPARATOR + 'pom.properties']
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

    def get_command
      command = 'java -XshowSettings:properties -version 2>&1'
      apache_tomcat_pid = get_apache_tomcat_pid

      if not apache_tomcat_pid.nil?
        command = "jcmd #{apache_tomcat_pid} VM.system_properties"
      end

      command
    end

    def get_apache_tomcat_pid
      apache_tomcat_pid = nil;
      `jcmd -l 2>&1`.split("\n").each do |line|

        if /org.apache.catalina/.match(line)
          words = line.split(' ')
          apache_tomcat_pid = words[0]
        end

      end

      apache_tomcat_pid
    end

    def set_config(config_file = nil)
      @config = nil

      if not config_file.nil?
        if not Dir[config_file][0].nil?
          @config = YAML::load_file(config_file)
        end
      end

    end

    def get_kaui_web_path
      kaui_web_path = nil;

      if not @config.nil?
        config_kaui = @config['kaui']

        if not config_kaui.nil?
          kaui_web_path = Dir[config_kaui['webapp_path']][0]
        end
      end

      kaui_web_path
    end

    def get_killbill_web_path
      killbill_web_path = nil;

      if not @config.nil?
        config_killbill = @config['killbill']

        if not config_killbill.nil?
          killbill_web_path = Dir[config_killbill['webapp_path']][0]
        end
      end

      killbill_web_path
    end

    def get_plugin_path
      plugin_path = nil;

      if not @config.nil?
        config_killbill = @config['killbill']

        if not config_killbill.nil?
          plugin_path = Dir[config_killbill['plugins_dir']][0]
        end
      end

      plugin_path
    end

  end

end