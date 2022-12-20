# frozen_string_literal: true

require 'logger'
require 'pathname'
require 'yaml'

module KPM
  class Installer < BaseInstaller
    def self.from_file(config_path = nil, logger = nil)
      config = if config_path.nil?
                 # Install Kill Bill, Kaui and the KPM plugin by default
                 build_default_config
               else
                 YAML.load_file(config_path)
               end
      Installer.new(config, logger)
    end

    def self.build_default_config(all_kb_versions = nil)
      latest_stable_version = get_kb_latest_stable_version(all_kb_versions)

      {
        'killbill' => {
          'version' => latest_stable_version.to_s
        },
        'kaui' => {
          # Note: we assume no unstable version of Kaui is published today
          'version' => 'LATEST'
        }
      }
    end

    def self.get_kb_latest_stable_version(all_kb_versions = nil)
      all_kb_versions ||= KillbillServerArtifact.versions(KillbillServerArtifact::KILLBILL_ARTIFACT_ID,
                                                          KillbillServerArtifact::KILLBILL_PACKAGING,
                                                          KillbillServerArtifact::KILLBILL_CLASSIFIER,
                                                          nil,
                                                          true).to_a
      latest_stable_version = Gem::Version.new('0.0.0')
      all_kb_versions.each do |kb_version|
        version = begin
                    Gem::Version.new(kb_version)
                  rescue StandardError
                    nil
                  end
        next if version.nil?

        _major, minor, _patch, pre = version.segments
        next if !pre.nil? || minor.nil? || minor.to_i.odd?

        latest_stable_version = version if version > latest_stable_version
      end

      latest_stable_version.to_s
    end

    def initialize(raw_config, logger = nil)
      @config = raw_config['killbill']
      @kaui_config = raw_config['kaui']

      @config['version'] = KPM::Installer.get_kb_latest_stable_version if !@config.nil? && (@config['version'].nil? || @config['version'] == 'LATEST')

      if logger.nil?
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
      end

      nexus_config = if !@config.nil?
                       @config['nexus']
                     elsif !@kaui_config.nil?
                       @kaui_config['nexus']
                     else
                       nil
                     end
      nexus_ssl_verify = !nexus_config.nil? ? nexus_config['ssl_verify'] : true

      super(logger, nexus_config, nexus_ssl_verify)
    end

    def install(force_download = false, verify_sha1 = true)
      bundles_dir = if !@config.nil?
                      @config['plugins_dir']
                    elsif !@kaui_config.nil?
                      @kaui_config['plugins_dir']
                    else
                      nil
                    end
      bundles_dir ||= DEFAULT_BUNDLES_DIR

      unless @config.nil?
        raise ArgumentError, "Aborting installation, no webapp_path specified in config: #{@config}" if @config['webapp_path'].nil?

        install_killbill_server(@config['group_id'], @config['artifact_id'], @config['packaging'], @config['classifier'], @config['version'], @config['webapp_path'], bundles_dir, force_download, verify_sha1)
        install_plugins(bundles_dir, @config['version'], force_download, verify_sha1)
        install_default_bundles(bundles_dir, @config['default_bundles_version'], @config['version'], force_download, verify_sha1) unless @config['default_bundles'] == false
        clean_up_descriptors(bundles_dir)
      end

      unless @kaui_config.nil?
        if @kaui_config['webapp_path'].nil?
          @logger.warn('No webapp_path specified for Kaui, aborting installation')
          return
        end

        install_kaui(@kaui_config['group_id'], @kaui_config['artifact_id'], @kaui_config['packaging'], @kaui_config['classifier'], @kaui_config['version'], @kaui_config['webapp_path'], bundles_dir, force_download, verify_sha1)
      end

      @trace_logger.to_json
    end

    private

    def install_plugins(bundles_dir, raw_kb_version, force_download, verify_sha1)
      install_java_plugins(bundles_dir, raw_kb_version, force_download, verify_sha1)
    end

    def install_java_plugins(bundles_dir, raw_kb_version, force_download, verify_sha1)
      return if @config['plugins'].nil? || @config['plugins']['java'].nil?

      infos = []
      @config['plugins']['java'].each do |plugin|
        infos << install_plugin(plugin['name'], raw_kb_version, plugin['group_id'], plugin['artifact_id'], plugin['packaging'], plugin['classifier'], plugin['version'], bundles_dir, 'java', force_download, verify_sha1)
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
        next if installed_plugins.key?(plugin['plugin_name'])

        _, plugin_entry = plugins_manager.get_identifier_key_and_entry(plugin_key)
        plugins_manager.remove_plugin_identifier_key(plugin_key)
        removed_identifiers << plugin_entry
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
