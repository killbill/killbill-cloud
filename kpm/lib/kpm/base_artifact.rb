require 'digest/sha1'
require 'nexus_cli'
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
        coordinates = build_coordinates(group_id, artifact_id, packaging, classifier, version)
        pull_and_put_in_place(logger, coordinates, destination_path, is_ruby_plugin_and_should_skip_top_dir(group_id, artifact_id), sha1_file, force_download, verify_sha1, overrides, ssl_verify)
      end

      def nexus_remote(overrides={}, ssl_verify=true)
        nexus_remote ||= NexusCli::RemoteFactory.create(nexus_defaults.merge(overrides || {}), ssl_verify)
      end

      def nexus_defaults
        {
            url:        'https://oss.sonatype.org',
            repository: 'releases'
        }
      end

      protected

      def pull_and_put_in_place(logger, coordinates, destination_path=nil, skip_top_dir=true, sha1_file=nil, force_download=false, verify_sha1=true, overrides={}, ssl_verify=true)
        # Build artifact info
        artifact_info = artifact_info(coordinates, overrides, ssl_verify)

        populate_fs_info(artifact_info, destination_path)

        # Return early if there's nothing to do
        if !force_download && skip_if_exists(artifact_info, coordinates, sha1_file)
          logger.info "  Skipping installation of #{coordinates} to #{artifact_info[:file_path]}, file already exists"
          artifact_info[:skipped] = true
          return artifact_info
        end

        # Create the destination directory
        FileUtils.mkdir_p(artifact_info[:dir_name])

        # Download the artifact in a temporary directory in case of failures
        Dir.mktmpdir do |tmp_destination_dir|
          logger.info "      Starting download of #{coordinates} to #{tmp_destination_dir}"

          downloaded_artifact_info = pull_and_verify(logger, artifact_info[:sha1], coordinates, tmp_destination_dir, sha1_file, verify_sha1, overrides, ssl_verify)
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

      def skip_if_exists(artifact_info, coordinates, sha1_file)

        # Unclear if this is even possible
        return false if artifact_info[:sha1].nil?

        # Check entry in sha1_file if exists
        if sha1_file && File.exists?(sha1_file)
          sha1_checker = Sha1Checker.from_file(sha1_file)
          local_sha1 = sha1_checker.sha1(coordinates)
          return true if local_sha1 == artifact_info[:sha1]
        end

        # If not using sha1_file mechanism, exit early if file_path odes not exist or is a directory
        if !File.exists?(artifact_info[:file_path]) ||
            File.directory?(artifact_info[:file_path])
          return false
        end

        # Finally check if remote_sha1 matches what we have locally
        local_sha1 = Digest::SHA1.file(artifact_info[:file_path]).hexdigest
        local_sha1 == artifact_info[:sha1]
      end

      def artifact_info(coordinates, overrides={}, ssl_verify=true)
        info = {
            :skipped => false
        }

        nexus_info = nexus_remote(overrides, ssl_verify).get_artifact_info(coordinates)

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
        destination_path = Pathname.new(plugin_dir).join(info[:version]).to_s if version_dir == 'LATEST'
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
        info = nexus_remote(overrides, ssl_verify).pull_artifact(coordinates, destination_dir)

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

      def build_coordinates(group_id, artifact_id, packaging, classifier, version=nil)
        if classifier.nil?
          if version.nil?
            "#{group_id}:#{artifact_id}:#{packaging}"
          else
            "#{group_id}:#{artifact_id}:#{packaging}:#{version}"
          end
        else
          if version.nil?
            "#{group_id}:#{artifact_id}:#{packaging}:#{classifier}"
          else
            "#{group_id}:#{artifact_id}:#{packaging}:#{classifier}:#{version}"
          end
        end
      end

      # Magic methods...

      def is_ruby_plugin_and_should_skip_top_dir(group_id, artifact_id)
        # The second check is for custom ruby plugins
        group_id == KILLBILL_RUBY_PLUGIN_GROUP_ID || artifact_id.include?('plugin')
      end

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
    end
  end
end
