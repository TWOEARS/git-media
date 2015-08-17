require 'git-media/transport'
require 'net/sftp'

# move large media to remote server via SFTP

# git-media.transport scp
# git-media.scpuser someuser
# git-media.scphost remoteserver.com
# git-media.scppath /opt/media

module GitMedia
  module Transport
    class Scp < Base

      def initialize(user, host, path, port)
        @user = user
        @host = host
        @path = path
        @port = port
        if port.empty?
          @connection = Net::SFTP.start(@host, @user)
        else
          @connection = Net::SFTP.start(@host, @user, :port=>@port)
        end
      end

      def has_file?(file)
        begin
          @connection.stat!(File.join(@path, file))
          return true
        rescue
          return false
        end
      end

      def read?
        return true
      end

      def get_file(sha, to_file)
        from_file = File.join(@path, sha)
        begin
          FileUtils.mkdir_p(File.dirname(to_file))
          @connection.download!(from_file, to_file)
          return true
        rescue
          if !self.exist?(sha)
            puts "... download failed: File not on server."
          else
            puts "... download failed."
          end
          return false
        end
      end

      def write?
        return true
      end

      def put_file(sha, from_file)
        to_file = File.join(@path, sha)
        self.create_dir(File.dirname(to_file))
        begin
          @connection.upload!(from_file, to_file)
          return true
        rescue
          puts "... upload failed"
          begin
            @connection.remove!(to_file)
          rescue
          end
          return false
        end
      end

      def get_media_files
        begin
          @connection.dir.glob(@path, '*/*').map do |file|
            { size: file.attributes.size.to_i, path: @path, name: file.name, sha: GitMedia.path_to_sha(file.name) }
          end
        rescue
          []
        end
      end

      def create_dir(path)
        begin
          @connection.mkdir!(path)
        rescue Net::SFTP::StatusException => e
          # Creation of directory fails if it already exist. This rescue
          # with doing nothing circumvances an error.
        end
      end

      #def get_unpushed(files)
      #  files_on_server = @connection.dir.glob(@path, '*').map { |e| e.name }
      #  files.select { |f| files_on_server.include?(f[:sha]) }
      #  files
      #end

    end
  end
end
