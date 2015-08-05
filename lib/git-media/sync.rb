# find files that are placeholders (41 char) and download them
# upload files in media buffer that are not in offsite bin
require 'git-media/status'
require 'git-media/push'
require 'git-media/pull'

module GitMedia
  module Sync

    def self.run!
      # TODO: the following connects two times to the server, maybe we could
      # reduce it to one time.
      GitMedia::Pull.run!
      GitMedia::Push.run!
    end

  end
end
