# frozen_string_literal: true

require 'highline'
require 'logger'
require 'thor'
require 'pathname'

require 'kpm/version'

module KPM
  module Tasks
    def self.included(base)
      base.send :include, ::Thor::Actions
      base.class_eval do
        desc 'version', 'Return current KPM version.'
        def version
          say "KPM version #{KPM::VERSION}"
        end

        class_option :overrides,
                     type: :hash,
                     default: nil,
                     desc: "A hashed list of overrides. Available options are 'url', 'repository', 'username', and 'password'."

        class_option :ssl_verify,
                     type: :boolean,
                     default: true,
                     desc: 'Set to false to disable SSL Verification.'

        method_option :force_download,
                      type: :boolean,
                      default: false,
                      desc: 'Force download of the artifact even if it exists'
        method_option :verify_sha1,
                      type: :boolean,
                      default: true,
                      desc: 'Validate sha1 sum'
        desc 'install config_file', 'Install Kill Bill server and plugins according to the specified YAML configuration file.'
        def install(config_file = nil)
          help = Installer.from_file(config_file).install(options[:force_download], options[:verify_sha1])
          help = JSON(help)
          say help['help'], :green unless help['help'].nil?
        end

        method_option :destination,
                      type: :string,
                      default: nil,
                      desc: 'A different folder other than the default bundles directory.'
        method_option :force,
                      type: :boolean,
                      default: nil,
                      desc: 'Don\'t ask for confirmation while deleting multiple versions of a plugin.'
        method_option :version,
                      type: :string,
                      default: nil,
                      desc: 'Specific plugin version to uninstall'
        desc 'uninstall plugin', 'Uninstall the specified plugin, identified by its name or key, from current deployment'
        def uninstall(plugin)
          Uninstaller.new(options[:destination]).uninstall_plugin(plugin, options[:force], options[:version])
        end

        method_option :destination,
                      type: :string,
                      default: nil,
                      desc: 'A different folder other than the default bundles directory.'
        method_option :dry_run,
                      type: :boolean,
                      default: false,
                      desc: 'Print the plugins which would be deleted'
        desc 'cleanup', 'Delete old plugins'
        def cleanup
          Uninstaller.new(options[:destination]).uninstall_non_default_plugins(options[:dry_run])
        end

        method_option :group_id,
                      type: :string,
                      default: KillbillServerArtifact::KILLBILL_GROUP_ID,
                      desc: 'The Kill Bill war artifact group-id'
        method_option :artifact_id,
                      type: :string,
                      default: KillbillServerArtifact::KILLBILL_ARTIFACT_ID,
                      desc: 'The Kill Bill war artifact id'
        method_option :packaging,
                      type: :string,
                      default: KillbillServerArtifact::KILLBILL_PACKAGING,
                      desc: 'The Kill Bill war packaging'
        method_option :classifier,
                      type: :string,
                      default: KillbillServerArtifact::KILLBILL_CLASSIFIER,
                      desc: 'The Kill Bill war classifier'
        method_option :destination,
                      type: :string,
                      default: nil,
                      desc: 'A different folder other than the current working directory.'
        method_option :bundles_dir,
                      type: :string,
                      default: nil,
                      desc: 'The location where bundles will be installed (along with sha1 file)'
        method_option :force_download,
                      type: :boolean,
                      default: false,
                      desc: 'Force download of the artifact even if it exists'
        method_option :verify_sha1,
                      type: :boolean,
                      default: true,
                      desc: 'Validate sha1 sum'
        desc 'pull_kb_server_war <version>', 'Pulls Kill Bill server war and places it on your machine. If version was not specified it uses the latest released version.'
        def pull_kb_server_war(version = 'LATEST')
          installer = BaseInstaller.new(logger,
                                        options[:overrides],
                                        options[:ssl_verify])
          response = installer.install_killbill_server(options[:group_id],
                                                       options[:artifact_id],
                                                       options[:packaging],
                                                       options[:classifier],
                                                       version,
                                                       options[:destination],
                                                       options[:bundles_dir],
                                                       options[:force_download],
                                                       options[:verify_sha1])
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

        method_option :group_id,
                      type: :string,
                      default: KillbillPluginArtifact::KILLBILL_JAVA_PLUGIN_GROUP_ID,
                      desc: 'The plugin artifact group-id'
        method_option :artifact_id,
                      type: :string,
                      default: nil,
                      desc: 'The plugin artifact id'
        method_option :version,
                      type: :string,
                      default: nil,
                      desc: 'The plugin artifact version'
        method_option :packaging,
                      type: :string,
                      default: KillbillPluginArtifact::KILLBILL_JAVA_PLUGIN_PACKAGING,
                      desc: 'The plugin artifact packaging'
        method_option :classifier,
                      type: :string,
                      default: KillbillPluginArtifact::KILLBILL_JAVA_PLUGIN_CLASSIFIER,
                      desc: 'The plugin artifact classifier'
        method_option :from_source_file,
                      type: :string,
                      default: nil,
                      desc: 'Specify the plugin jar that should be used for the installation.'
        method_option :destination,
                      type: :string,
                      default: nil,
                      desc: 'A different folder other than the current working directory.'
        method_option :force_download,
                      type: :boolean,
                      default: false,
                      desc: 'Force download of the artifact even if it exists'
        method_option :sha1_file,
                      type: :string,
                      default: nil,
                      desc: 'Location of the sha1 file'
        method_option :verify_sha1,
                      type: :boolean,
                      default: true,
                      desc: 'Validates sha1 sum'
        desc 'install_java_plugin plugin-key <kb-version>', 'Pulls a java plugin and installs it under the specified destination. If the kb-version has been specified, it is used to download the matching plugin artifact version; if not, it uses the specified plugin version or if null, the LATEST one.'
        def install_java_plugin(plugin_key, kb_version = 'LATEST')
          installer = BaseInstaller.new(logger,
                                        options[:overrides],
                                        options[:ssl_verify])

          response = if options[:from_source_file].nil?
                       installer.install_plugin(plugin_key,
                                                kb_version,
                                                options[:group_id],
                                                options[:artifact_id],
                                                options[:packaging],
                                                options[:classifier],
                                                options[:version],
                                                options[:destination],
                                                'java',
                                                options[:force_download],
                                                options[:verify_sha1])
                     else
                       installer.install_plugin_from_fs(plugin_key, options[:from_source_file], nil, options[:version], options[:destination], 'java')
                     end

          say "Artifact has been retrieved and can be found at path: #{response[:file_path]}", :green
        end

        method_option :destination,
                      type: :string,
                      default: nil,
                      desc: 'A different folder other than the default bundles directory.'
        method_option :force_download,
                      type: :boolean,
                      default: false,
                      desc: 'Force download of the artifact even if it exists'
        method_option :verify_sha1,
                      type: :boolean,
                      default: true,
                      desc: 'Validates sha1 sum'
        desc 'pull_defaultbundles <kb-version>', 'Pulls the default OSGI bundles and places it on your machine. If the kb-version has been specified, it is used to download the matching platform artifact; if not, it uses the latest released version.'
        def pull_defaultbundles(kb_version = 'LATEST')
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
                      type: :string,
                      default: nil,
                      desc: 'A different folder other than the current working directory.'
        method_option :force_download,
                      type: :boolean,
                      default: false,
                      desc: 'Force download of the artifact even if it exists'
        method_option :sha1_file,
                      type: :string,
                      default: nil,
                      desc: 'Location of the sha1 file'
        method_option :verify_sha1,
                      type: :boolean,
                      default: true,
                      desc: 'Validates sha1 sum'
        desc 'pull_kaui_war <version>', 'Pulls Kaui war and places it on your machine. If version was not specified it uses the latest released version.'
        def pull_kaui_war(version = 'LATEST')
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
                      type: :string,
                      default: 'LATEST',
                      desc: 'Kill Bill version'
        method_option :force_download,
                      type: :boolean,
                      default: false,
                      desc: 'Ignore local cache'
        method_option :sha1_file,
                      type: :string,
                      default: nil,
                      desc: 'Location of the sha1 file'
        method_option :verify_sha1,
                      type: :boolean,
                      default: true,
                      desc: 'Validates sha1 sum'
        method_option :as_json,
                      type: :boolean,
                      default: false,
                      desc: 'Set the output format as JSON when true'
        desc 'info', 'Describe information about a Kill Bill version'
        def info
          versions_info = KillbillServerArtifact.info(options[:version],
                                                      options[:sha1_file],
                                                      options[:force_download],
                                                      options[:verify_sha1],
                                                      options[:overrides],
                                                      options[:ssl_verify])
          resolved_kb_version = versions_info['killbill']
          kb_version = resolved_kb_version.split('.').slice(0, 2).join('.')

          plugins_info = KPM::PluginsDirectory.list_plugins(true, kb_version)

          if options[:as_json]
            puts({ 'killbill' => versions_info, 'plugins' => plugins_info }.to_json)
          else
            say "Dependencies for version #{options[:version]}\n  " + (versions_info.map { |k, v| "#{k} #{v}" }).join("\n  "), :green
            say "Known plugins for KB version #{options[:version]}\n  " + (plugins_info.map { |k, v| "#{k} #{v}" }).join("\n  "), :green
          end
        end

        method_option :destination,
                      type: :string,
                      default: nil,
                      desc: 'Folder where to download migration files.'
        method_option :token,
                      type: :string,
                      default: nil,
                      desc: 'GitHub OAuth token.'
        desc 'migrations repository from to', 'Download migration files for Kill Bill or a plugin'
        def migrations(repository, from, to = nil)
          full_repo = repository.include?('/') ? repository : "killbill/#{repository}"
          dir = KPM::Migrations.new(from, to, full_repo, options[:token], logger).save(options[:destination])
          say (dir.nil? ? 'No migration required' : "Migrations can be found at #{dir}"), :green
        end

        method_option :destination,
                      type: :string,
                      default: nil,
                      desc: 'A different folder other than the default bundles directory.'
        method_option :as_json,
                      type: :boolean,
                      default: false,
                      desc: 'Set the output format as JSON when true'
        desc 'inspect', 'Inspect current deployment'
        def inspect
          inspector = KPM::Inspector.new
          all_plugins = inspector.inspect(options[:destination])
          options[:as_json] ? puts(all_plugins.to_json) : inspector.format(all_plugins)
        end

        method_option :bundles_dir,
                      type: :string,
                      default: nil,
                      desc: 'A different folder other than the default bundles directory.'
        method_option :config_file,
                      type: :string,
                      default: nil,
                      desc: 'KPM configuration file (yml file)'
        method_option :as_json,
                      type: :boolean,
                      default: false,
                      desc: 'Set the output format as JSON when true'
        method_option :kaui_web_path,
                      type: :string,
                      default: nil,
                      desc: 'Path for the KAUI web app'
        method_option :killbill_web_path,
                      type: :string,
                      default: nil,
                      desc: 'Path for the killbill web app'
        desc 'system', 'Gather information about the system'
        def system
          system = KPM::System.new(logger)
          information = system.information(options[:bundles_dir], options[:as_json], options[:config_file], options[:kaui_web_path],
                                           options[:killbill_web_path])

          puts information if options[:as_json]
        end

        method_option :export,
                      type: :string,
                      default: nil,
                      desc: 'export account for a provided id.'
        method_option :import,
                      type: :string,
                      default: nil,
                      desc: 'import account for a previously exported file.'
        method_option :tenant_record_id,
                      type: :numeric,
                      default: nil,
                      desc: 'replace the tenant_record_id before importing data.'
        method_option :generate_record_id,
                      type: :boolean,
                      default: false,
                      desc: 'The generate_record_id will instruct to generate the tables record_ids that were exported'
        method_option :skip_payment_methods,
                      type: :boolean,
                      default: false,
                      desc: 'Skip or swap payment types other than __EXTERNAL_PAYMENT__.'
        method_option :config_file,
                      type: :string,
                      default: nil,
                      desc: 'Yml that contains killbill api connection and DB connection'
        method_option :killbill_api_credentials,
                      type: :array,
                      default: nil,
                      desc: 'Killbill api credentials <api_key> <api_secrets>'
        method_option :killbill_credentials,
                      type: :array,
                      default: nil,
                      desc: 'Killbill credentials <user> <password>'
        method_option :killbill_url,
                      type: :string,
                      default: nil,
                      desc: 'Killbill URL ex. http://127.0.0.1:8080'
        method_option :database_name,
                      type: :string,
                      default: nil,
                      desc: 'DB name to connect'
        method_option :database_credentials,
                      type: :array,
                      default: nil,
                      desc: 'DB credentials <user> <password>'
        method_option :data_delimiter,
                      type: :string,
                      default: '|',
                      desc: 'Data delimiter'
        method_option :database_host,
                      type: :string,
                      default: nil,
                      desc: 'Database Host name'
        method_option :database_port,
                      type: :string,
                      default: nil,
                      desc: 'Database port'
        desc 'account', 'export/import accounts'
        def account
          config_file = nil
          raise Interrupt, '--killbill_url, required format -> http(s)://something' if options[:killbill_url] && %r{https?://\S+}.match(options[:killbill_url]).nil?

          raise Interrupt, '--killbill_api_credentials, required format -> <api_key> <api_secrets>' if options[:killbill_api_credentials] && options[:killbill_api_credentials].size != 2

          raise Interrupt, '--killbill_credentials, required format -> <user> <password>' if options[:killbill_credentials] && options[:killbill_credentials].size != 2

          raise Interrupt, '--database_credentials, required format -> <user> <password>' if options[:database_credentials] && options[:database_credentials].size != 2

          raise Interrupt, '--database_credentials, please provide a valid database name' if options[:database_name] && options[:database_name] == :database_name.to_s

          config_file = File.join(__dir__, 'account_export_import.yml') if options[:config_file] && options[:config_file] == :config_file.to_s

          raise Interrupt, 'Need to specify an action' if options[:export].nil? && options[:import].nil?

          account = KPM::Account.new(config_file || options[:config_file], options[:killbill_api_credentials], options[:killbill_credentials],
                                     options[:killbill_url], options[:database_name], options[:database_credentials], options[:database_host], options[:database_port], options[:data_delimiter], logger)
          export_file = nil
          round_trip_export_import = false

          unless options[:export].nil?
            export_file = account.export_data(options[:export])
            round_trip_export_import = true
          end

          unless options[:import].nil?
            account.import_data(export_file || options[:import], options[:tenant_record_id], options[:skip_payment_methods],
                                round_trip_export_import, options[:generate_record_id])
          end
        rescue StandardError => e
          logger.error "\e[91;1m#{e.message}\e[0m"
          logger.error e.backtrace.join("\n") unless e.is_a?(Interrupt)
        end

        method_option :key_prefix,
                      type: :string,
                      default: nil,
                      enum: KPM::TenantConfig::KEY_PREFIXES,
                      desc: 'Retrieve a per tenant key value based on key prefix'
        method_option :killbill_api_credentials,
                      type: :array,
                      default: nil,
                      desc: 'Killbill api credentials <api_key> <api_secrets>'
        method_option :killbill_credentials,
                      type: :array,
                      default: nil,
                      desc: 'Killbill credentials <user> <password>'
        method_option :killbill_url,
                      type: :string,
                      default: nil,
                      desc: 'Killbill URL ex. http://127.0.0.1:8080'
        desc 'tenant_config', 'export all tenant-level configs.'
        def tenant_config
          raise Interrupt, '--killbill_url, required format -> http(s)://something' if options[:killbill_url] && %r{https?://\S+}.match(options[:killbill_url]).nil?

          raise Interrupt, '--killbill_api_credentials, required format -> <api_key> <api_secrets>' if options[:killbill_api_credentials] && options[:killbill_api_credentials].size != 2

          raise Interrupt, '--killbill_credentials, required format -> <user> <password>' if options[:killbill_credentials] && options[:killbill_credentials].size != 2

          raise Interrupt, "--key_prefix, posible values #{KPM::TenantConfig::KEY_PREFIXES.join(', ')}" if options[:key_prefix] == :key_prefix.to_s

          tenant_config = KPM::TenantConfig.new(options[:killbill_api_credentials], options[:killbill_credentials],
                                                options[:killbill_url], logger)

          tenant_config.export(options[:key_prefix])
        rescue StandardError => e
          logger.error "\e[91;1m#{e.message}\e[0m"
          logger.error e.backtrace.join("\n") unless e.is_a?(Interrupt)
        end

        method_option :account_export,
                      type: :string,
                      default: nil,
                      desc: 'export account for a provided id.'
        method_option :log_dir,
                      type: :string,
                      default: nil,
                      desc: '(Optional) Log directory if the default tomcat location has changed'
        method_option :config_file,
                      type: :string,
                      default: nil,
                      desc: 'Yml that contains killbill api connection and DB connection'
        method_option :killbill_api_credentials,
                      type: :array,
                      default: nil,
                      desc: 'Killbill api credentials <api_key> <api_secrets>'
        method_option :killbill_credentials,
                      type: :array,
                      default: nil,
                      desc: 'Killbill credentials <user> <password>'
        method_option :killbill_url,
                      type: :string,
                      default: nil,
                      desc: 'Killbill URL ex. http://127.0.0.1:8080'
        method_option :database_name,
                      type: :string,
                      default: nil,
                      desc: 'DB name to connect'
        method_option :database_credentials,
                      type: :array,
                      default: nil,
                      desc: 'DB credentials <user> <password>'
        method_option :database_host,
                      type: :string,
                      default: nil,
                      desc: 'Database Host name'
        method_option :database_port,
                      type: :string,
                      default: nil,
                      desc: 'Database port'
        method_option :kaui_web_path,
                      type: :string,
                      default: nil,
                      desc: 'Path for the KAUI web app'
        method_option :killbill_web_path,
                      type: :string,
                      default: nil,
                      desc: 'Path for the killbill web app'
        method_option :bundles_dir,
                      type: :string,
                      default: nil,
                      desc: 'A different folder other than the default bundles directory.'
        desc 'diagnostic', 'exports and \'zips\' the account data, system, logs and tenant configurations'
        def diagnostic
          raise Interrupt, '--account_export,  please provide a valid account id' if options[:account_export] && options[:account_export] == 'account_export'

          raise Interrupt, '--killbill_url, required format -> http(s)://something' if options[:killbill_url] && %r{https?://\S+}.match(options[:killbill_url]).nil?

          raise Interrupt, '--killbill_api_credentials, required format -> <api_key> <api_secrets>' if options[:killbill_api_credentials] && options[:killbill_api_credentials].size != 2

          raise Interrupt, '--killbill_credentials, required format -> <user> <password>' if options[:killbill_credentials] && options[:killbill_credentials].size != 2

          raise Interrupt, '--database_credentials, required format -> <user> <password>' if options[:database_credentials] && options[:database_credentials].size != 2

          raise Interrupt, '--database_credentials, please provide a valid database name' if options[:database_name] && options[:database_name] == :database_name.to_s

          raise Interrupt, '--kaui_web_path, please provide a valid kaui web path ' if options[:kaui_web_path] && options[:kaui_web_path] == :kaui_web_path.to_s

          raise Interrupt, '--killbill_web_path, please provide a valid killbill web path' if options[:killbill_web_path] && options[:killbill_web_path] == :killbill_web_path.to_s

          diagnostic = KPM::DiagnosticFile.new(options[:config_file], options[:killbill_api_credentials], options[:killbill_credentials],
                                               options[:killbill_url], options[:database_name], options[:database_credentials],
                                               options[:database_host], options[:database_port], options[:kaui_web_path], options[:killbill_web_path], options[:bundles_dir], logger)
          diagnostic.export_data(options[:account_export], options[:log_dir])
        rescue StandardError => e
          logger.error "\e[91;1m#{e.message}\e[0m"
          logger.error e.backtrace.join("\n") unless e.is_a?(Interrupt)
        end

        map pull_java_plugin: :install_java_plugin

        private

        def logger
          logger       = ::Logger.new(STDOUT)
          logger.level = ENV['KPM_DEBUG'] ? Logger::DEBUG : Logger::INFO
          logger
        end
      end
    end
  end
end
