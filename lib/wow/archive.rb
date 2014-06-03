require 'rubygems/package'
require 'pathname'

module Wow
  class Archive
    attr_accessor :gz
    attr_accessor :io
    attr_accessor :tar_writer
    attr_accessor :tar_reader
    attr_accessor :archive_filename

    #Open archive file to read
    # @param filename Archive filename
    # @param block Optional block the archive is given as param
    def self.open(filename, &block)
      archive = Archive.new
      archive.tar_reader = Gem::Package::TarReader.new(Zlib::GzipReader.open(filename))
      if block_given?
        block.call(archive)
        archive.tar_reader.close
      end
      archive
    end

    def self.write(filename, &block)
      archive = Archive.new
      archive.io = StringIO.new('')
      archive.gz = Zlib::GzipWriter.open(filename)
      archive.tar_writer = Gem::Package::TarWriter.new(archive.io)
      if block_given?
        block.call(archive)
        archive.close
      end
      archive
    end

    def each (&block)
      tar.each(&block)
    end

    #Close the file
    def close
      unless gz.nil?
        gz.write io.string
        gz.close
      end
      tar_reader.close if tar_reader
    end

    def add_file(filename, path_in_archive = '')
      mode = File.stat(filename).mode
      filename_in_archive = if Pathname.new(filename).absolute?
                              File.basename(filename)
                            else
                              filename
                            end
      archive_file_path = if path_in_archive.nil? or path_in_archive.empty?
                            filename_in_archive
                          else
                            Join(path_in_archive, filename_in_archive)
                          end
      tar_writer.add_file archive_file_path, mode do |tf|
        File.open(filename, 'rb') { |f|
          tf.write f.read
        }
      end
    end

    # Add the given list of files to the archive into the given folder

    def add_files(filenames, path_in_archive = '')
      [*filenames].each do |filename|
        add_file filename, path_in_archive
      end
    end

    def extract_all(destination)
      return false if tar_reader.nil?
      tar_reader.each do |tar_entity|
        destination_file = File.join destination, tar_entity.full_name
        if tar_entity.directory?
          FileUtils.mkdir_p destination_file
        else
          destination_directory = File.dirname(destination_file)
          FileUtils.mkdir_p destination_directory unless File.directory?(destination_directory)
          File.open destination_file, 'wb' do |f|
            f.print tar_entity.open
          end
        end
      end
    end

    def self.extract(filename, destination)
      Archive.open(filename) do |archive|
        archive.extract_all(destination)
      end
    end

    def self.create(filenames, output)
      Archive.write(output) do |archive|
        archive.add_files filenames
      end
    end
  end
end