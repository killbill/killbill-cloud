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


    def install_plugin(plugin_key, specified_group_id, specified_artifact_id, specified_packaging=nil, specified_classifier=nil, specified_version=nil, bundles_dir=nil, specified_type='java', force_download=false, verify_sha1=true)

      if plugin_key.nil?
        @logger.warn("Aborting installation: User needs to specify a pluginKey")
        return nil
      end

      # Since we allow to only specify a the artifact_id to identify a given plugin we set the default on the other fields
      specified_group_id = specified_group_id || (specified_type.to_s == 'java' ? KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID : KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID)
      specified_packaging = specified_packaging || (specified_type.to_s == 'java' ? KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_PACKAGING : KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_PACKAGING)
      specified_classifier = specified_classifier || (specified_type.to_s == 'java' ? KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_CLASSIFIER : KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_CLASSIFIER)

      # Create a Proc to validate and resolve arguments
      resolve_and_validate_args_proc = Proc.new { |plugin_key, arg_type, specified_arg, lookup_arg|

        # There is an entry in plugin_directory.yml but does not match with input
        if lookup_arg && specified_arg && lookup_arg.to_s != specified_arg.to_s
          @logger.warn("Aborting installation: User specified #{arg_type}=#{specified_arg} for pluginKey = #{plugin_key}, but plugin_directory.yml resolves with #{lookup_arg}")
          return nil
        end

        # There is no entry and user did not specify anything (or we did not have any default)
        if lookup_arg.nil? && specified_arg.nil?
          @logger.warn("Aborting installation: need to specify an #{arg_type} for pluginKey = #{plugin_key}")
          return nil
        end
        # If validation is successful we return resolved value
        specified_arg || lookup_arg
      }


      # Lookup entry (will come with null everywhere if entry does not exist in plugin_directory.yml)
      looked_up_group_id, looked_up_artifact_id, looked_up_packaging, looked_up_classifier, looked_up_version, looked_up_type = KPM::PluginsDirectory.lookup(plugin_key, true)

      # If there is no entry in plugins_directory.yml, the key provided must be a user key and must have a namespace
      if looked_up_artifact_id.nil? && plugin_key.split(':').size == 1
        @logger.warn("Aborting installation: pluginKey = #{plugin_key} does not exist in plugin_directory.yml so format of the key must have a user namespace (e.g namespace:key)")
        return nil
      end

      # Validate and resolve the value to use (user input has precedence)
      group_id = resolve_and_validate_args_proc.call(plugin_key, 'group_id', specified_group_id, looked_up_group_id)
      artifact_id = resolve_and_validate_args_proc.call(plugin_key, 'artifact_id', specified_artifact_id, looked_up_artifact_id)
      packaging = resolve_and_validate_args_proc.call(plugin_key, 'packaging', specified_packaging, looked_up_packaging)
      classifier = specified_classifier || looked_up_classifier
      type = resolve_and_validate_args_proc.call(plugin_key, 'type', specified_type, looked_up_type).to_s
      version = specified_version || looked_up_version || LATEST_VERSION

      bundles_dir = Pathname.new(bundles_dir || DEFAULT_BUNDLES_DIR).expand_path
      plugins_dir = bundles_dir.join('plugins')

      destination = type == 'java' ? plugins_dir.join('java').join(artifact_id).join(version) : plugins_dir.join('ruby')

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
      mark_as_active(plugins_dir, artifact_info, artifact_id)
      update_plugin_identifier(plugins_dir, plugin_key, artifact_info)

      artifact_info
    end



    def install_plugin_from_fs(plugin_key, file_path, name, version, bundles_dir=nil, type='java')
      bundles_dir = Pathname.new(bundles_dir || DEFAULT_BUNDLES_DIR).expand_path
      plugins_dir = bundles_dir.join('plugins')

      if type.to_s == 'java'
        destination = plugins_dir.join('java').join(name).join(version)
      else
        destination = plugins_dir.join('ruby')
      end

      artifact_info = KPM::KillbillPluginArtifact.pull_from_fs(@logger, file_path, destination)
      artifact_info[:version] ||= version

      mark_as_active(plugins_dir, artifact_info)
      update_plugin_identifier(plugins_dir, plugin_key, artifact_info)

      artifact_info
    end

    def uninstall_plugin(plugin_key, plugin_version=nil, bundles_dir=nil)

      bundles_dir = Pathname.new(bundles_dir || DEFAULT_BUNDLES_DIR).expand_path
      plugins_dir = bundles_dir.join('plugins')

      plugins_manager = PluginsManager.new(plugins_dir, @logger)

      plugin_name = plugins_manager.get_plugin_name_from_key(plugin_key)
      if plugin_name.nil?
        logger.warn("Cannot uninstall plugin: Unknown plugin_key = #{plugin_key}");
        return
      end

      plugins_manager.uninstall(plugin_name, plugin_version)
    end

    def install_default_bundles(bundles_dir, specified_version=nil, kb_version=nil, force_download=false, verify_sha1=true)
      group_id = 'org.kill-bill.billing'
      artifact_id = 'killbill-platform-osgi-bundles-defaultbundles'
      packaging = 'tar.gz'
      classifier = nil

      version = specified_version
      if version.nil?
        info = KPM::KillbillServerArtifact.info(kb_version || LATEST_VERSION, @nexus_config, @nexus_ssl_verify)
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

    private

    def update_plugin_identifier(plugins_dir, plugin_key, artifact_info)
      # In case the artifact on disk already existed and the installation is skipped, we don't try to update the pluginKey mapping
      # (of course if the install is retried with a different pluginKey that may be confusing for the user)
      if artifact_info[:bundle_dir].nil?
        @logger.info("Skipping updating plugin identifier for already installed plugin")
        return
      end

      # The plugin_name needs to be computed after the fact (after the installation) because some plugin archive embed their directory structure
      plugin_name = Pathname.new(artifact_info[:bundle_dir]).parent.split[1].to_s
      plugins_manager = PluginsManager.new(plugins_dir, @logger)
      plugins_manager.update_plugin_identifier(plugin_key, plugin_name)
    end

    def mark_as_active(plugins_dir, artifact_info, artifact_id=nil)
      # Mark this bundle as active
      plugins_manager = PluginsManager.new(plugins_dir, @logger)
      if artifact_info[:bundle_dir].nil?
        # In case the artifact on disk already existed and the installation is skipped,
        # we don't know the plugin name on disk (arbitrary if it's a .tar.gz). That being said,
        # we can guess it for Kill Bill plugins (using our naming conventions)
        plugins_manager.set_active(plugins_manager.guess_plugin_name(artifact_id), artifact_info[:version])
      else
        plugins_manager.set_active(artifact_info[:bundle_dir])
      end
    end
  end
end
