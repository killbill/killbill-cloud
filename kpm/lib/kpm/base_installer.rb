require 'pathname'

module KPM
  class BaseInstaller

    LATEST_VERSION = 'LATEST'
    SHA1_FILENAME = 'sha1.yml'
    DEFAULT_BUNDLES_DIR = Pathname.new('/var').join('tmp').join('bundles').to_s

    def initialize(logger, nexus_config, nexus_ssl_verify)
      @logger = logger
      @nexus_config = nexus_config
      @nexus_ssl_verify = nexus_ssl_verify
    end

    def install_killbill_server(specified_group_id=nil, specified_artifact_id=nil, specified_packaging=nil, specified_classifier=nil, specified_version=nil, specified_webapp_path=nil, force_download=false, verify_sha1=true)
      group_id = specified_group_id || KPM::BaseArtifact::KILLBILL_GROUP_ID
      artifact_id = specified_artifact_id || KPM::BaseArtifact::KILLBILL_ARTIFACT_ID
      packaging = specified_packaging || KPM::BaseArtifact::KILLBILL_PACKAGING
      classifier = specified_classifier || KPM::BaseArtifact::KILLBILL_CLASSIFIER
      version = specified_version || LATEST_VERSION
      webapp_path = specified_webapp_path || KPM::root

      @logger.debug("Installing Kill Bill server: group_id=#{group_id} artifact_id=#{artifact_id} packaging=#{packaging} classifier=#{classifier} version=#{version} webapp_path=#{webapp_path}")
      KPM::KillbillServerArtifact.pull(@logger,
                                       group_id,
                                       artifact_id,
                                       packaging,
                                       classifier,
                                       version,
                                       webapp_path,
                                       nil,
                                       force_download,
                                       verify_sha1,
                                       @nexus_config,
                                       @nexus_ssl_verify)
    end

    def install_kaui(specified_group_id=nil, specified_artifact_id=nil, specified_packaging=nil, specified_classifier=nil, specified_version=nil, specified_webapp_path=nil, force_download=false, verify_sha1=true)
      group_id = specified_group_id || KPM::BaseArtifact::KAUI_GROUP_ID
      artifact_id = specified_artifact_id || KPM::BaseArtifact::KAUI_ARTIFACT_ID
      packaging = specified_packaging || KPM::BaseArtifact::KAUI_PACKAGING
      classifier = specified_classifier || KPM::BaseArtifact::KAUI_CLASSIFIER
      version = specified_version || LATEST_VERSION
      webapp_path = specified_webapp_path || KPM::root

      @logger.debug("Installing Kaui: group_id=#{group_id} artifact_id=#{artifact_id} packaging=#{packaging} classifier=#{classifier} version=#{version} webapp_path=#{webapp_path}")
      KPM::KauiArtifact.pull(@logger,
                             group_id,
                             artifact_id,
                             packaging,
                             classifier,
                             version,
                             webapp_path,
                             nil,
                             force_download,
                             verify_sha1,
                             @nexus_config,
                             @nexus_ssl_verify)
    end

    def install_plugin(specified_group_id, specified_artifact_id, specified_packaging=nil, specified_classifier=nil, specified_version=nil, bundles_dir=nil, specified_type='java', force_download=false, verify_sha1=true)
      looked_up_group_id, looked_up_artifact_id, looked_up_packaging, looked_up_classifier, looked_up_version, looked_up_type = KPM::PluginsDirectory.lookup(specified_artifact_id, true)

      # Specified parameters have always precedence except for the artifact_id (to map stripe to stripe-plugin)
      artifact_id = looked_up_artifact_id || specified_artifact_id
      if artifact_id.nil?
        @logger.warn("Aborting installation: unable to lookup plugin #{specified_artifact_id}")
        return nil
      end

      bundles_dir = Pathname.new(bundles_dir || DEFAULT_BUNDLES_DIR).expand_path
      plugins_dir = bundles_dir.join('plugins')

      type = specified_type || looked_up_type
      if type == 'java'
        group_id = specified_group_id || looked_up_group_id || KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID
        packaging = specified_packaging || looked_up_packaging || KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_PACKAGING
        classifier = specified_classifier || looked_up_classifier || KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_CLASSIFIER
        version = specified_version || looked_up_version || LATEST_VERSION
        destination = plugins_dir.join('java').join(artifact_id).join(version)
      else
        group_id = specified_group_id || looked_up_group_id || KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID
        packaging = specified_packaging || looked_up_packaging || KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_PACKAGING
        classifier = specified_classifier || looked_up_classifier || KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_CLASSIFIER
        version = specified_version || looked_up_version || LATEST_VERSION
        destination = plugins_dir.join('ruby')
      end
      sha1_file = "#{bundles_dir}/#{SHA1_FILENAME}"

      @logger.debug("Installing plugin: group_id=#{group_id} artifact_id=#{artifact_id} packaging=#{packaging} classifier=#{classifier} version=#{version} destination=#{destination}")
      artifact_info = KPM::KillbillPluginArtifact.pull(@logger,
                                                       group_id,
                                                       artifact_id,
                                                       packaging,
                                                       classifier,
                                                       version,
                                                       destination,
                                                       sha1_file,
                                                       force_download,
                                                       verify_sha1,
                                                       @nexus_config,
                                                       @nexus_ssl_verify)

      # Mark this bundle as active
      plugins_manager = PluginsManager.new(plugins_dir, @logger)
      if artifact_info[:bundle_dir].nil?
        # In case the artifact on disk already existed and the installation is skipped,
        # we don't know the plugin name on disk (arbitrary if it's a .tar.gz). That being said,
        # we can guess it for Kill Bill plugins (using our naming conventions)
        plugins_manager.set_active(plugins_manager.guess_plugin_name(artifact_id), version)
      else
        plugins_manager.set_active(artifact_info[:bundle_dir])
      end

      artifact_info
    end

    def install_default_bundles(bundles_dir, specified_version=nil, kb_version=nil, force_download=false, verify_sha1=true)
      group_id = 'org.kill-bill.billing'
      artifact_id = 'killbill-platform-osgi-bundles-defaultbundles'
      packaging = 'tar.gz'
      classifier = nil

      version = specified_version
      if version.nil?
        info = KPM::KillbillServerArtifact.info(kb_version, @nexus_config, @nexus_ssl_verify)
        version = info['killbill-platform']
      end
      version ||= LATEST_VERSION

      bundles_dir = Pathname.new(bundles_dir || DEFAULT_BUNDLES_DIR).expand_path
      destination = bundles_dir.join('platform')
      sha1_file = bundles_dir.join(SHA1_FILENAME)

      @logger.debug("Installing default bundles: group_id=#{group_id} artifact_id=#{artifact_id} packaging=#{packaging} classifier=#{classifier} version=#{version} destination=#{destination}")
      info = KPM::BaseArtifact.pull(@logger,
                                    group_id,
                                    artifact_id,
                                    packaging,
                                    classifier,
                                    version,
                                    destination,
                                    sha1_file,
                                    force_download,
                                    verify_sha1,
                                    @nexus_config,
                                    @nexus_ssl_verify)

      # The special JRuby bundle needs to be called jruby.jar
      # TODO .first - code smell
      unless info[:skipped]
        File.rename Dir.glob("#{destination}/killbill-platform-osgi-bundles-jruby-*.jar").first, destination.join('jruby.jar')
      end

      info
    end
  end
end
