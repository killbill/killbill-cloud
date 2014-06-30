require 'rexml/document'
require 'set'

module KPM
  class KillbillPluginArtifact < BaseArtifact
    class << self
      def pull(artifact_id, version='LATEST', type=:java, destination=nil, overrides={}, ssl_verify=true)
        if type == :java
          group_id = BaseArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID
          packaging = 'jar'
        else
          group_id = BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID
          packaging = 'tar.gz'
        end
        coordinates = "#{group_id}:#{artifact_id}:#{packaging}:#{version}"
        nexus_remote(overrides, ssl_verify).pull_artifact(coordinates, destination)
      end

      def versions(overrides={}, ssl_verify=true)
        plugins = { :java => {}, :ruby => {} }

        nexus = nexus_remote(overrides, ssl_verify)

        [[:java, BaseArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID], [:ruby, BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID]].each do |type_and_group_id|
          response = REXML::Document.new nexus.search_for_artifacts(type_and_group_id[1])
          response.elements.each('search-results/data/artifact') do |element|
            artifact_id = element.elements['artifactId'].text
            plugins[type_and_group_id[0]][artifact_id] ||= SortedSet.new
            plugins[type_and_group_id[0]][artifact_id] << element.elements['version'].text
          end
        end

        plugins
      end
    end
  end
end
