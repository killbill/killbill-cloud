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
      def pull(logger, group_id, artifact_id, packaging='jar', classifier=nil, version='LATEST', destination_path=nil, sha1_file=nil, force_download=false,  overrides={}, ssl_verify=true)
        coordinates = build_coordinates(group_id, artifact_id, packaging, classifier, version)
        pull_and_put_in_place(logger, coordinates, destination_path, is_ruby_plugin_and_should_skip_top_dir(group_id, artifact_id), sha1_file, force_download, overrides, ssl_verify)
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

      def pull_and_put_in_place(logger, coordinates, destination_path=nil, skip_top_dir=true, sha1_file=nil, force_download=false, overrides={}, ssl_verify=true)
        destination_path = KPM::root if destination_path.nil?

        # Create the destination directory
        if path_looks_like_a_directory(destination_path)
          destination_dir = destination_path
        else
          destination_dir = File.dirname(destination_path)
        end
        FileUtils.mkdir_p(destination_dir)

        # Build artifact info
        artifact_info = artifact_info(coordinates, destination_path, overrides, ssl_verify)
        if !force_download && skip_if_exists(artifact_info, coordinates, sha1_file)
          logger.info "Skipping installation of #{coordinates} to #{artifact_info[:file_path]}, file already exists"
          artifact_info[:skipped] = true
          return artifact_info
        end

        # Download the artifact in a temporary directory in case of failures
        Dir.mktmpdir do |tmp_destination_dir|
          logger.info "      Starting download of #{coordinates} to #{tmp_destination_dir}"

          downloaded_artifact_info  = pull_and_verify(logger, artifact_info[:sha1], coordinates, tmp_destination_dir, sha1_file, overrides, ssl_verify)
          if artifact_info[:is_tgz]
            Utils.unpack_tgz(downloaded_artifact_info[:file_path], destination_path, skip_top_dir)
            FileUtils.rm downloaded_artifact_info[:file_path]
          else
            FileUtils.mv downloaded_artifact_info[:file_path], destination_path
            artifact_info[:size] = downloaded_artifact_info[:size]
          end
          logger.info "Successful installation of #{coordinates} to #{artifact_info[:file_path]}"
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


      def artifact_info(coordinates, destination_path, overrides={}, ssl_verify=true)

        info = {}
        nexus_info = nexus_remote(overrides, ssl_verify).get_artifact_info(coordinates)

        xml = REXML::Document.new(nexus_info)
        repository_path = xml.elements['//repositoryPath'].text unless xml.elements['//repositoryPath'].nil?
        sha1 = xml.elements['//sha1'].text unless xml.elements['//sha1'].nil?
        version = xml.elements['//version'].text unless xml.elements['//version'].nil?

        info[:sha1] = sha1
        info[:version] = version
        info[:is_tgz] = repository_path.end_with?('.tar.gz') || repository_path.end_with?('.tgz')
        if File.directory?(destination_path) && !info[:is_tgz]
          destination = File.join(File.expand_path(destination_path), File.basename(repository_path))
          info[:file_name] = File.basename(repository_path)
        else
          # The destination was a fully specified path or this is an archive and we keep the directory
          destination = destination_path
          info[:file_name] = File.basename(destination_path) if !info[:is_tgz]
        end
        info[:file_path] = File.expand_path(destination)
        info[:skipped] = false
        info
      end


      def pull_and_verify(logger, remote_sha1, coordinates, destination_dir, sha1_file, overrides={}, ssl_verify=true)
        info = nexus_remote(overrides, ssl_verify).pull_artifact(coordinates, destination_dir)
        raise ArtifactCorruptedException unless verify(logger, info[:file_path], remote_sha1)

        if sha1_file
          sha1_checker = Sha1Checker.from_file(sha1_file)
          sha1_checker.add_or_modify_entry!(coordinates, remote_sha1)
        end

        info
      end

      def verify(logger, file_path, remote_sha1)
        # Can't check :(
        if remote_sha1.nil?
          logger.warn("Unable to verify sha1 for #{coordinates}. Artifact info: #{artifact_info.inspect}")
          return true
        end

        local_sha1 = Digest::SHA1.file(file_path).hexdigest
        local_sha1 == remote_sha1
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
