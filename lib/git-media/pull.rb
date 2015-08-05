# find files that are placeholders (41 char) and download them
require 'git-media/status'

module GitMedia
  module Pull

    def self.run!(opts)
      @server = GitMedia.get_transport
      self.pull_media(opts[:dir])
      self.update_index(opts[:dir])
    end

    def self.pull_media(relative_path=false)
      status = GitMedia::Status.get_pull_status(relative_path)
      status[:unpulled].each_with_index do |tuple, index|
        file = tuple[0]
        sha = tuple[1]
        cache_file = GitMedia.media_path(sha)
        if !File.exist?(cache_file)
          puts "Downloading " + sha[0,8]
          @server.pull(sha)
        end
        if File.exist?(cache_file)
          puts "Expanding " + (index+1).to_s + " of " + status[:unpulled].length.to_s + ": " + sha[0,8] + " => " + file
          FileUtils.cp(cache_file, file)
        else
          puts "Expanding " + (index+1).to_s + " of " + status[:unpulled].length.to_s + ": Could not get media from storage"
        end
      end
    end

    def self.update_index(relative_path=false)
      refs = GitMedia::Status.get_pull_status(relative_path)

      begin
        # Split references up into lists of at most 500
        # because most OSs have limits on the size of the argument list
        # TODO: Could probably use the --stdin flag on git update-index to be
        # able to update it in a single call
        refLists = refs[:pulled].each_slice(500).to_a
        refLists.each do |refList|
          refList = refList.map { |v| "\"" + v + "\"" }
          `git update-index --assume-unchanged -- #{refList.join(' ')}`
        end
      rescue
        puts "Failed to update your git index, your repo is in a non-working state!"
      end
    end

  end
end
