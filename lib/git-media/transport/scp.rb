require 'git-media/transport'
require 'net/sftp'

# move large media to remote server via SCP

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
        unless port === ""
          @sshport = "-p#{port}"
        end
        unless port === ""
          @scpport = "-P#{port}"
        end
      end

      def exist?(file)
        if `ssh #{@user}@#{@host} #{@sshport} [ -f "#{file}" ] && echo 1 || echo 0`.chomp == "1"
          return true
        else
          return false
        end
      end

      def read?
        return true
      end

      def get_file(sha, to_file)
        from_file = @user+"@"+@host+":"+File.join(@path, sha)
        `scp #{@scpport} "#{from_file}" "#{to_file}"`
        if $? == 0
          return true
        end
        puts sha+" download fail"
        return false
      end

      def write?
        return true
      end

      def put_file(sha, from_file)
        to_file = @user+"@"+@host+":"+File.join(@path, sha)
        `scp #{@scpport} "#{from_file}" "#{to_file}"`
        if $? == 0
          return true
        end
        puts sha+" upload fail"
        return false
      end
      
      def get_unpushed(files)
        Net::SFTP.start(@host, @user) do |sftp|
          files_on_server = sftp.dir.entries(@path).map { |e| e.name }
          # Get rid of ".." and "." entries
          files_on_server = files_on_server.delete_if { |e| e === ".." || e === "." }
          return files - files_on_server rescue []
        end
      end
      
    end
  end
end
