# upload files in media buffer that are not in offsite bin
require 'git-media/status'

module GitMedia
  module Push

    def self.run!
      @push = GitMedia.get_push_transport
      self.push_media
    end

    def self.push_media
      # Find files in media buffer and upload them
      all_cache = Dir.chdir(GitMedia.get_media_buffer) { Dir.glob('*') }
      unpushed_files = @push.get_unpushed(all_cache)
      unpushed_files.each_with_index do |sha, index|
        puts "Uploading " + sha[0, 8] + " " + (index+1).to_s + " of " + unpushed_files.length.to_s
        @push.push(sha)
      end
      # TODO: if --clean, remove them
    end

  end
end
