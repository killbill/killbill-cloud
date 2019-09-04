require 'pathname'
require 'rubygems/package'
require 'zlib'

module KPM
  class Utils
    class << self
      TAR_LONGLINK = '././@LongLink'

      def unpack_tgz(tar_gz_archive, destination, skip_top_dir = false)
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
              FileUtils.mkdir_p File.dirname(dest), :verbose => false
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

      def peek_tgz_file_names(tar_gz_archive)
        file_names = []
        Gem::Package::TarReader.new(Zlib::GzipReader.open(tar_gz_archive)) do |tar|
          tar.each do |entry|
            if entry.file?
              file_names.push entry.full_name
            end
          end
        end

        file_names
      end

      def get_plugin_name_from_file_path(file_path)
        base = File.basename(file_path).to_s
        ver = get_version_from_file_path(file_path)
        ext = File.extname(base)

        name = base.gsub(ext, '')
        if ver.nil?
          # this will remove SNAPSHOT and any dash that appear before it (ex --SNAPSHOT).
          name = name.gsub(/((-+){,1}SNAPSHOT){,1}/, '')
          last_dash = name.rindex('-')
          name = name[0..last_dash] unless last_dash.nil?
        else
          name = name.gsub(ver, '')
        end

        name = name[0..name.length - 2] if name[-1].match(/[a-zA-z]/).nil?
        name
      end

      def get_version_from_file_path(file_path)
        base = File.basename(file_path).to_s
        ver = base.match(/(\d+)(\.(\d+)){,6}((-+){,1}SNAPSHOT){,1}/)

        return ver if ver.nil?

        ver[0]
      end
    end
  end
end
