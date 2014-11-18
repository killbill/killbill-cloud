require 'net/http'
require 'yaml'

module KPM
  class PluginsDirectory
    def self.all(latest=false)
      if latest
        # Look at GitHub (source of truth)
        uri = URI('https://raw.githubusercontent.com/killbill/killbill-cloud/master/kpm/lib/kpm/plugins_directory.yml')
        source = Net::HTTP.get(uri)
      else
        source = File.join(File.expand_path(File.dirname(__FILE__)), 'plugins_directory.yml')
      end
      YAML.load_file(source)
    end

    def self.lookup(plugin_name, latest=false)
      plugin = all(latest)[plugin_name.to_s.downcase.to_sym]
      return nil if plugin.nil?

      type = plugin[:type]
      is_ruby = type == :ruby

      group_id    = plugin[:group_id] || (is_ruby ? KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID : KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID)
      artifact_id = plugin[:artifact_id] || "#{plugin.to_s}-plugin"
      packaging   = plugin[:packaging] || (is_ruby ? KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_PACKAGING : KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_PACKAGING)
      classifier  = plugin[:classifier] || (is_ruby ? KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_CLASSIFIER : KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_CLASSIFIER)
      version     = plugin[:stable_version] || 'LATEST'

      [group_id, artifact_id, packaging, classifier, version, type]
    end
  end
end