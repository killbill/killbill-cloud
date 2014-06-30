require 'nexus_cli'

module KPM
  class BaseArtifact
    KILLBILL_GROUP_ID             = 'org.kill-bill.billing'
    KILLBILL_JAVA_PLUGIN_GROUP_ID = 'org.kill-bill.billing.plugin.java'
    KILLBILL_RUBY_PLUGIN_GROUP_ID = 'org.kill-bill.billing.plugin.ruby'

    class << self
      def pull(group_id, artifact_id, packaging='jar', version='LATEST', destination=nil, overrides={}, ssl_verify=true)
        coordinates = build_coordinates(group_id, artifact_id, packaging, nil, version)
        nexus_remote(overrides, ssl_verify).pull_artifact(coordinates, destination)
      end

      def nexus_remote(overrides={}, ssl_verify=true)
        nexus_remote ||= NexusCli::RemoteFactory.create(nexus_defaults.merge(overrides || {}), ssl_verify)
      end

      def nexus_defaults
        {
          url: 'https://repository.sonatype.org',
          repository: 'central-proxy'
        }
      end

      protected

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
    end
  end
end
