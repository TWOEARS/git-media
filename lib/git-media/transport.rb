module GitMedia
  module Transport
    class Base

      def pull(sha)
        to_file = GitMedia.media_path(sha)
        from_file = GitMedia.sha_to_path(sha)
        get_file(from_file, to_file)
      end

      def push(sha)
        from_file = GitMedia.media_path(sha)
        to_file = GitMedia.sha_to_path(sha)
        put_file(to_file, from_file)
      end

      def exist?(sha)
        file = GitMedia.sha_to_path(sha)
        has_file?(file)
      end

      ## OVERWRITE ##

      def read?
        false
      end

      def write?
        false
      end

      def has_file?(file)
        false
      end

      def get_file(sha, to_file)
        false
      end

      def put_file(sha, to_file)
        false
      end

      def get_media_files
        []
      end

      #def get_unpushed(files)
      #  files
      #end

    end
  end
end
