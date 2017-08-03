require 'pathname'
require 'zip'

module KPM
  class BaseInstaller

    LATEST_VERSION = 'LATEST'
    SHA1_FILENAME = 'sha1.yml'
    DEFAULT_BUNDLES_DIR = Pathname.new('/var').join('tmp').join('bundles').to_s

    def initialize(logger, nexus_config = nil, nexus_ssl_verify = nil)
      @logger = logger
      @nexus_config = nexus_config
      @nexus_ssl_verify = nexus_ssl_verify
      @trace_logger = KPM::TraceLogger.new
    end

    def install_killbill_server(specified_group_id=nil, specified_artifact_id=nil, specified_packaging=nil, specified_classifier=nil, specified_version=nil, specified_webapp_path=nil,  bundles_dir=nil, force_download=false, verify_sha1=true)
      group_id = specified_group_id || KPM::BaseArtifact::KILLBILL_GROUP_ID
      artifact_id = specified_artifact_id || KPM::BaseArtifact::KILLBILL_ARTIFACT_ID
      packaging = specified_packaging || KPM::BaseArtifact::KILLBILL_PACKAGING
      classifier = specified_classifier || KPM::BaseArtifact::KILLBILL_CLASSIFIER
      version = specified_version || LATEST_VERSION
      webapp_path = specified_webapp_path || KPM::root
      bundles_dir = Pathname.new(bundles_dir || DEFAULT_BUNDLES_DIR).expand_path
      sha1_file = "#{bundles_dir}/#{SHA1_FILENAME}"

      if version == LATEST_VERSION
        latest_stable_version = KPM::Installer.get_kb_latest_stable_version
        version = latest_stable_version unless latest_stable_version.nil?
      end

      @logger.debug("Installing Kill Bill server: group_id=#{group_id} artifact_id=#{artifact_id} packaging=#{packaging} classifier=#{classifier} version=#{version} webapp_path=#{webapp_path}")
      artifact_info = KPM::KillbillServerArtifact.pull(@logger,
                                       group_id,
                                       artifact_id,
                                       packaging,
                                       classifier,
                                       version,
                                       webapp_path,
                                       sha1_file,
                                       force_download,
                                       verify_sha1,
                                       @nexus_config,
                                       @nexus_ssl_verify)
      # store trace info to be returned as JSON by the KPM::Installer.install method
      @trace_logger.add('killbill',
                           artifact_info.merge({'status'=> (artifact_info[:skipped] ? 'UP_TO_DATE': 'INSTALLED'),
                            :group_id => group_id, :artifact_id => artifact_id, :packaging => packaging, :classifier => classifier}))
    end

    def install_kaui(specified_group_id=nil, specified_artifact_id=nil, specified_packaging=nil, specified_classifier=nil, specified_version=nil, specified_webapp_path=nil,  bundles_dir=nil, force_download=false, verify_sha1=true)
      group_id = specified_group_id || KPM::BaseArtifact::KAUI_GROUP_ID
      artifact_id = specified_artifact_id || KPM::BaseArtifact::KAUI_ARTIFACT_ID
      packaging = specified_packaging || KPM::BaseArtifact::KAUI_PACKAGING
      classifier = specified_classifier || KPM::BaseArtifact::KAUI_CLASSIFIER
      version = specified_version || LATEST_VERSION
      webapp_path = specified_webapp_path || KPM::root
      bundles_dir = Pathname.new(bundles_dir || DEFAULT_BUNDLES_DIR).expand_path
      sha1_file = "#{bundles_dir}/#{SHA1_FILENAME}"

      @logger.debug("Installing Kaui: group_id=#{group_id} artifact_id=#{artifact_id} packaging=#{packaging} classifier=#{classifier} version=#{version} webapp_path=#{webapp_path}")
      artifact_info = KPM::KauiArtifact.pull(@logger,
                             group_id,
                             artifact_id,
                             packaging,
                             classifier,
                             version,
                             webapp_path,
                             sha1_file,
                             force_download,
                             verify_sha1,
                             @nexus_config,
                             @nexus_ssl_verify)
      # store trace info to be returned as JSON by the KPM::Installer.install method
      @trace_logger.add('kaui',
                           artifact_info.merge({'status'=> (artifact_info[:skipped] ? 'UP_TO_DATE': 'INSTALLED'),
                            :group_id => group_id, :artifact_id => artifact_id, :packaging => packaging, :classifier => classifier}))


    end

    def install_plugin(plugin_key, raw_kb_version=nil, specified_group_id=nil, specified_artifact_id=nil, specified_packaging=nil, specified_classifier=nil, specified_version=nil, bundles_dir=nil, specified_type=nil, force_download=false, verify_sha1=true, verify_jruby_jar=false)

      # plugin_key needs to exist
      if plugin_key.nil?
        raise ArgumentError.new 'Aborting installation: User needs to specify a pluginKey'
      end

      # Lookup artifact and perform validation against input
      looked_up_group_id, looked_up_artifact_id, looked_up_packaging, looked_up_classifier, looked_up_version, looked_up_type = KPM::PluginsDirectory.lookup(plugin_key, true, raw_kb_version)
      validate_installation_arg!(plugin_key, 'group_id', specified_group_id, looked_up_group_id)
      validate_installation_arg!(plugin_key, 'artifact_id', specified_artifact_id, looked_up_artifact_id)
      validate_installation_arg!(plugin_key, 'packaging', specified_packaging, looked_up_packaging)
      validate_installation_arg!(plugin_key, 'type', specified_type, looked_up_type)
      validate_installation_arg!(plugin_key, 'classifier', specified_classifier, looked_up_classifier)


      # If there is no entry in plugins_directory.yml and the group_id is not the killbill default group_id, the key provided must be a user key and must have a namespace
      if looked_up_artifact_id.nil? &&
          specified_group_id != KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID &&
          specified_group_id != KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID &&
          plugin_key.split(':').size == 1
        raise ArgumentError.new "Aborting installation: pluginKey = #{plugin_key} does not exist in plugin_directory.yml so format of the key must have a user namespace (e.g namespace:key)"
      end


      # Specified parameters have always precedence except for the artifact_id (to map stripe to stripe-plugin)
      artifact_id = looked_up_artifact_id || specified_artifact_id
      if artifact_id.nil?
        raise ArgumentError.new "Aborting installation: unable to lookup plugin #{specified_artifact_id}"
      end

      bundles_dir = Pathname.new(bundles_dir || DEFAULT_BUNDLES_DIR).expand_path
      plugins_dir = bundles_dir.join('plugins')

      type = specified_type || looked_up_type
      if type.to_s == 'java'
        group_id = specified_group_id || looked_up_group_id || KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID
        packaging = specified_packaging || looked_up_packaging || KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_PACKAGING
        classifier = specified_classifier || looked_up_classifier || KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_CLASSIFIER
        version = specified_version || looked_up_version || LATEST_VERSION
        destination = plugins_dir.join('java').join(artifact_id).join(version)
      else

        warn_if_jruby_jar_missing(bundles_dir) if verify_jruby_jar

        group_id = specified_group_id || looked_up_group_id || KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID
        packaging = specified_packaging || looked_up_packaging || KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_PACKAGING
        classifier = specified_classifier || looked_up_classifier || KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_CLASSIFIER
        version = specified_version || looked_up_version || LATEST_VERSION
        destination = plugins_dir.join('ruby')
      end
      sha1_file = "#{bundles_dir}/#{SHA1_FILENAME}"
      plugins_manager = PluginsManager.new(plugins_dir, @logger)
      _, plugin_name = plugins_manager.get_plugin_key_and_name(plugin_key)

      # Before we do the install we verify that the entry we have in the plugin_identifiers.json matches our current request
      coordinate_map = {:group_id => group_id, :artifact_id => artifact_id, :packaging => packaging, :classifier => classifier}
      validate_plugin_key!(plugins_dir, plugin_key, coordinate_map)


      @logger.debug("Installing plugin: group_id=#{group_id} artifact_id=#{artifact_id} packaging=#{packaging} classifier=#{classifier} version=#{version} destination=#{destination}")
      artifact_info = KPM::KillbillPluginArtifact.pull(@logger,
                                                       group_id,
                                                       artifact_id,
                                                       packaging,
                                                       classifier,
                                                       version,
                                                       plugin_name,
                                                       destination,
                                                       sha1_file,
                                                       force_download,
                                                       verify_sha1,
                                                       @nexus_config,
                                                       @nexus_ssl_verify)
      # store trace info to be returned as JSON by the KPM::Installer.install method
      @trace_logger.add('plugins', plugin_key,
                           artifact_info.merge({'status'=> (artifact_info[:skipped] ? 'UP_TO_DATE': 'INSTALLED'),
                            :group_id => group_id, :artifact_id => artifact_id, :packaging => packaging, :classifier => classifier}))

      # Update with resolved version
      coordinate_map[:version] = artifact_info[:version]

      mark_as_active(plugins_dir, artifact_info, artifact_id)

      update_plugin_identifier(plugins_dir, plugin_key, type.to_s, coordinate_map, artifact_info)

      artifact_info
    end


    def install_plugin_from_fs(plugin_key, file_path, name, version, bundles_dir=nil, type='java')
      bundles_dir = Pathname.new(bundles_dir || DEFAULT_BUNDLES_DIR).expand_path
      plugins_dir = bundles_dir.join('plugins')

      if type.to_s == 'java'
        plugin_name = name.nil? ? Utils.get_plugin_name_from_file_path(file_path) : name
        destination = plugins_dir.join('java').join(plugin_name).join(version)
      else
        destination = plugins_dir.join('ruby')
      end

      artifact_info = KPM::KillbillPluginArtifact.pull_from_fs(@logger, file_path, destination)
      artifact_info[:version] ||= version

      mark_as_active(plugins_dir, artifact_info)

      update_plugin_identifier(plugins_dir, plugin_key, type.to_s, nil, artifact_info)

      # store trace info to be returned as JSON by the KPM::Installer.install method
      @trace_logger.add('plugins', plugin_key,
                           artifact_info.merge({'status'=>'INSTALLED'}))

      artifact_info
    end

    def uninstall_plugin(plugin_name_or_key, plugin_version=nil, bundles_dir=nil)
      bundles_dir = Pathname.new(bundles_dir || DEFAULT_BUNDLES_DIR).expand_path
      plugins_dir = bundles_dir.join('plugins')

      plugins_manager = PluginsManager.new(plugins_dir, @logger)

      plugin_key, plugin_name = plugins_manager.get_plugin_key_and_name(plugin_name_or_key)
      if plugin_name.nil?
        raise ArgumentError.new "Cannot uninstall plugin: Unknown plugin name or plugin key = #{plugin_name_or_key}"
      end

      modified = plugins_manager.uninstall(plugin_name, plugin_version || :all)
      plugins_manager.remove_plugin_identifier_key(plugin_key)
      modified
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

      @trace_logger.add('default_bundles',
                        info.merge({'status'=> (info[:skipped] ? 'UP_TO_DATE': 'INSTALLED'),
                         :group_id => group_id, :artifact_id => artifact_id, :packaging => packaging, :classifier => classifier}))

      # The special JRuby bundle needs to be called jruby.jar
      # TODO .first - code smell
      unless info[:skipped]
        File.rename Dir.glob("#{destination}/killbill-platform-osgi-bundles-jruby-*.jar").first, destination.join('jruby.jar')
      end

      info
    end

    private

    def validate_installation_arg!(plugin_key, arg_type, specified_arg, looked_up_arg)

      # If nothing was specified, or if we don't find anything from the lookup, nothing to validate against
      if specified_arg.nil? || looked_up_arg.nil?
        return
      end

      if specified_arg.to_s != looked_up_arg.to_s
        raise ArgumentError.new "Aborting installation for plugin_key #{plugin_key}: specified value #{specified_arg} for #{arg_type} does not match looked_up value #{looked_up_arg}"
      end
    end

    def validate_plugin_key!(plugins_dir, plugin_key, coordinate_map)
      plugins_manager = PluginsManager.new(plugins_dir, @logger)
      res = plugins_manager.validate_plugin_identifier_key(plugin_key, coordinate_map)
      raise ArgumentError.new "Failed to validate plugin key #{plugin_key}" if !res
    end

    def update_plugin_identifier(plugins_dir, plugin_key, type, coordinate_map, artifact_info)
      path = artifact_info[:bundle_dir]

      # The plugin_name needs to be computed after the fact (after the installation) because some plugin archive embed their directory structure
      plugin_name = Pathname.new(path).parent.split[1].to_s
      plugins_manager = PluginsManager.new(plugins_dir, @logger)
      plugins_manager.add_plugin_identifier_key(plugin_key, plugin_name, type, coordinate_map)
    end

    def mark_as_active(plugins_dir, artifact_info, artifact_id=nil)
      # Mark this bundle as active
      plugins_manager = PluginsManager.new(plugins_dir, @logger)
      plugins_manager.set_active(artifact_info[:bundle_dir])
    end

    def warn_if_jruby_jar_missing(bundles_dir)
      platform_dir = bundles_dir.join('platform')
      jruby_jar = platform_dir.join('jruby.jar')
      if !File.exists?(jruby_jar)
        @logger.warn("  Missing installation for jruby.jar under #{platform_dir}. This is required for ruby plugin installation");
      else
        version = extract_jruby_jar_version(jruby_jar)
        if version
          @logger.info("  Detected jruby.jar version #{version}")
        else
          @logger.warn("  Failed to detect jruby.jar version for #{jruby_jar}");
        end
      end
    end

    def extract_jruby_jar_version(jruby_jar)
      selected_entries = Zip::File.open(jruby_jar) do |zip_file|
        zip_file.select do |entry|
          entry.name == 'META-INF/maven/org.kill-bill.billing/killbill-platform-osgi-bundles-jruby/pom.properties'
        end
      end

      if selected_entries && selected_entries.size == 1
        zip_entry = selected_entries[0]
        content = zip_entry.get_input_stream.read
        return content.split("\n").select { |e| e.start_with?("version")}[0].split("=")[1]
      end
      nil
    end

  end
end
