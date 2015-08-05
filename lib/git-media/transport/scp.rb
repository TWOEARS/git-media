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
        # TODO: port is no longer used, is this a problem?
        unless port === ""
          @sshport = "-p#{port}"
        end
        unless port === ""
          @scpport = "-P#{port}"
        end
        @connection = Net::SFTP.start(@host, @user)
      end

      def exist?(file)
        begin
          # TODO: check why the following prints the path two times?
          #puts File.join(@path, file)
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
          @connection.download!(from_file, to_file)
          return true
        rescue
          if !self.exist?(sha)
            puts sha[0, 8] + " download failed: File not on server."
          else
            puts sha[0, 8] + " download failed."
          end
          return false
        end
      end

      def write?
        return true
      end

      def put_file(sha, from_file)
        to_file = File.join(@path, sha)
        begin
          @connection.upload!(from_file, to_file)
          return true
        rescue
          puts sha+" upload fail"
          return false
        end
      end

      def get_unpushed(files)
        files_on_server = @connection.dir.entries(@path).map { |e| e.name }
        # Get rid of ".." and "." entries
        files_on_server = files_on_server.delete_if { |e| e === ".." || e === "." }
        return files - files_on_server rescue []
      end

    end
  end
end
