#! /usr/bin/env ruby

require 'net/http'
require 'openssl'
require 'tmpdir'
require 'yaml'


EC2_INSTALL_DEST="/home/ubuntu/killbill_install"
CONFIG="config"
BINARIES="binaries"

OUTPUT="install.log"

CATALINA_HOME="/opt/apache-tomcat-7.0.40"
TOMCAT_GEN_SCRIPT="/tmp/tomcat.sh"

class KillbillInstall
  attr_reader :config

  def initialize(killbill_config_path, output)
    @output = output
    @config = YAML.load(File.open(killbill_config_path))
    @working_dir = EC2_INSTALL_DEST
    Dir.chdir(@working_dir)
    log "Initialize : working directory is #{@working_dir}"

    @config_dir = File.join(@working_dir, CONFIG)
    Dir.mkdir(@config_dir) if !Dir.exist?(@config_dir)

    @binaries_dir = File.join(@working_dir, BINARIES)
    Dir.mkdir(@binaries_dir) if !Dir.exist?(@binaries_dir)
  end

  def log(msg)
    @output.write("#{msg}\n")
    @output.flush
  end

  def download_world
    download_killbill
    download_plugins
  end

  def setup_tomcat
    generate_tomcat_setup_script
    system "chmod a+x #{TOMCAT_GEN_SCRIPT}"
    system "#{TOMCAT_GEN_SCRIPT}"
  end

  def start
    log("Starting Killbill...")
    system "sudo #{CATALINA_HOME}/bin/shutdown.sh 2>/dev/null"
    sleep 3
    system "sudo #{CATALINA_HOME}/bin/startup.sh"
  end

  private

  def generate_tomcat_setup_script

    kilbill_server_war = Dir["#{@binaries_dir}/*.{war}"][0]
    log("Generating tomcat script kilbill_server_war = #{kilbill_server_war}..")


    File.open(TOMCAT_GEN_SCRIPT, "w") do |out|
      out.write("#!/usr/bin/env bash\n\n")
      out.write("\n")
      out.write("sudo chmod a+w  #{CATALINA_HOME}/conf/catalina.properties\n")
      out.write("sudo cat #{@config_dir}/killbill.properties >> #{CATALINA_HOME}/conf/catalina.properties\n")
      out.write("sudo mkdir -p #{CATALINA_HOME}/conf/Catalina/localhost\n")
      out.write("sudo touch #{CATALINA_HOME}/conf/Catalina/localhost/ROOT.xml\n")
      out.write("sudo chmod a+w #{CATALINA_HOME}/conf/Catalina/localhost/ROOT.xml\n")
      out.write("sudo echo \'<Context docBase=\"#{kilbill_server_war}\">\' > #{CATALINA_HOME}/conf/Catalina/localhost/ROOT.xml\n")
      out.write("sudo echo \"</Context>\" >> #{CATALINA_HOME}/conf/Catalina/localhost/ROOT.xml\n")
    end
  end

  def download_killbill
    version = (@config[:killbill] || {})[:version]

    # Download the binary
    download('com.ning.billing', 'killbill-server', version, 'war', 'jar-with-dependencies')

  end

  def download_plugins
    plugins = (@config[:plugins] || [])
    plugins.each do |plugin_name, plugin_def|
      version = plugin_def[:version]

      # Download the binary
      download (plugin_def[:group_id] || 'com.ning.killbill.ruby'),
               (plugin_def[:artifact_id] || plugin_name),
               version
    end
  end

  def download(group_id, artifact_id, version=nil, packaging='tar.gz', classifier=nil)
    log("Download #{group_id}:#{artifact_id}:#{version}")
    fetch("https://repository.sonatype.org/service/local/artifact/maven/redirect?r=central-proxy&g=#{group_id}&a=#{artifact_id}&c=#{classifier}&p=#{packaging}&v=#{version||'LATEST'}",
          "#{artifact_id}#{'-' + version if version}.#{packaging}")
  end

  def fetch(uri_string, filename, limit=10)
    return if limit <= 0

    uri = URI(uri_string)
    Net::HTTP.start(uri.host, uri.port, {:use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE}) do |http|
      request = Net::HTTP::Get.new uri.request_uri

      http.request request do |response|
        case response
          when Net::HTTPSuccess then
            puts "Downloading #{uri.request_uri}"
            open "#{@binaries_dir}/#{filename}", 'w' do |io|
              response.read_body do |chunk|
                io.write chunk
              end
            end
          when Net::HTTPRedirection then
            #puts "Redirect from #{uri.request_uri} to #{response['location']}"
            fetch(response['location'], filename, limit - 1)
          else
            response.error!
        end
      end
    end
  end
end


logfile="#{EC2_INSTALL_DEST}/#{OUTPUT}"
File.delete(logfile) if File.exist?(logfile)

File.open(logfile, "w") do |log|
  installer = KillbillInstall.new("#{EC2_INSTALL_DEST}/killbill.config", log)
  installer.download_world
  installer.setup_tomcat
  installer.start
end

