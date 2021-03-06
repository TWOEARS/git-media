# find files that are placeholders (41 char) and download them
# upload files in media buffer that are not in offsite bin
require 'git-media/push'
require 'git-media/pull'

module GitMedia
  module Sync

    def self.run!(opts)
      @server = GitMedia.get_transport
      GitMedia::Pull.pull_media(opts[:dir], opts[:clear], @server)
      GitMedia::Push.push_media(opts[:clear], @server)
    end

  end
end
