# frozen_string_literal: true

require 'net/http'
require 'uri'

module KPM
  class TomcatManager
    DOWNLOAD_URL = 'https://s3.amazonaws.com/kb-binaries/apache-tomcat-7.0.42.tar.gz'

    def initialize(tomcat_dir, logger)
      @tomcat_dir = Pathname.new(tomcat_dir)
      @logger = logger
    end

    def download
      uri = URI.parse(DOWNLOAD_URL)

      path = nil
      Dir.mktmpdir do |dir|
        file = Pathname.new(dir).join('tomcat.tar.gz')

        @logger.info "Starting download of #{DOWNLOAD_URL} to #{file}"
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          File.open(file, 'wb+') do |file|
            http.get(uri.path) do |body|
              file.write(body)
            end
          end
        end

        path = Utils.unpack_tgz(file.to_s, @tomcat_dir, true)
      end

      @logger.info "Successful installation of #{DOWNLOAD_URL} to #{path}"
      path
    end

    def setup
      # Remove default webapps
      %w[ROOT docs examples host-manager manager].each do |webapp|
        FileUtils.rm_rf(@tomcat_dir.join('webapps').join(webapp))
      end

      # Update Root.xml
      root_xml_dir = @tomcat_dir.join('conf').join('Catalina').join('localhost')
      FileUtils.mkdir_p(root_xml_dir)
      File.write(root_xml_dir.join('ROOT.xml'), '<Context></Context>')

      # Setup default properties
      setenv_sh_path = @tomcat_dir.join('bin').join('setenv.sh')

      File.write(setenv_sh_path, "export CATALINA_OPTS=\"$CATALINA_OPTS #{default_java_properties}\"")

      @tomcat_dir.join('webapps').join('ROOT.war').to_s
    end

    def help
      "Tomcat installed at #{@tomcat_dir}
Start script: #{@tomcat_dir.join('bin').join('startup.sh').to_s}
Stop script: #{@tomcat_dir.join('bin').join('shutdown.sh').to_s}
Logs: #{@tomcat_dir.join('logs').to_s}"
    end

    private

    def default_java_properties
      <<HEREDOC.gsub(/\s+/, ' ').strip
      -server
      -showversion
      -XX:+PrintCommandLineFlags
      -XX:+UseCodeCacheFlushing
      -XX:PermSize=512m
      -XX:MaxPermSize=1G
      -Xms1G
      -Xmx2G
      -XX:+CMSClassUnloadingEnabled
      -XX:-OmitStackTraceInFastThrow
      -XX:+UseParNewGC
      -XX:+UseConcMarkSweepGC
      -XX:+CMSConcurrentMTEnabled
      -XX:+CMSParallelRemarkEnabled
      -XX:+UseCMSInitiatingOccupancyOnly
      -XX:CMSInitiatingOccupancyFraction=70
      -XX:+ScavengeBeforeFullGC
      -XX:+CMSScavengeBeforeRemark
      -XX:NewSize=600m
      -XX:MaxNewSize=900m
      -XX:SurvivorRatio=10
      -XX:+DisableExplicitGC
      -Djava.security.egd=file:/dev/./urandom
HEREDOC
    end
  end
end
