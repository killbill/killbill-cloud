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
      bundles_dir = @config['plugins_dir'] || DEFAULT_BUNDLES_DIR

      help = nil
      unless @config.nil?
        help = install_tomcat if @config['webapp_path'].nil?
        install_killbill_server(@config['group_id'], @config['artifact_id'], @config['packaging'], @config['classifier'], @config['version'], @config['webapp_path'], force_download, verify_sha1)
        install_plugins(bundles_dir, force_download, verify_sha1)
        unless @config['default_bundles'] == false
          install_default_bundles(bundles_dir, @config['default_bundles_version'], @config['version'], force_download, verify_sha1)
        end
        clean_up_descriptors(bundles_dir)
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
      unless @kaui_config.nil?
        @kaui_config['webapp_path'] = Pathname.new(File.dirname(root_war_path)).join('kaui.war').to_s
      end

      # Help message
      manager.help
    end

    def install_plugins(bundles_dir, force_download, verify_sha1)
      install_java_plugins(bundles_dir, force_download, verify_sha1)
      install_ruby_plugins(bundles_dir, force_download, verify_sha1)
    end

    def install_java_plugins(bundles_dir, force_download, verify_sha1)
      return if @config['plugins'].nil? or @config['plugins']['java'].nil?

      infos = []
      @config['plugins']['java'].each do |plugin|
        infos << install_plugin(plugin['name'], nil, plugin['group_id'], plugin['artifact_id'], plugin['packaging'], plugin['classifier'], plugin['version'], bundles_dir, 'java', force_download, verify_sha1, false)
      end

      infos
    end

    def install_ruby_plugins(bundles_dir, force_download, verify_sha1)
      return if @config['plugins'].nil? or @config['plugins']['ruby'].nil?

      verify_jruby_jar=true
      infos = []
      @config['plugins']['ruby'].each do |plugin|
        infos << install_plugin(plugin['name'], nil, plugin['group_id'], plugin['artifact_id'], plugin['packaging'], plugin['classifier'], plugin['version'], bundles_dir, 'ruby', force_download, verify_sha1, verify_jruby_jar)
        verify_jruby_jar=false
      end

      infos
    end

    def clean_up_descriptors(bundles_dir)
      removed_plugins = clean_up_plugin_identifiers(bundles_dir)
      clean_up_sha1s(removed_plugins, bundles_dir)
    end

    def clean_up_plugin_identifiers(bundles_dir)
      inspector = KPM::Inspector.new
      installed_plugins = inspector.inspect(bundles_dir)

      plugins_installation_path = File.join(bundles_dir, 'plugins')
      plugins_manager = KPM::PluginsManager.new(plugins_installation_path, @logger)

      plugin_identifiers = plugins_manager.read_plugin_identifiers
      removed_identifiers = []
      plugin_identifiers.each do |plugin_key, plugin|
        if !installed_plugins.has_key?(plugin['plugin_name'])
          _, plugin_entry = plugins_manager.get_identifier_key_and_entry(plugin_key)
          plugins_manager.remove_plugin_identifier_key(plugin_key)
          removed_identifiers << plugin_entry
        end
      end

      removed_identifiers
    end

    def clean_up_sha1s(removed_plugins, plugins_dir)
      sha1checker = KPM::Sha1Checker.from_file(File.join(plugins_dir, KPM::BaseInstaller::SHA1_FILENAME))
      removed_plugins.each do |removed|
        coordinates = KPM::Coordinates.build_coordinates(group_id: removed['group_id'],
                                                         artifact_id: removed['artifact_id'],
                                                         packaging: removed['packaging'],
                                                         classifier: removed['classifier'],
                                                         version: removed['version'])
        sha1checker.remove_entry!(coordinates)
      end
    end

  end
end
