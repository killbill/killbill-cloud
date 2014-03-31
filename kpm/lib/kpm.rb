module KPM
  autoload :Utils, 'kpm/utils'
  autoload :BaseArtifact, 'kpm/base_artifact'
  autoload :KillbillServerArtifact, 'kpm/killbill_server_artifact'
  autoload :KillbillPluginArtifact, 'kpm/killbill_plugin_artifact'
  autoload :Installer, 'kpm/installer'
  autoload :Tasks, 'kpm/tasks'
  autoload :Cli, 'kpm/cli'

  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end

    def ui
      @ui ||= Thor::Shell::Color.new
    end
  end
end