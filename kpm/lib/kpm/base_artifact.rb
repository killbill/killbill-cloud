require 'digest/sha1'
require 'nexus_cli'
require 'rexml/document'

module KPM

  class ArtifactCorruptedException < IOError
    def message
      'Downloaded artifact failed checksum verification'
    end
  end

  class ArtifactAlreadyExistsException < IOError
    def message
      'Artifact already exists locally'
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
      def pull(logger, group_id, artifact_id, packaging='jar', classifier=nil, version='LATEST', destination_path=nil, overrides={}, ssl_verify=true)
        coordinates = build_coordinates(group_id, artifact_id, packaging, classifier, version)
        pull_and_put_in_place(logger, coordinates, destination_path, is_ruby_plugin_and_should_skip_top_dir(group_id, artifact_id), overrides, ssl_verify)
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

      def pull_and_put_in_place(logger, coordinates, destination_path=nil, skip_top_dir=true, overrides={}, ssl_verify=true)
        destination_path = KPM::root if destination_path.nil?

        # Create the destination directory
        if path_looks_like_a_directory(destination_path)
          destination_dir = destination_path
        else
          destination_dir = File.dirname(destination_path)
        end
        FileUtils.mkdir_p(destination_dir)

        # Retrieve sha1 first
        artifact_info = artifact_info(logger, coordinates, overrides, ssl_verify)

        # Check if already exists
        raise ArtifactAlreadyExistsException.new if skip_if_exists(artifact_info[:sha1], artifact_info[:repository_path], destination_path)

        # Download the artifact in a temporary directory in case of failures
        info = {}
        Dir.mktmpdir do |tmp_destination_dir|
          logger.info "      Starting download of #{coordinates} to #{tmp_destination_dir}"

          info   = pull_and_verify(logger, artifact_info[:sha1], coordinates, tmp_destination_dir, overrides, ssl_verify)

          # Move the file to the final destination, unpacking if necessary
          is_tgz = info[:file_path].end_with?('.tar.gz') || info[:file_path].end_with?('.tgz')
          if is_tgz
            Utils.unpack_tgz(info[:file_path], destination_path, skip_top_dir)
            FileUtils.rm info[:file_path]
          else
            FileUtils.mv info[:file_path], destination_path
          end

          # Update the info hash with the real destination
          if File.directory?(destination_path) && !is_tgz
            destination = File.join(File.expand_path(destination_path), info[:file_name])
          else
            destination = destination_path
          end
          info[:file_path] = File.expand_path(destination)

          if is_tgz
            info[:file_name] = nil
            info[:size]      = nil
          else
            info[:file_name] = File.basename(destination)
          end

          logger.info "Successful installation of #{coordinates} to #{info[:file_path]}"
        end
        info
      end

      def skip_if_exists(remote_sha1, remote_path, destination_path)
        # If we could not get sha1, we assume we don't skip and download again
        return false if remote_sha1.nil?

        if File.directory?(destination_path) && remote_path
          destination = File.join(File.expand_path(destination_path), File.basename(remote_path))
        else
          destination = destination_path
        end

        return false if ! File.exists?(destination)

        local_sha1 = Digest::SHA1.file(destination).hexdigest
        local_sha1 == remote_sha1
      end


      def artifact_info(logger, coordinates, overrides={}, ssl_verify=true)
        artifact_info = nexus_remote(overrides, ssl_verify).get_artifact_info(coordinates)
        if artifact_info.nil?
          logger.warn("Unable to retrieve artifact info for #{coordinates}")
          nil
        else
          xml = REXML::Document.new(artifact_info)
          repository_path =  xml.elements['//repositoryPath'].text unless xml.elements['//repositoryPath'].nil?
          sha1 =  xml.elements['//sha1'].text unless xml.elements['//sha1'].nil?
          {
            :sha1 => sha1,
            :repository_path => repository_path
          }
        end
      end


      def pull_and_verify(logger, remote_sha1, coordinates, destination_dir, overrides={}, ssl_verify=true)
        info = nexus_remote(overrides, ssl_verify).pull_artifact(coordinates, destination_dir)
        raise ArtifactCorruptedException unless verify(logger, info[:file_path], remote_sha1)
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
