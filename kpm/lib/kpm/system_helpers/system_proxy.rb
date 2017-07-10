require_relative 'cpu_information'
require_relative 'memory_information'
require_relative 'disk_space_information'
require_relative 'entropy_available'
require_relative 'os_information'
module SystemProxy

  module OS
    def OS.windows?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RbConfig::CONFIG["host_os"]) != nil
    end

    def OS.mac?
      (/darwin/ =~ RbConfig::CONFIG["host_os"]) != nil
    end

    def OS.unix?
      !OS.windows?
    end

    def OS.linux?
      OS.unix? and not OS.mac?
    end
  end

end