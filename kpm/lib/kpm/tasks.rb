require 'highline'
require 'logger'
require 'thor'

module KPM
  module Tasks
    def self.included(base)
      base.send :include, ::Thor::Actions
      base.class_eval do

        class_option :overrides,
                     :type    => :hash,
                     :default => nil,
                     :desc    => "A hashed list of overrides. Available options are 'url', 'repository', 'username', and 'password'."

        class_option :ssl_verify,
                     :type    => :boolean,
                     :default => true,
                     :desc    => 'Set to false to disable SSL Verification.'

        method_option :force_download,
                      :type    => :boolean,
                      :default => false,
                      :desc    => 'Force download of the artifact even if it exists'
        method_option :verify_sha1,
                      :type    => :boolean,
                      :default => true,
                      :desc    => 'Validate sha1 sum'
        desc 'install config_file', 'Install Kill Bill server and plugins according to the specified YAML configuration file.'
        def install(config_file=nil)
          help = Installer.from_file(config_file).install(options[:force_download], options[:verify_sha1])
          say help, :green unless help.nil?
        end

        method_option :destination,
                      :type    => :string,
                      :default => nil,
                      :desc    => 'A different folder other than the current working directory.'
        method_option :force_download,
                      :type    => :boolean,
                      :default => false,
                      :desc    => 'Force download of the artifact even if it exists'
        method_option :verify_sha1,
                      :type    => :boolean,
                      :default => true,
                      :desc    => 'Validate sha1 sum'
        desc 'pull_kb_server_war <version>', 'Pulls Kill Bill server war from Sonatype and places it on your machine. If version was not specified it uses the latest released version.'
        def pull_kb_server_war(version='LATEST')
          response = KillbillServerArtifact.pull(logger,
                                                 KillbillServerArtifact::KILLBILL_GROUP_ID,
                                                 KillbillServerArtifact::KILLBILL_ARTIFACT_ID,
                                                 KillbillServerArtifact::KILLBILL_PACKAGING,
                                                 KillbillServerArtifact::KILLBILL_CLASSIFIER,
                                                 version,
                                                 options[:destination],
                                                 nil,
                                                 options[:force_download],
                                                 options[:verify_sha1],
                                                 options[:overrides],
                                                 options[:ssl_verify])
          say "Artifact has been retrieved and can be found at path: #{response[:file_path]}", :green
        end

        desc 'search_for_kb_server', 'Searches for all versions of Kill Bill server and prints them to the screen.'
        def search_for_kb_server
          say "Available versions: #{KillbillServerArtifact.versions(KillbillServerArtifact::KILLBILL_ARTIFACT_ID,
                                                                     KillbillServerArtifact::KILLBILL_PACKAGING,
                                                                     KillbillServerArtifact::KILLBILL_CLASSIFIER,
                                                                     options[:overrides],
                                                                     options[:ssl_verify]).to_a.join(', ')}", :green
        end

        method_option :destination,
                      :type    => :string,
                      :default => nil,
                      :desc    => 'A different folder other than the current working directory.'
        method_option :force_download,
                      :type    => :boolean,
                      :default => false,
                      :desc    => 'Force download of the artifact even if it exists'
        method_option :verify_sha1,
                      :type    => :boolean,
                      :default => true,
                      :desc    => 'Validates sha1 sum'
        desc 'pull_kp_server_war <version>', 'Pulls Kill Pay server war from Sonatype and places it on your machine. If version was not specified it uses the latest released version.'
        def pull_kp_server_war(version='LATEST')
          response = KillbillServerArtifact.pull(logger,
                                                 KillbillServerArtifact::KILLBILL_GROUP_ID,
                                                 KillbillServerArtifact::KILLPAY_ARTIFACT_ID,
                                                 KillbillServerArtifact::KILLPAY_PACKAGING,
                                                 KillbillServerArtifact::KILLPAY_CLASSIFIER,
                                                 version,
                                                 options[:destination],
                                                 nil,
                                                 options[:force_download],
                                                 options[:verify_sha1],
                                                 options[:overrides],
                                                 options[:ssl_verify])
          say "Artifact has been retrieved and can be found at path: #{response[:file_path]}", :green
        end

        desc 'search_for_kp_server', 'Searches for all versions of Kill Pay server and prints them to the screen.'
        def search_for_kp_server
          say "Available versions: #{KillbillServerArtifact.versions(KillbillServerArtifact::KILLPAY_ARTIFACT_ID,
                                                                     KillbillServerArtifact::KILLPAY_PACKAGING,
                                                                     KillbillServerArtifact::KILLPAY_CLASSIFIER,
                                                                     options[:overrides],
                                                                     options[:ssl_verify]).to_a.join(', ')}", :green
        end

        method_option :destination,
                      :type    => :string,
                      :default => nil,
                      :desc    => 'A different folder other than the current working directory.'
        method_option :force_download,
                      :type    => :boolean,
                      :default => false,
                      :desc    => 'Force download of the artifact even if it exists'
        method_option :sha1_file,
                      :type    => :string,
                      :default => nil,
                      :desc    => 'Location of the sha1 file'
        method_option :verify_sha1,
                      :type    => :boolean,
                      :default => true,
                      :desc    => 'Validates sha1 sum'
        desc 'pull_java_plugin artifact_id <version>', 'Pulls a java plugin from Sonatype and places it on your machine. If version was not specified it uses the latest released version.'
        def pull_java_plugin(artifact_id, version='LATEST')
          response = KillbillPluginArtifact.pull(logger,
                                                 KillbillPluginArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID,
                                                 artifact_id,
                                                 KillbillPluginArtifact::KILLBILL_JAVA_PLUGIN_PACKAGING,
                                                 KillbillPluginArtifact::KILLBILL_JAVA_PLUGIN_CLASSIFIER,
                                                 version,
                                                 options[:destination],
                                                 options[:sha1_file],
                                                 options[:force_download],
                                                 options[:verify_sha1],
                                                 options[:overrides],
                                                 options[:ssl_verify])
          say "Artifact has been retrieved and can be found at path: #{response[:file_path]}", :green
        end

        method_option :destination,
                      :type    => :string,
                      :default => nil,
                      :desc    => 'A different folder other than the current working directory.'
        method_option :force_download,
                      :type    => :boolean,
                      :default => false,
                      :desc    => 'Force download of the artifact even if it exists'
        method_option :sha1_file,
                      :type    => :string,
                      :default => nil,
                      :desc    => 'Location of the sha1 file'
        method_option :verify_sha1,
                      :type    => :boolean,
                      :default => true,
                      :desc    => 'Validates sha1 sum'
        desc 'pull_ruby_plugin artifact_id <version>', 'Pulls a ruby plugin from Sonatype and places it on your machine. If version was not specified it uses the latest released version.'
        def pull_ruby_plugin(artifact_id, version='LATEST')
          response = KillbillPluginArtifact.pull(logger,
                                                 KillbillPluginArtifact::KILLBILL_RUBY_PLUGIN_GROUP_ID,
                                                 artifact_id,
                                                 KillbillPluginArtifact::KILLBILL_RUBY_PLUGIN_PACKAGING,
                                                 KillbillPluginArtifact::KILLBILL_RUBY_PLUGIN_CLASSIFIER,
                                                 version,
                                                 options[:destination],
                                                 options[:sha1_file],
                                                 options[:force_download],
                                                 options[:verify_sha1],
                                                 options[:overrides],
                                                 options[:ssl_verify])
          say "Artifact has been retrieved and can be found at path: #{response[:file_path]}", :green
        end

        method_option :destination,
                      :type    => :string,
                      :default => nil,
                      :desc    => 'A different folder other than the default bundles directory.'
        method_option :force_download,
                      :type    => :boolean,
                      :default => false,
                      :desc    => 'Force download of the artifact even if it exists'
        method_option :verify_sha1,
                      :type    => :boolean,
                      :default => true,
                      :desc    => 'Validates sha1 sum'
        desc 'pull_defaultbundles <kb-version>', 'Pulls the default OSGI bundles from Sonatype and places it on your machine. If the kb-version has been specified, it is used to download the matching platform artifact; if not, it uses the latest released version.'
        def pull_defaultbundles(kb_version='LATEST')
          response = BaseInstaller.new(logger,
                                       options[:overrides],
                                       options[:ssl_verify])
                                  .install_default_bundles(options[:destination],
                                                           nil,
                                                           kb_version,
                                                           options[:force_download],
                                                           options[:verify_sha1])
          say "Artifact has been retrieved and can be found at path: #{response[:file_path]}", :green
        end

        desc 'search_for_plugins', 'Searches for all available plugins and prints them to the screen.'
        def search_for_plugins
          all_plugins = KillbillPluginArtifact.versions(options[:overrides], options[:ssl_verify])

          result = ''
          all_plugins.each do |type, plugins|
            result << "Available #{type} plugins:\n"
            Hash[plugins.sort].each do |name, versions|
              result << "  #{name}: #{versions.to_a.join(', ')}\n"
            end
          end

          say result, :green
        end

        method_option :destination,
                      :type    => :string,
                      :default => nil,
                      :desc    => 'A different folder other than the current working directory.'
        method_option :force_download,
                      :type    => :boolean,
                      :default => false,
                      :desc    => 'Force download of the artifact even if it exists'
        method_option :sha1_file,
                      :type    => :string,
                      :default => nil,
                      :desc    => 'Location of the sha1 file'
        method_option :verify_sha1,
                      :type    => :boolean,
                      :default => true,
                      :desc    => 'Validates sha1 sum'
        desc 'pull_kaui_war <version>', 'Pulls Kaui war from Sonatype and places it on your machine. If version was not specified it uses the latest released version.'
        def pull_kaui_war(version='LATEST')
          response = KauiArtifact.pull(logger,
                                       KauiArtifact::KAUI_GROUP_ID,
                                       KauiArtifact::KAUI_ARTIFACT_ID,
                                       KauiArtifact::KAUI_PACKAGING,
                                       KauiArtifact::KAUI_CLASSIFIER,
                                       version,
                                       options[:destination],
                                       options[:sha1_file],
                                       options[:force_download],
                                       options[:verify_sha1],
                                       options[:overrides],
                                       options[:ssl_verify])
          say "Artifact has been retrieved and can be found at path: #{response[:file_path]}", :green
        end

        desc 'search_for_kaui', 'Searches for all versions of Kaui and prints them to the screen.'
        def search_for_kaui
          say "Available versions: #{KauiArtifact.versions(options[:overrides], options[:ssl_verify]).to_a.join(', ')}", :green
        end

        method_option :version,
                      :type => :string,
                      :default => 'LATEST',
                      :desc => 'Kill Bill version'
        desc 'info', 'Describe information about a Kill Bill version'
        def info

          say "Fetching info for version #{options[:version]}...\n"

          versions_info = KillbillServerArtifact.info(options[:version],
                                             options[:overrides],
                                             options[:ssl_verify])
          say "Dependencies for version #{options[:version]}\n  " + (versions_info.map {|k,v| "#{k} #{v}"}).join("\n  "), :green
          say "\n\n"

          resolved_kb_version = versions_info['killbill']
          kb_version = resolved_kb_version.split('.').slice(0,2).join(".")

          plugins_info = KPM::PluginsDirectory.list_plugins(true, kb_version)

          say "Known plugin for KB version #{options[:version]}\n  " + (plugins_info.map {|k,v| "#{k} #{v}"}).join("\n  "), :green
        end

        private

        def logger
          logger       = ::Logger.new(STDOUT)
          logger.level = Logger::INFO
          logger
        end
      end
    end
  end
end
