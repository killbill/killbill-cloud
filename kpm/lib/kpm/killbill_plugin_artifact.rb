require 'rexml/document'
require 'set'

module KPM
  class KillbillPluginArtifact < BaseArtifact
    class << self
      def pull(logger, group_id, artifact_id, packaging = 'jar', classifier = nil, version = 'LATEST', plugin_name = nil, destination_path = nil, sha1_file = nil, force_download = false, verify_sha1 = true, overrides = {}, ssl_verify = true)
        coordinate_map = { :group_id => group_id, :artifact_id => artifact_id, :packaging => packaging, :classifier => classifier, :version => version }
        pull_and_put_in_place(logger, coordinate_map, plugin_name, destination_path, is_ruby_plugin_and_should_skip_top_dir(group_id, artifact_id), sha1_file, force_download, verify_sha1, overrides, ssl_verify)
      end

      def versions(overrides = {}, ssl_verify = true)
        plugins = { :java => {}, :ruby => {} }

        nexus = nexus_remote(overrides, ssl_verify)

        [[:java, KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID], [:ruby, KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID]].each do |type_and_group_id|
          response = REXML::Document.new nexus.search_for_artifacts(type_and_group_id[1])
          response.elements.each('searchNGResponse/data/artifact') do |element|
            artifact_id = element.elements['artifactId'].text
            plugins[type_and_group_id[0]][artifact_id] ||= SortedSet.new
            plugins[type_and_group_id[0]][artifact_id] << element.elements['version'].text
          end
        end

        plugins
      end

      protected

      # Magic methods...

      def is_ruby_plugin_and_should_skip_top_dir(group_id, artifact_id)
        # The second check is for custom ruby plugins
        group_id == KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID || artifact_id.include?('plugin')
      end
    end
  end
end
