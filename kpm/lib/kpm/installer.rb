require 'logger'
require 'yaml'

module KPM
  class Installer
    LATEST_VERSION = 'LATEST'

    def self.from_file(config_path, logger=nil)
      Installer.new(YAML::load_file(config_path), logger)
    end

    def initialize(raw_config, logger=nil)
      raise(ArgumentError, 'killbill or kaui section must be specified') if raw_config['killbill'].nil? and raw_config['kaui'].nil?
      @config = raw_config['killbill']
      @kaui_config = raw_config['kaui']

      if logger.nil?
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
      else
        @logger = logger
      end
    end

    def install
      unless @config.nil?
        install_killbill_server
        install_plugins
        install_default_bundles
      end
      unless @kaui_config.nil?
        install_kaui
      end
    end

    private

    def install_killbill_server
      group_id = @config['group_id'] || BaseArtifact::KILLBILL_GROUP_ID
      artifact_id = @config['artifact_id'] || KillbillServerArtifact::KILLBILL_ARTIFACT_ID
      packaging = @config['packaging'] || KillbillServerArtifact::KILLBILL_PACKAGING
      classifier = @config['classifier'] || KillbillServerArtifact::KILLBILL_CLASSIFIER
      version = @config['version'] || LATEST_VERSION
      webapp_path = @config['webapp_path'] || KPM::root

      webapp_dir = File.dirname(webapp_path)
      FileUtils.mkdir_p(webapp_dir)

      @logger.info "Installing Kill Bill server (#{group_id}:#{artifact_id}:#{packaging}:#{classifier}:#{version}) to #{webapp_path}"
      file = KillbillServerArtifact.pull(group_id, artifact_id, packaging, classifier, version, webapp_dir, @config['nexus'], @config['nexus']['ssl_verify'])
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

        Utils.unpack_tgz(archive[:file_path], destination, true)
        FileUtils.rm archive[:file_path]
      end
    end

    def install_default_bundles
      return if @config['default_bundles'] == false

      group_id = 'org.kill-bill.billing'
      artifact_id = 'killbill-osgi-bundles-defaultbundles'
      packaging = 'tar.gz'
      version = @config['version'] || LATEST_VERSION
      destination = "#{@config['plugins_dir']}/platform"

      FileUtils.mkdir_p(destination)

      @logger.info "Installing Kill Bill #{artifact_id} #{version} to #{destination}"
      archive = BaseArtifact.pull(group_id, artifact_id, packaging, version, destination, @config['nexus'], @config['nexus']['ssl_verify'])

      Utils.unpack_tgz(archive[:file_path], destination)
      FileUtils.rm archive[:file_path]

      # The special JRuby bundle needs to be called jruby.jar
      File.rename Dir.glob("#{destination}/killbill-osgi-bundles-jruby-*.jar").first, "#{destination}/jruby.jar"
    end

    def install_kaui
      version = @kaui_config['version'] || LATEST_VERSION
      webapp_path = @kaui_config['webapp_path'] || KPM::root

      webapp_dir = File.dirname(webapp_path)
      FileUtils.mkdir_p(webapp_dir)

      @logger.info "Installing Kaui #{version} to #{webapp_path}"
      file = KauiArtifact.pull(version, webapp_dir, @kaui_config['nexus'], @kaui_config['nexus']['ssl_verify'])
      FileUtils.mv file[:file_path], webapp_path
    end
  end
end
