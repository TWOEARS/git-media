# upload files in media buffer that are not in offsite bin
require 'git-media/status'

module GitMedia
  module Push

    def self.run!(opts)
      @server = GitMedia.get_transport
      self.push_media(opts[:clean])
    end

    def self.push_media(clean=false, server=@server)
      # Find files in media buffer and upload them
      all_cache = GitMedia.get_cache_files
      unpushed_files = server.get_unpushed(all_cache)
      unpushed_files.each_with_index do |sha, index|
        cache_file = GitMedia.media_path(sha)
        puts "Uploading " + (index+1).to_s + " of " + unpushed_files.length.to_s + ": " + cache_file + " => " + sha[0, 8]
        server.push(sha)
        if server.exist?(sha) && clean
          File.unlink(cache_file)
        end
      end
    end

  end
end
