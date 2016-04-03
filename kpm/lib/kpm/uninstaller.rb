module KPM
  class Uninstaller
    def initialize(destination, logger = nil)
      @logger = logger
      if @logger.nil?
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
      end

      destination ||= KPM::BaseInstaller::DEFAULT_BUNDLES_DIR
      @installed_plugins = Inspector.new.inspect(destination)

      plugins_installation_path = File.join(destination, 'plugins')
      @plugins_manager = PluginsManager.new(plugins_installation_path, @logger)

      sha1_file_path = File.join(destination, KPM::BaseInstaller::SHA1_FILENAME)
      @sha1checker = KPM::Sha1Checker.from_file(sha1_file_path, @logger)
    end

    def uninstall_plugin(plugin, force = false)
      plugin_info = find_plugin(plugin)
      raise "No plugin with key/name '#{plugin}' found installed. Try running 'kpm inspect' for more info" unless plugin_info

      remove_all_plugin_versions(plugin_info, force)
    end

    private

    def find_plugin(plugin)
      plugin_info = @installed_plugins[plugin]
      if plugin_info.nil?
        @installed_plugins.each do |_, info|
          if info[:plugin_key] == plugin
            plugin_info = info
            break
          end
        end
      end

      plugin_info
    end

    def remove_all_plugin_versions(plugin_info, force = false)
      versions = plugin_info[:versions].map { |artifact| artifact[:version] }
      KPM.ui.say "Removing the following versions of the #{plugin_info[:plugin_name]} plugin: #{versions.join(', ')}"
      if !force && versions.length > 1
        return false unless 'y' == KPM.ui.ask('Are you sure you want to continue?', limited_to: %w(y n))
      end

      FileUtils.rmtree(plugin_info[:plugin_path])

      @plugins_manager.remove_plugin_identifier_key(plugin_info[:plugin_key])
      versions.each do |version|
        remove_sha1_entry(plugin_info, version)
      end

      true
    end

    def remove_sha1_entry(plugin_info, version)
      coordinates = KPM::Coordinates.build_coordinates(group_id: plugin_info[:group_id],
                                                       artifact_id: plugin_info[:artifact_id],
                                                       packaging: plugin_info[:packaging],
                                                       classifier: plugin_info[:classifier],
                                                       version: version)
      @sha1checker.remove_entry!(coordinates)
    end
  end
end
