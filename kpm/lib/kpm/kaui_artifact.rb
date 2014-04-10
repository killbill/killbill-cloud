require 'rexml/document'
require 'set'

module KPM
  class KauiArtifact < BaseArtifact
    class << self
      KAUI_WAR = "org.kill-bill.billing.kaui:kaui-standalone:war"

      def pull(version='LATEST', destination=nil, overrides={}, ssl_verify=true)
        nexus_remote(overrides, ssl_verify).pull_artifact("#{KAUI_WAR}:#{version}", destination)
      end

      def versions(overrides={}, ssl_verify=true)
        response = REXML::Document.new nexus_remote(overrides, ssl_verify).search_for_artifacts(KAUI_WAR)
        versions = SortedSet.new
        response.elements.each("search-results/data/artifact/version") { |element| versions << element.text }
        versions
      end
    end
  end
end
