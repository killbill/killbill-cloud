# frozen_string_literal: true

require_relative 'cpu_information'
require_relative 'memory_information'
require_relative 'disk_space_information'
require_relative 'entropy_available'
require_relative 'os_information'
module KPM
  module SystemProxy
    module OS
      def self.windows?
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RbConfig::CONFIG['host_os']) != nil
      end

      def self.mac?
        (/darwin/ =~ RbConfig::CONFIG['host_os']) != nil
      end

      def self.unix?
        !OS.windows?
      end

      def self.linux?
        OS.unix? && !OS.mac?
      end
    end
  end
end
