module KPM
  class BaseInstaller

    LATEST_VERSION = 'LATEST'
    SHA1_FILENAME = 'sha1.yml'

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

      # Specified parameters have always precedence except for the artifact_id (to map stripe to killbill-stripe)
      artifact_id = looked_up_artifact_id || specified_artifact_id
      if artifact_id.nil?
        @logger.warn("Aborting installation: unable to lookup plugin #{specified_artifact_id}")
        return nil
      end

      type = specified_type || looked_up_type
      if type == 'java'
        group_id = specified_group_id || looked_up_group_id || KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID
        packaging = specified_packaging || looked_up_packaging || KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_PACKAGING
        classifier = specified_classifier || looked_up_classifier || KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_CLASSIFIER
        version = specified_version || looked_up_version || LATEST_VERSION
        destination = "#{bundles_dir}/plugins/java/#{artifact_id}/#{version}"
      else
        group_id = specified_group_id || looked_up_group_id || KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID
        packaging = specified_packaging || looked_up_packaging || KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_PACKAGING
        classifier = specified_classifier || looked_up_classifier || KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_CLASSIFIER
        version = specified_version || looked_up_version || LATEST_VERSION
        destination = "#{bundles_dir}/plugins/ruby"
      end
      sha1_file = "#{bundles_dir}/#{SHA1_FILENAME}"

      KPM::KillbillPluginArtifact.pull(@logger,
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
    end

    def install_default_bundles(bundles_dir, specified_version=nil, force_download=false, verify_sha1=true)
      group_id = 'org.kill-bill.billing'
      artifact_id = 'killbill-platform-osgi-bundles-defaultbundles'
      packaging = 'tar.gz'
      classifier = nil
      version = specified_version || LATEST_VERSION
      destination = "#{bundles_dir}/platform"
      sha1_file = "#{bundles_dir}/#{SHA1_FILENAME}"

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
        File.rename Dir.glob("#{destination}/killbill-platform-osgi-bundles-jruby-*.jar").first, "#{destination}/jruby.jar"
      end

      info
    end
  end
end
