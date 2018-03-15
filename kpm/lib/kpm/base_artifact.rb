require 'digest/sha1'
require 'rexml/document'

module KPM

  class ArtifactCorruptedException < IOError
    def message
      'Downloaded artifact failed checksum verification'
    end
  end

  class BaseArtifact
    KILLBILL_GROUP_ID = 'org.kill-bill.billing'

    KILLBILL_ARTIFACT_ID = 'killbill-profiles-killbill'
    KILLBILL_PACKAGING   = 'war'
    KILLBILL_CLASSIFIER  = nil

    KILLPAY_ARTIFACT_ID = 'killbill-profiles-killpay'
    KILLPAY_PACKAGING   = 'war'
    KILLPAY_CLASSIFIER  = nil

    KILLBILL_JAVA_PLUGIN_GROUP_ID   = 'org.kill-bill.billing.plugin.java'
    KILLBILL_JAVA_PLUGIN_PACKAGING  = 'jar'
    KILLBILL_JAVA_PLUGIN_CLASSIFIER = nil

    KILLBILL_RUBY_PLUGIN_GROUP_ID   = 'org.kill-bill.billing.plugin.ruby'
    KILLBILL_RUBY_PLUGIN_PACKAGING  = 'tar.gz'
    KILLBILL_RUBY_PLUGIN_CLASSIFIER = nil

    KAUI_GROUP_ID    = 'org.kill-bill.billing.kaui'
    KAUI_ARTIFACT_ID = 'kaui-standalone'
    KAUI_PACKAGING   = 'war'
    KAUI_CLASSIFIER  = nil

    class << self
      def pull(logger, group_id, artifact_id, packaging='jar', classifier=nil, version='LATEST', destination_path=nil, sha1_file=nil, force_download=false, verify_sha1=true, overrides={}, ssl_verify=true)
        coordinate_map = {:group_id => group_id, :artifact_id => artifact_id, :packaging => packaging, :classifier => classifier, :version => version}
        pull_and_put_in_place(logger, coordinate_map, nil, destination_path, false, sha1_file, force_download, verify_sha1, overrides, ssl_verify)
      end

      def pull_from_fs(logger, file_path, destination_path=nil)
        pull_from_fs_and_put_in_place(logger, file_path, destination_path)
      end

      def nexus_remote(overrides={}, ssl_verify=true, logger=nil)
        # overrides typically comes from the kpm.yml where we expect keys as String
        overrides_sym = (overrides || {}).each_with_object({}) {|(k,v), h| h[k.to_sym] = v}
        nexus_config = nexus_defaults.merge(overrides_sym)
        nexus_remote ||= KPM::NexusFacade::RemoteFactory.create(nexus_config, ssl_verify, logger)
      end

      def nexus_defaults
        {
            url:        'https://oss.sonatype.org',
            repository: 'releases'
        }
      end

      protected

      def pull_and_put_in_place(logger, coordinate_map, plugin_name, destination_path=nil, skip_top_dir=true, sha1_file=nil, force_download=false, verify_sha1=true, overrides={}, ssl_verify=true)
        # Build artifact info
        artifact_info = artifact_info(logger, coordinate_map, overrides, ssl_verify)
        artifact_info[:plugin_name] = plugin_name
        populate_fs_info(artifact_info, destination_path)

        # Update with resolved version in case 'LATEST' was passed
        coordinate_map[:version] = artifact_info[:version]
        coordinates = KPM::Coordinates.build_coordinates(coordinate_map)

        # Return early if there's nothing to do
        if !force_download && skip_if_exists(artifact_info, coordinates, sha1_file)
          logger.info "  Skipping installation of #{coordinates} to #{artifact_info[:file_path]}, file already exists"

          # We need to do a bit of magic to make sure that artifact_info[:bundle_dir] is correctly populated when we bail early
          if artifact_info[:is_tgz] && coordinate_map[:artifact_id] != 'killbill-platform-osgi-bundles-defaultbundles'
            plugin_dir = File.split(artifact_info[:dir_name])[0]
            plugin_name = artifact_info[:plugin_name]
            unless plugin_name
              plugins_manager = PluginsManager.new(plugin_dir, logger)
              artifact_id = coordinates.split(':')[1]
              plugin_name = plugins_manager.guess_plugin_name(artifact_id)
            end
            if plugin_name.nil?
              logger.warn("Failed to guess plugin_name for #{coordinates}: artifact_info[:bundle_dir] will not be populated correctly")
            else
              version = artifact_info[:version]
              artifact_info[:bundle_dir] = Pathname.new(artifact_info[:dir_name]).join(plugin_name).join(version).to_s
            end
          else
            artifact_info[:bundle_dir] = artifact_info[:dir_name]
          end

          artifact_info[:skipped] = true
          return artifact_info
        end

        # Create the destination directory
        FileUtils.mkdir_p(artifact_info[:dir_name])

        # Download the artifact in a temporary directory in case of failures
        Dir.mktmpdir do |tmp_destination_dir|
          logger.info "      Starting download of #{coordinates} to #{tmp_destination_dir}"

          downloaded_artifact_info = pull_and_verify(logger, artifact_info[:sha1], coordinates, tmp_destination_dir, sha1_file, verify_sha1, overrides, ssl_verify)
          remove_old_default_bundles(coordinate_map,artifact_info,downloaded_artifact_info)
          if artifact_info[:is_tgz]
            artifact_info[:bundle_dir] = Utils.unpack_tgz(downloaded_artifact_info[:file_path], artifact_info[:dir_name], skip_top_dir)
            FileUtils.rm downloaded_artifact_info[:file_path]
          else
            FileUtils.mv downloaded_artifact_info[:file_path], artifact_info[:file_path]
            artifact_info[:bundle_dir] = artifact_info[:dir_name]
            artifact_info[:size] = downloaded_artifact_info[:size]
          end
          logger.info "Successful installation of #{coordinates} to #{artifact_info[:bundle_dir]}"
        end
        artifact_info
      end

      # Logic similar than pull_and_put_in_place above
      def pull_from_fs_and_put_in_place(logger, file_path, destination_path=nil)
        artifact_info = {
            :skipped => false,
            :repository_path => file_path,
            :is_tgz => file_path.end_with?('.tar.gz') || file_path.end_with?('.tgz')
        }

        populate_fs_info(artifact_info, destination_path)

        # Create the destination directory
        FileUtils.mkdir_p(artifact_info[:dir_name])

        if artifact_info[:is_tgz]
          artifact_info[:bundle_dir] = Utils.unpack_tgz(file_path, artifact_info[:dir_name], true)
        else
          FileUtils.cp file_path, artifact_info[:dir_name]
          artifact_info[:bundle_dir] = artifact_info[:dir_name]
        end
        logger.info "Successful installation of #{file_path} to #{artifact_info[:bundle_dir]}"

        artifact_info
      end

      def skip_if_exists(artifact_info, coordinates, sha1_file)
        # If there is no sha1 from the binary server, we don't skip
        # (Unclear if this is even possible)
        return false if artifact_info[:sha1].nil?

        # If there is no such sha1_file, we don't skip
        return false if sha1_file.nil? || !File.exists?(sha1_file)

        #
        # At this point we have a valid sha1_file and a remote sha1
        #
        sha1_checker = Sha1Checker.from_file(sha1_file)
        local_sha1 = sha1_checker.sha1(coordinates)

        # Support convenient 'SKIP' keyword for allowing hacking deployments (dev mode)
        return true if local_sha1 == 'SKIP'

        if artifact_info[:is_tgz]
          # For Ruby plugins, if there is an entry in the sha1_file and it matches the remote, we can skip
          local_sha1 == artifact_info[:sha1]
        else
          # For Java plugins and other artifacts, verify the file is still around
          local_sha1 == artifact_info[:sha1] && File.file?(artifact_info[:file_path])
        end
      end

      def artifact_info(logger, coordinate_map, overrides={}, ssl_verify=true)
        info = {
            :skipped => false
        }

        coordinates = KPM::Coordinates.build_coordinates(coordinate_map)
        begin
          nexus_info = nexus_remote(overrides, ssl_verify, logger).get_artifact_info(coordinates)
        rescue KPM::NexusFacade::ArtifactMalformedException => e
          raise StandardError.new("Invalid coordinates #{coordinate_map}")
        rescue StandardError => e
          logger.warn("Unable to retrieve coordinates #{coordinate_map}")
          raise e
        end

        xml = REXML::Document.new(nexus_info)
        info[:sha1] = xml.elements['//sha1'].text unless xml.elements['//sha1'].nil?
        info[:version] = xml.elements['//version'].text unless xml.elements['//version'].nil?
        info[:repository_path] = xml.elements['//repositoryPath'].text unless xml.elements['//repositoryPath'].nil?
        info[:is_tgz] = info[:repository_path].end_with?('.tar.gz') || info[:repository_path].end_with?('.tgz')

        info
      end

      def update_destination_path(info, destination_path)
        # In case LATEST was specified, use the actual version as the directory name
        destination_path = KPM::root if destination_path.nil?
        plugin_dir, version_dir = File.split(destination_path)
        destination_path = Pathname.new(plugin_dir).join(info[:version]).to_s if version_dir == 'LATEST' && !info[:version].nil?
        destination_path
      end

      def populate_fs_info(info, destination_path)
        destination_path = update_destination_path(info, destination_path)

        if path_looks_like_a_directory(destination_path) && !info[:is_tgz]
          info[:dir_name] = File.expand_path(destination_path)
          info[:file_name] = File.basename(info[:repository_path])
          info[:file_path] = File.expand_path(File.join(info[:dir_name], File.basename(info[:repository_path])))
        else
          # The destination was a fully specified path or this is an archive and we keep the directory
          if info[:is_tgz]
            info[:dir_name] = File.expand_path(destination_path)
          else
            info[:dir_name] = File.dirname(destination_path)
            info[:file_name] = File.basename(destination_path)
          end
          info[:file_path] = File.expand_path(destination_path)
        end

        destination_path
      end

      def pull_and_verify(logger, remote_sha1, coordinates, destination_dir, sha1_file, verify_sha1, overrides={}, ssl_verify=true)
        info = nexus_remote(overrides, ssl_verify, logger).pull_artifact(coordinates, destination_dir)

        # Always verify sha1 and if incorrect either throw or log when we are asked to bypass sha1 verification
        verified = verify(logger, coordinates, info[:file_path], remote_sha1)
        if !verified
          raise ArtifactCorruptedException if verify_sha1
          logger.warn("Skip sha1 verification for  #{coordinates}")
        end

        if sha1_file
          sha1_checker = Sha1Checker.from_file(sha1_file)
          sha1_checker.add_or_modify_entry!(coordinates, remote_sha1)
        end

        info
      end

      def verify(logger, coordinates, file_path, remote_sha1)
        # Can't check :(
        if remote_sha1.nil?
          logger.warn("Unable to verify sha1 for #{coordinates}")
          return true
        end

        local_sha1 = Digest::SHA1.file(file_path).hexdigest
        res = local_sha1 == remote_sha1
        if !res
          logger.warn("Sha1 verification failed for #{coordinates} : local_sha1 = #{local_sha1}, remote_sha1 = #{remote_sha1}")
        end
        res
      end


      # Magic methods...

      def path_looks_like_a_directory(path)
        # It already is!
        return true if File.directory?(path)
        # It already isn't!
        return false if File.file?(path)

        last_part = File.basename(path).downcase

        %w(.pom .xml .war .jar .xsd .tar.gz .tgz .gz .zip).each do |classic_file_extension|
          return false if last_part.end_with?(classic_file_extension)
        end

        # Known magic files
        %w(root).each do |classic_filename|
          return false if last_part == classic_filename
        end

        # Probably a directory
        true
      end

      def remove_old_default_bundles(coordinate_map, artifact_info, downloaded_artifact_info)
        return unless coordinate_map[:artifact_id] == 'killbill-platform-osgi-bundles-defaultbundles'

        downloaded_default_bundles = Utils.peek_tgz_file_names(downloaded_artifact_info[:file_path])
        existing_default_bundles = Dir.glob("#{artifact_info[:dir_name]}/*")

        existing_default_bundles.each do |bundle|
          bundle_name = Utils.get_plugin_name_from_file_path(bundle)
          is_downloaded = downloaded_default_bundles.index {|file_name| file_name.include? bundle_name}
          unless is_downloaded.nil?
            FileUtils.remove(bundle)
          end
        end

      end
    end
  end
end
