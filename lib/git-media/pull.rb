# find files that are placeholders (41 char) and download them
require 'git-media/status'

module GitMedia
  module Pull

    def self.run!(opts)
      @server = GitMedia.get_transport
      self.pull_media(opts[:dir], opts[:clean])
      self.update_index(opts[:dir])
    end

    def self.pull_media(relative_path=false, clean=false, server=@server)
      refs = GitMedia::Status.get_pull_status(relative_path, server)
      refs[:unpulled].each_with_index do |file, index|
        cache_file = GitMedia.media_path(file[:sha])
        if !File.exist?(cache_file)
          puts "Downloading " + (index+1).to_s + " of " + refs[:unpulled].length.to_s + ": " + file[:sha][0,8] + " => " + file[:name]
          server.pull(file[:sha])
        end
        if File.exist?(cache_file)
          FileUtils.cp(cache_file, File.join(file[:path], file[:name]))
          File.unlink(cache_file) if clean
        else
          puts "Downloading " + (index+1).to_s + " of " + refs[:unpulled].length.to_s + ": Could not get media from storage"
        end
      end
    end

    def self.update_index(relative_path=false, server=@server)
      refs = GitMedia::Status.get_pull_status(relative_path, server)

      begin
        # Split references up into lists of at most 500
        # because most OSs have limits on the size of the argument list
        # TODO: Could probably use the --stdin flag on git update-index to be
        # able to update it in a single call
        refs[:pulled] = refs[:pulled].map { |r| File.join(r[:path], r[:name]) }
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
