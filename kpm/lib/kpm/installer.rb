require 'logger'
require 'yaml'

module KPM
  class Installer < BaseInstaller

    def self.from_file(config_path, logger=nil)
      Installer.new(YAML::load_file(config_path), logger)
    end

    def initialize(raw_config, logger=nil)
      raise(ArgumentError, 'killbill or kaui section must be specified') if raw_config['killbill'].nil? and raw_config['kaui'].nil?
      @config = raw_config['killbill']
      @kaui_config = raw_config['kaui']

      if logger.nil?
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
      end

      nexus_config = !@config.nil? ? @config['nexus'] : @kaui_config['nexus']
      nexus_ssl_verify = !nexus_config.nil? ? nexus_config['ssl_verify'] : true

      super(logger, nexus_config, nexus_ssl_verify)
    end

    def install(force_download=false, verify_sha1=true)
      unless @config.nil?
        install_killbill_server(@config['group_id'], @config['artifact_id'], @config['packaging'], @config['classifier'], @config['version'], @config['webapp_path'], force_download, verify_sha1)
        install_plugins(force_download, verify_sha1)
        unless @config['default_bundles'] == false
          install_default_bundles(@config['plugins_dir'], @config['default_bundles_version'], force_download, verify_sha1)
        end
      end

      unless @kaui_config.nil?
        install_kaui(@kaui_config['group_id'], @kaui_config['artifact_id'], @kaui_config['packaging'], @kaui_config['classifier'], @kaui_config['version'], @kaui_config['webapp_path'], force_download, verify_sha1)
      end
    end

    private

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
