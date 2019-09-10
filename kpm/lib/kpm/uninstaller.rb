# frozen_string_literal: true

require 'pathname'

module KPM
  class Uninstaller
    def initialize(destination, logger = nil)
      @logger = logger
      if @logger.nil?
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
      end

      @destination = (destination || KPM::BaseInstaller::DEFAULT_BUNDLES_DIR)
      refresh_installed_plugins

      plugins_installation_path = File.join(@destination, 'plugins')
      @plugins_manager = PluginsManager.new(plugins_installation_path, @logger)

      sha1_file_path = File.join(@destination, KPM::BaseInstaller::SHA1_FILENAME)
      @sha1checker = KPM::Sha1Checker.from_file(sha1_file_path, @logger)
    end

    def uninstall_plugin(plugin, force = false)
      plugin_info = find_plugin(plugin)
      raise "No plugin with key/name '#{plugin}' found installed. Try running 'kpm inspect' for more info" unless plugin_info

      remove_all_plugin_versions(plugin_info, force)
    end

    def uninstall_non_default_plugins(dry_run = false)
      plugins = categorize_plugins

      if plugins[:to_be_deleted].empty?
        KPM.ui.say 'Nothing to do'
        return false
      end

      if dry_run
        msg = "The following plugin versions would be removed:\n"
        msg += plugins[:to_be_deleted].map { |p| "  #{p[0][:plugin_name]}: #{p[1]}" }.join("\n")
        msg += "\nThe following plugin versions would be kept:\n"
        msg += plugins[:to_keep].map { |p| "  #{p[0][:plugin_name]}: #{p[1]}" }.join("\n")
        KPM.ui.say msg
        false
      else
        plugins[:to_be_deleted].each do |p|
          remove_plugin_version(p[0], p[1])
        end
        true
      end
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

    def categorize_plugins
      plugins = { to_be_deleted: [], to_keep: [] }
      @installed_plugins.each do |_, info|
        info[:versions].each do |artifact|
          (artifact[:is_default] ? plugins[:to_keep] : plugins[:to_be_deleted]) << [info, artifact[:version]]
        end
      end
      plugins
    end

    def remove_all_plugin_versions(plugin_info, force = false)
      versions = plugin_info[:versions].map { |artifact| artifact[:version] }
      KPM.ui.say "Removing the following versions of the #{plugin_info[:plugin_name]} plugin: #{versions.join(', ')}"
      if !force && versions.length > 1
        return false unless KPM.ui.ask('Are you sure you want to continue?', limited_to: %w[y n]) == 'y'
      end

      versions.each do |version|
        remove_plugin_version(plugin_info, version)
      end
      true
    end

    def remove_plugin_version(plugin_info, version)
      # Be safe
      raise ArgumentError, 'plugin_path is empty' if plugin_info[:plugin_path].empty?
      raise ArgumentError, "version is empty (plugin_path=#{plugin_info[:plugin_path]})" if version.empty?

      plugin_version_path = File.expand_path(File.join(plugin_info[:plugin_path], version))
      safe_rmrf(plugin_version_path)

      remove_sha1_entry(plugin_info, version)

      # Remove the identifier if this was the last version installed
      refresh_installed_plugins
      if @installed_plugins[plugin_info[:plugin_name]][:versions].empty?
        safe_rmrf(plugin_info[:plugin_path])
        @plugins_manager.remove_plugin_identifier_key(plugin_info[:plugin_key])
      end

      refresh_installed_plugins
    end

    def remove_sha1_entry(plugin_info, version)
      coordinates = KPM::Coordinates.build_coordinates(group_id: plugin_info[:group_id],
                                                       artifact_id: plugin_info[:artifact_id],
                                                       packaging: plugin_info[:packaging],
                                                       classifier: plugin_info[:classifier],
                                                       version: version)
      @sha1checker.remove_entry!(coordinates)
    end

    def refresh_installed_plugins
      @installed_plugins = Inspector.new.inspect(@destination)
    end

    def safe_rmrf(dir)
      validate_dir_for_rmrf(dir)
      FileUtils.rmtree(dir)
    end

    def validate_dir_for_rmrf(dir)
      raise ArgumentError, "Path #{dir} is not a valid directory" unless File.directory?(dir)
      raise ArgumentError, "Path #{dir} is not a subdirectory of #{@destination}" unless Pathname.new(dir).fnmatch?(File.join(@destination, '**'))
    end
  end
end
