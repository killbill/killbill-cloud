require 'pathname'
require 'rubygems/package'
require 'zlib'

module KPM
  class Utils
    class << self
      TAR_LONGLINK = '././@LongLink'

      def unpack_tgz(tar_gz_archive, destination, skip_top_dir=false)
        top_dir = nil
        Gem::Package::TarReader.new(Zlib::GzipReader.open(tar_gz_archive)) do |tar|
          dest = nil
          tar.each do |entry|
            if entry.full_name == TAR_LONGLINK
              dest = File.join destination, skip_top_dir ? path_with_skipped_top_level_dir(entry.read.strip) : entry.read.strip
              next
            end
            dest ||= File.join destination, skip_top_dir ? path_with_skipped_top_level_dir(entry.full_name) : entry.full_name

            if entry.directory?
              File.delete dest if File.file? dest
              FileUtils.mkdir_p dest, :mode => entry.header.mode, :verbose => false
            elsif entry.file?
              FileUtils.rm_rf dest if File.directory? dest
              File.open dest, "wb" do |f|
                f.print entry.read
              end
              FileUtils.chmod entry.header.mode, dest, :verbose => false
              current_dir = File.dirname(dest)
              # In case there are two top dirs, keep the last one by convention
              top_dir = current_dir if (top_dir.nil? || top_dir.size >= current_dir.size)
            elsif entry.header.typeflag == '2' # Symlink
              File.symlink entry.header.linkname, dest
            end
            dest = nil
          end
        end
        top_dir
      end

      def path_with_skipped_top_level_dir(path)
        Pathname(path).each_filename.to_a[1..-1].join(File::SEPARATOR)
      end
    end
  end
end
