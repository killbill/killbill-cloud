require 'open-uri'
require 'yaml'

module KPM
  class PluginsDirectory
    def self.all(latest=false)
      if latest
        # Look at GitHub (source of truth)
        source = URI.parse('https://raw.githubusercontent.com/killbill/killbill-cloud/master/kpm/lib/kpm/plugins_directory.yml').read
        YAML.load(source)
      else
        source = File.join(File.expand_path(File.dirname(__FILE__)), 'plugins_directory.yml')
        YAML.load_file(source)
      end
    end

    # Note: this API is used in Docker images (see kpm_generator.rb, careful when changing it!)
    def self.lookup(raw_plugin_key, latest=false, raw_kb_version=nil)
      plugin_key = raw_plugin_key.to_s.downcase
      plugin = all(latest)[plugin_key.to_sym]
      return nil if plugin.nil?

      type = plugin[:type]
      is_ruby = type == :ruby

      group_id    = plugin[:group_id] || (is_ruby ? KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID : KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID)
      artifact_id = plugin[:artifact_id] || "#{plugin_key}-plugin"
      packaging   = plugin[:packaging] || (is_ruby ? KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_PACKAGING : KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_PACKAGING)
      classifier  = plugin[:classifier] || (is_ruby ? KPM::BaseArtifact::KILLBILL_RUBY_PLUGIN_CLASSIFIER : KPM::BaseArtifact::KILLBILL_JAVA_PLUGIN_CLASSIFIER)

      if raw_kb_version == 'LATEST'
        version = 'LATEST'
      else
        # Keep supporting the deprecated key :stable_version for now
        captures = raw_kb_version.nil? ? [] : raw_kb_version.scan(/(\d+\.\d+)(\.\d)?/)
        if captures.empty? || captures.first.nil? || captures.first.first.nil?
          version = plugin[:stable_version] || 'LATEST'
        else
          kb_version = captures.first.first
          version = (plugin[:versions] || {})[kb_version.to_sym] || 'LATEST'
        end
      end

      [group_id, artifact_id, packaging, classifier, version, type]
    end
  end
end
