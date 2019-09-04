# frozen_string_literal: true

module KPM
  class Inspector
    def initialize; end

    def inspect(bundles_dir)
      bundles_dir = Pathname.new(bundles_dir || KPM::BaseInstaller::DEFAULT_BUNDLES_DIR).expand_path
      plugins = bundles_dir.join('plugins')
      ruby_plugins_path = bundles_dir.join('plugins/ruby')
      java_plugins_path = bundles_dir.join('plugins/java')

      all_plugins = {}
      build_plugins_for_type(ruby_plugins_path, 'ruby', all_plugins)
      build_plugins_for_type(java_plugins_path, 'java', all_plugins)

      add_plugin_identifier_info(plugins, all_plugins)

      add_sha1_info(bundles_dir, all_plugins)

      all_plugins
    end

    def format(all_plugins)
      formatter = KPM::Formatter.new
      formatter.format(all_plugins)
    end

    private

    def add_sha1_info(bundles_dir, all_plugins)
      sha1_filename = KPM::BaseInstaller::SHA1_FILENAME
      sha1_file = "#{bundles_dir}/#{sha1_filename}"
      sha1_checker = Sha1Checker.from_file(sha1_file)

      all_plugins.keys.each do |cur_plugin_name|
        cur = all_plugins[cur_plugin_name]

        sha1_checker.all_sha1.each do |e|
          coord, sha1 = e
          coordinate_map = KPM::Coordinates.get_coordinate_map(coord)

          next unless coordinate_map[:group_id] == cur[:group_id] &&
                      coordinate_map[:artifact_id] == cur[:artifact_id] &&
                      coordinate_map[:packaging] == cur[:packaging]

          found_version = cur[:versions].select { |v| v[:version] == coordinate_map[:version] }[0]
          found_version[:sha1] = sha1 if found_version
        end
      end
    end

    def add_plugin_identifier_info(plugins, all_plugins)
      plugins_manager = PluginsManager.new(plugins, @logger)
      all_plugins.keys.each do |cur|
        plugin_key, entry = plugins_manager.get_identifier_key_and_entry(cur)
        all_plugins[cur][:plugin_key] = plugin_key
        all_plugins[cur][:group_id] = entry ? entry['group_id'] : nil
        all_plugins[cur][:artifact_id] = entry ? entry['artifact_id'] : nil
        all_plugins[cur][:packaging] = entry ? entry['packaging'] : nil
        all_plugins[cur][:classifier] = entry ? entry['classifier'] : nil
      end
    end

    def build_plugins_for_type(plugins_path, type, res)
      return [] unless File.exist?(plugins_path)

      get_entries(plugins_path).each_with_object(res) do |e, out|
        plugin_map = build_plugin_map(e, plugins_path.join(e), type)
        out[e] = plugin_map
      end
    end

    def build_plugin_map(plugin_name, plugin_path, type)
      plugin_map = { plugin_name: plugin_name, plugin_path: plugin_path.to_s, type: type }
      entries = get_entries(plugin_path)
      set_default = entries.select { |e| e == 'SET_DEFAULT' }[0]
      default_version = File.basename(File.readlink(plugin_path.join(set_default))) if set_default

      versions = entries.reject do |e|
        e == 'SET_DEFAULT'
      end.each_with_object([]) do |e, out|
        is_disabled = File.exist?(plugin_path.join(e).join('tmp').join('disabled.txt'))
        out << { version: e, is_default: default_version == e, is_disabled: is_disabled, sha1: nil }
      end

      versions.sort! { |a, b| a[:version] <=> b[:version] }
      plugin_map[:versions] = versions || []

      plugin_map
    end

    def get_entries(path)
      Dir.entries(path).select { |entry| entry != '.' && entry != '..' && File.directory?(File.join(path, entry)) }
    end
  end
end
