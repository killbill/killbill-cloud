require 'pathname'

module KPM
  class PluginsManager

    def initialize(plugins_dir, logger)
      @plugins_dir = Pathname.new(plugins_dir)
      @logger = logger
    end

    def set_active(plugin_name_or_path, plugin_version=nil)
      if plugin_version.nil?
        # Full path specified, with version
        link = Pathname.new(plugin_name_or_path).join('../ACTIVE')
        FileUtils.rm_f(link)
        FileUtils.ln_s(plugin_name_or_path, link, :force => true)
      else
        plugin_dir_glob = @plugins_dir.join('*').join(plugin_name_or_path)
        # Only one should match (java or ruby plugin)
        Dir.glob(plugin_dir_glob).each do |plugin_dir_path|
          plugin_dir = Pathname.new(plugin_dir_path)
          link = plugin_dir.join('ACTIVE')
          FileUtils.rm_f(link)
          FileUtils.ln_s(plugin_dir.join(plugin_version), link, :force => true)
        end
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

    private

    # Note: the plugin name here is the directory name on the filesystem
    def update_fs(plugin_name_or_path, plugin_version=nil, &block)
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
