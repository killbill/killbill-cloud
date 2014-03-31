require 'logger'
require 'yaml'

module KPM
  class Installer
    LATEST_VERSION = 'LATEST'

    def self.from_file(config_path, logger=nil)
      Installer.new(YAML::load_file(config_path), logger)
    end

    def initialize(raw_config, logger=nil)
      raise(ArgumentError, 'killbill section must be specified') if raw_config['killbill'].nil?
      @config = raw_config['killbill']

      if logger.nil?
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
      else
        @logger = logger
      end
    end

    def install
      install_killbill_server
      install_plugins
    end

    private

    def install_killbill_server
      version = @config['version'] || LATEST_VERSION
      webapp_path = @config['webapp_path'] || KPM::root

      webapp_dir = File.dirname(webapp_path)
      FileUtils.mkdir_p(webapp_dir)

      @logger.info "Installing Kill Bill server #{version} to #{webapp_path}"
      file = KillbillServerArtifact.pull(version, webapp_dir, @config['nexus'], @config['nexus']['ssl_verify'])
      FileUtils.mv file[:file_path], webapp_path
    end

    def install_plugins
      bundles_dir = @config['plugins_dir']

      install_java_plugins(bundles_dir)
      install_ruby_plugins(bundles_dir)
    end

    def install_java_plugins(bundles_dir)
      return if @config['plugins'].nil? or @config['plugins']['java'].nil?

      @config['plugins']['java'].each do |plugin|
        artifact_id = plugin['name']
        version = plugin['version'] || LATEST_VERSION
        destination = "#{bundles_dir}/plugins/java/#{artifact_id}/#{version}"

        FileUtils.mkdir_p(destination)

        @logger.info "Installing Kill Bill Java plugin #{artifact_id} #{version} to #{destination}"
        KillbillPluginArtifact.pull(artifact_id, version, :java, destination, @config['nexus'], @config['nexus']['ssl_verify'])
      end
    end

    def install_ruby_plugins(bundles_dir)
      return if @config['plugins'].nil? or @config['plugins']['ruby'].nil?

      @config['plugins']['ruby'].each do |plugin|
        artifact_id = plugin['name']
        version = plugin['version'] || LATEST_VERSION
        destination = "#{bundles_dir}/plugins/ruby"

        FileUtils.mkdir_p(destination)

        @logger.info "Installing Kill Bill Ruby plugin #{artifact_id} #{version} to #{destination}"
        archive = KillbillPluginArtifact.pull(artifact_id, version, :ruby, destination, @config['nexus'], @config['nexus']['ssl_verify'])

        Utils.unpack_tgz(archive[:file_path], destination)
        FileUtils.rm archive[:file_path]
      end
    end
  end
end