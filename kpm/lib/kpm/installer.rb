require 'logger'
require 'yaml'

module KPM
  class Installer
    LATEST_VERSION = 'LATEST'
    SHA1_FILENAME = 'sha1.yml'

    def self.from_file(config_path, logger=nil)
      Installer.new(YAML::load_file(config_path), logger)
    end

    def initialize(raw_config, logger=nil)
      raise(ArgumentError, 'killbill or kaui section must be specified') if raw_config['killbill'].nil? and raw_config['kaui'].nil?
      @config      = raw_config['killbill']
      @kaui_config = raw_config['kaui']

      if logger.nil?
        @logger       = Logger.new(STDOUT)
        @logger.level = Logger::INFO
      else
        @logger = logger
      end

      @nexus_config     = !@config.nil? ? @config['nexus'] : @kaui_config['nexus']
      @nexus_ssl_verify = !@nexus_config.nil? ? @nexus_config['ssl_verify'] : true
    end

    def install(force_download=false)
      @force_download = force_download
      @bundles_dir = @config['plugins_dir']
      @sha1_file = "#{@bundles_dir}/#{SHA1_FILENAME}"

      unless @config.nil?
        install_killbill_server
        install_plugins
        install_default_bundles
      end
      unless @kaui_config.nil?
        install_kaui
      end
    end

    private

    def install_killbill_server
      group_id    = @config['group_id'] || KPM::BaseArtifact::KILLBILL_GROUP_ID
      artifact_id = @config['artifact_id'] || KPM::BaseArtifact::KILLBILL_ARTIFACT_ID
      packaging   = @config['packaging'] || KPM::BaseArtifact::KILLBILL_PACKAGING
      classifier  = @config['classifier'] || KPM::BaseArtifact::KILLBILL_CLASSIFIER
      version     = @config['version'] || LATEST_VERSION
      webapp_path = @config['webapp_path'] || KPM::root

      KPM::KillbillServerArtifact.pull(@logger, group_id, artifact_id, packaging, classifier, version, webapp_path, nil, @force_download, @nexus_config, @nexus_ssl_verify)
    end

    def install_plugins
      install_java_plugins
      install_ruby_plugins
    end

    def install_java_plugins
      return if @config['plugins'].nil? or @config['plugins']['java'].nil?

      infos = []
      @config['plugins']['java'].each do |plugin|
        group_id    = plugin['group_id'] || KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID
        artifact_id = plugin['artifact_id'] || plugin['name']
        packaging   = plugin['packaging'] || KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_PACKAGING
        classifier  = plugin['classifier'] || KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_CLASSIFIER
        version     = plugin['version'] || LATEST_VERSION
        destination = "#{@bundles_dir}/plugins/java/#{artifact_id}/#{version}"

        infos << KPM::KillbillPluginArtifact.pull(@logger, group_id, artifact_id, packaging, classifier, version, destination, @sha1_file, @force_download, @nexus_config, @nexus_ssl_verify)
      end

      infos
    end

    def install_ruby_plugins
      return if @config['plugins'].nil? or @config['plugins']['ruby'].nil?

      infos = []
      @config['plugins']['ruby'].each do |plugin|
        group_id    = plugin['group_id'] || KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID
        artifact_id = plugin['artifact_id'] || plugin['name']
        packaging   = plugin['packaging'] || KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_PACKAGING
        classifier  = plugin['classifier'] || KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_CLASSIFIER
        version     = plugin['version'] || LATEST_VERSION
        destination = "#{@bundles_dir}/plugins/ruby"

        infos << KPM::KillbillPluginArtifact.pull(@logger, group_id, artifact_id, packaging, classifier, version, destination, @sha1_file, @force_download, @nexus_config, @nexus_ssl_verify)
      end

      infos
    end

    def install_default_bundles
      return if @config['default_bundles'] == false

      group_id    = 'org.kill-bill.billing'
      artifact_id = 'killbill-platform-osgi-bundles-defaultbundles'
      packaging   = 'tar.gz'
      classifier  = nil
      version     = @config['default_bundles_version'] || LATEST_VERSION
      destination = "#{@config['plugins_dir']}/platform"

      info = KPM::BaseArtifact.pull(@logger, group_id, artifact_id, packaging, classifier, version, destination, @sha1_file, @force_download, @nexus_config, @nexus_ssl_verify)

      # The special JRuby bundle needs to be called jruby.jar
      # TODO .first - code smell
      if  !info[:skipped]
        File.rename Dir.glob("#{destination}/killbill-platform-osgi-bundles-jruby-*.jar").first, "#{destination}/jruby.jar"
      end

      info
    end

    def install_kaui
      group_id    = @kaui_config['group_id'] || KPM::BaseArtifact::KAUI_GROUP_ID
      artifact_id = @kaui_config['artifact_id'] || KPM::BaseArtifact::KAUI_ARTIFACT_ID
      packaging   = @kaui_config['packaging'] || KPM::BaseArtifact::KAUI_PACKAGING
      classifier  = @kaui_config['classifier'] || KPM::BaseArtifact::KAUI_CLASSIFIER
      version     = @kaui_config['version'] || LATEST_VERSION
      webapp_path = @kaui_config['webapp_path'] || KPM::root

      KPM::KauiArtifact.pull(@logger, group_id, artifact_id, packaging, classifier, version, webapp_path, nil, @force_download, @nexus_config, @nexus_ssl_verify)
    end
  end
end
