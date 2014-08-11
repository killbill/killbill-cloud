require 'rexml/document'
require 'set'

module KPM
  class KillbillPluginArtifact < BaseArtifact
    class << self
      def versions(overrides={}, ssl_verify=true)
        plugins = {:java => {}, :ruby => {}}

        nexus = nexus_remote(overrides, ssl_verify)

        [[:java, KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID], [:ruby, KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID]].each do |type_and_group_id|
          response = REXML::Document.new nexus.search_for_artifacts(type_and_group_id[1])
          response.elements.each('search-results/data/artifact') do |element|
            artifact_id                                = element.elements['artifactId'].text
            plugins[type_and_group_id[0]][artifact_id] ||= SortedSet.new
            plugins[type_and_group_id[0]][artifact_id] << element.elements['version'].text
          end
        end

        plugins
      end
    end
  end
end
