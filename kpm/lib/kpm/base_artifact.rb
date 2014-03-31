require 'nexus_cli'

module KPM
  class BaseArtifact
    class << self
      KILLBILL_GROUP_ID = 'org.kill-bill.billing'
      KILLBILL_JAVA_PLUGIN_GROUP_ID = 'org.kill-bill.billing.plugin.java'
      KILLBILL_RUBY_PLUGIN_GROUP_ID = 'org.kill-bill.billing.plugin.ruby'

      def nexus_remote(overrides={}, ssl_verify=true)
        nexus_remote ||= NexusCli::RemoteFactory.create(nexus_defaults.merge(overrides || {}), ssl_verify)
      end

      def nexus_defaults
        {
          url: 'https://repository.sonatype.org',
          repository: 'central-proxy'
        }
      end
    end
  end
end