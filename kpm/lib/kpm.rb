module KPM
  autoload :Utils, 'kpm/utils'
  autoload :BaseArtifact, 'kpm/base_artifact'
  autoload :Sha1Checker, 'kpm/sha1_checker'
  autoload :TomcatManager, 'kpm/tomcat_manager'
  autoload :KillbillServerArtifact, 'kpm/killbill_server_artifact'
  autoload :KillbillPluginArtifact, 'kpm/killbill_plugin_artifact'
  autoload :KauiArtifact, 'kpm/kaui_artifact'
  autoload :PluginsManager, 'kpm/plugins_manager'
  autoload :BaseInstaller, 'kpm/base_installer'
  autoload :Installer, 'kpm/installer'
  autoload :Tasks, 'kpm/tasks'
  autoload :Cli, 'kpm/cli'
  autoload :PluginsDirectory, 'kpm/plugins_directory'

  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end

    def ui
      @ui ||= Thor::Shell::Color.new
    end
  end
end
