require 'logger'
require 'pathname'
require 'yaml'

module KPM
  class Installer < BaseInstaller

    def self.from_file(config_path=nil, logger=nil)
      if config_path.nil?
        # Install Kill Bill, Kaui and the KPM plugin by default
        config = {'killbill' => {'version' => 'LATEST', 'plugins' => {'ruby' => [{'name' => 'kpm'}]}}, 'kaui' => {'version' => 'LATEST'}}
      else
        config = YAML::load_file(config_path)
      end
      Installer.new(config, logger)
    end

    def initialize(raw_config, logger=nil)
      @config = raw_config['killbill']
      @kaui_config = raw_config['kaui']

      if logger.nil?
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
      end

      nexus_config = !@config.nil? ? @config['nexus'] : (!@kaui_config.nil? ? @kaui_config['nexus'] : nil)
      nexus_ssl_verify = !nexus_config.nil? ? nexus_config['ssl_verify'] : true

      super(logger, nexus_config, nexus_ssl_verify)
    end

    def install(force_download=false, verify_sha1=true)
      help = nil
      unless @config.nil?
        help = install_tomcat if @config['webapp_path'].nil?
        install_killbill_server(@config['group_id'], @config['artifact_id'], @config['packaging'], @config['classifier'], @config['version'], @config['webapp_path'], force_download, verify_sha1)
        install_plugins(force_download, verify_sha1)
        unless @config['default_bundles'] == false
          install_default_bundles(@config['plugins_dir'], @config['default_bundles_version'], @config['version'], force_download, verify_sha1)
        end
      end

      unless @kaui_config.nil?
        if @kaui_config['webapp_path'].nil?
          @logger.warn('No webapp_path specified for Kaui, aborting installation')
          return
        end

        install_kaui(@kaui_config['group_id'], @kaui_config['artifact_id'], @kaui_config['packaging'], @kaui_config['classifier'], @kaui_config['version'], @kaui_config['webapp_path'], force_download, verify_sha1)
      end

      help
    end

    private

    def install_tomcat(dir=Dir.pwd)
      # Download and unpack Tomcat
      manager = KPM::TomcatManager.new(dir, @logger)
      manager.download

      # Update main config
      root_war_path = manager.setup
      @config['webapp_path'] = root_war_path
      @kaui_config['webapp_path'] = Pathname.new(File.dirname(root_war_path)).join('kaui.war').to_s

      # Help message
      manager.help
    end

    def install_plugins(force_download, verify_sha1)
      install_java_plugins(force_download, verify_sha1)
      install_ruby_plugins(force_download, verify_sha1)
    end

    def install_java_plugins(force_download, verify_sha1)
      return if @config['plugins'].nil? or @config['plugins']['java'].nil?

      infos = []
      @config['plugins']['java'].each do |plugin|
        infos << install_plugin(plugin['group_id'], plugin['artifact_id'] || plugin['name'], plugin['packaging'], plugin['classifier'], plugin['version'], @config['plugins_dir'], 'java', force_download, verify_sha1)
      end

      infos
    end

    def install_ruby_plugins(force_download, verify_sha1)
      return if @config['plugins'].nil? or @config['plugins']['ruby'].nil?

      infos = []
      @config['plugins']['ruby'].each do |plugin|
        infos << install_plugin(plugin['group_id'], plugin['artifact_id'] || plugin['name'], plugin['packaging'], plugin['classifier'], plugin['version'], @config['plugins_dir'], 'ruby', force_download, verify_sha1)
      end

      infos
    end
  end
end
