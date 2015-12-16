require 'pathname'
require 'json'

module KPM
  class PluginsManager

    def initialize(plugins_dir, logger)
      @plugins_dir = Pathname.new(plugins_dir)
      @logger = logger
    end

    def set_active(plugin_name_or_path, plugin_version=nil)
      if plugin_name_or_path.nil?
        @logger.warn('Unable to mark a plugin as active: no name or path specified')
        return
      end

      if plugin_version.nil?
        # Full path specified, with version
        link = Pathname.new(plugin_name_or_path).join('../ACTIVE')
        FileUtils.rm_f(link)
        FileUtils.ln_s(plugin_name_or_path, link, :force => true)
      else
        # Plugin name (fs directory) specified
        plugin_dir_glob = @plugins_dir.join('*').join(plugin_name_or_path)
        # Only one should match (java or ruby plugin)
        Dir.glob(plugin_dir_glob).each do |plugin_dir_path|
          plugin_dir = Pathname.new(plugin_dir_path)
          link = plugin_dir.join('ACTIVE')
          FileUtils.rm_f(link)
          FileUtils.ln_s(plugin_dir.join(plugin_version), link, :force => true)
        end
      end

      update_fs(plugin_name_or_path, plugin_version) do |tmp_dir|
        FileUtils.rm_f(tmp_dir.join('stop.txt'))
        FileUtils.rm_f(tmp_dir.join('restart.txt'))
      end
    end

    def uninstall(plugin_name_or_path, plugin_version=nil)
      update_fs(plugin_name_or_path, plugin_version) do |tmp_dir|
        FileUtils.rm_f(tmp_dir.join('restart.txt'))
        # Be safe, keep the code, just never start it
        FileUtils.touch(tmp_dir.join('stop.txt'))
      end
    end

    def restart(plugin_name_or_path, plugin_version=nil)
      update_fs(plugin_name_or_path, plugin_version) do |tmp_dir|
        # Remove stop.txt so that the plugin is started if it was stopped
        FileUtils.rm_f(tmp_dir.join('stop.txt'))
        FileUtils.touch(tmp_dir.join('restart.txt'))
      end
    end

    def validate_plugin_identifier_key(plugin_key, coordinates)

      identifiers = read_plugin_identifiers
      entry = identifiers[plugin_key]
      if entry
        [:group_id, :artifact_id, :packaging, :classifier, :version].each_with_index do |value_type, idx|
          return false if !validate_plugin_identifier_key_value(plugin_key, value_type, entry[value_type.to_s], coordinates[idx])
        end
      end
      true
    end

    def add_plugin_identifier_key(plugin_key, plugin_name, language, coordinates)

      identifiers = read_plugin_identifiers
      # If key does not already exists we update it, if not nothing to do
      if !identifiers.has_key?(plugin_key)

        entry = {'plugin_name' => plugin_name}
        entry['language'] = language
        if coordinates
          entry['group_id'] = coordinates[0]
          entry['artifact_id'] = coordinates[1]
          entry['packaging'] = coordinates[2]
          entry['classifier'] = coordinates[3]
          entry['version'] = coordinates[4]
        end
        identifiers[plugin_key] = entry
        write_plugin_identifiers(identifiers)
      end

      identifiers
    end

    def remove_plugin_identifier_key(plugin_key)

      identifiers = read_plugin_identifiers
      # If key does not already exists we update it, if not nothing to do.
      if identifiers.has_key?(plugin_key)
        identifiers.delete(plugin_key)
        write_plugin_identifiers(identifiers)
      end

      identifiers
    end


    def get_plugin_name_from_key(plugin_key)
      begin
        identifiers = File.open(path, 'r') do |f|
          JSON.parse(f.read)
        end
        identifiers[plugin_key]
      rescue Errno::ENOENT
        nil
      end
    end


    def guess_plugin_name(artifact_id)
      return nil if artifact_id.nil?
      captures = artifact_id.scan(/(.*)-plugin/)
      if captures.empty? || captures.first.nil? || captures.first.first.nil?
        short_name = artifact_id
      else
        # 'analytics-plugin' or 'stripe-plugin' passed
        short_name = captures.first.first
      end
      Dir.glob(@plugins_dir.join('*').join('*')).each do |plugin_path|
        plugin_name = File.basename(plugin_path)
        if plugin_name == short_name ||
            plugin_name == artifact_id ||
            !plugin_name.scan(/-#{short_name}/).empty? ||
            !plugin_name.scan(/#{short_name}-/).empty?
          return plugin_name
        end
      end
      nil
    end

    private

    def validate_plugin_identifier_key_value(plugin_key, value_type, entry_value, coordinate_value)
      # The json does not contain the coordinates (case when installed from install_plugin_from_fs)
      return true if entry_value.nil?

      if entry_value != coordinate_value
        @logger.warn("Entry in plugin_identifiers.json for key #{plugin_key} does not match for coordinate #{value_type}: got #{coordinate_value} instead of #{entry_value}")
        return false
      end
      true
    end

    def read_plugin_identifiers
      path = Pathname.new(@plugins_dir).join('plugin_identifiers.json')
      identifiers = {}
      begin
        identifiers = File.open(path, 'r') do |f|
          JSON.parse(f.read)
        end
      rescue Errno::ENOENT
      end
      identifiers
    end

    def write_plugin_identifiers(identifiers)

      path = Pathname.new(@plugins_dir).join('plugin_identifiers.json')
      Dir.mktmpdir do |tmp_dir|
        tmp_path = Pathname.new(tmp_dir).join('plugin_identifiers.json')
        File.open(tmp_path, 'w') do |f|
          f.write(identifiers.to_json)
        end

        FileUtils.mv(tmp_path, path)
      end
    end

    # Note: the plugin name here is the directory name on the filesystem
    def update_fs(plugin_name_or_path, plugin_version=nil, &block)
      if plugin_name_or_path.nil?
        @logger.warn('Unable to update the filesystem: no name or path specified')
        return
      end

      p = plugin_version.nil? ? plugin_name_or_path : @plugins_dir.join('*').join(plugin_name_or_path).join(plugin_version == :all ? '*' : plugin_version)

      modified = []
      Dir.glob(p).each do |plugin_dir_path|
        plugin_dir = Pathname.new(plugin_dir_path)
        tmp_dir = plugin_dir.join('tmp')
        FileUtils.mkdir_p(tmp_dir)

        yield(tmp_dir) if block_given?

        modified << plugin_dir
      end

      if modified.empty?
        if plugin_version.nil?
          @logger.warn("No plugin found with name #{plugin_name_or_path}. Installed plugins: #{Dir.glob(@plugins_dir.join('*').join('*'))}")
        else
          @logger.warn("No plugin found with name #{plugin_name_or_path} and version #{plugin_version}. Installed plugins: #{Dir.glob(@plugins_dir.join('*').join('*').join('*'))}")
        end
      end

      modified
    end
  end
end
