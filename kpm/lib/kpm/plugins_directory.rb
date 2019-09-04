# frozen_string_literal: true

require 'open-uri'
require 'yaml'

module KPM
  class PluginsDirectory
    def self.all(latest = false)
      if latest
        # Look at GitHub (source of truth)
        begin
          source = URI.parse('https://raw.githubusercontent.com/killbill/killbill-cloud/master/kpm/lib/kpm/plugins_directory.yml').read
        rescue StandardError
          # Default to built-in version if GitHub isn't accessible
          return all(false)
        end
        YAML.safe_load(source)
      else
        source = File.join(__dir__, 'plugins_directory.yml')
        YAML.load_file(source)
      end
    end

    def self.list_plugins(latest = false, kb_version)
      all(latest).each_with_object({}) { |(key, val), out| out[key] = val[:versions][kb_version.to_sym] if val[:versions].key?(kb_version.to_sym); }
    end

    def self.lookup(raw_plugin_key, latest = false, raw_kb_version = nil)
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
        captures = raw_kb_version.nil? ? [] : raw_kb_version.scan(/(\d+\.\d+)(\.\d)?/)
        if captures.empty? || captures.first.nil? || captures.first.first.nil?
          version = 'LATEST'
        else
          kb_version = captures.first.first
          version = (plugin[:versions] || {})[kb_version.to_sym] || 'LATEST'
        end
      end

      [group_id, artifact_id, packaging, classifier, version, type]
    end
  end
end
