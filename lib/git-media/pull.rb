# find files that are placeholders (41 char) and download them
require 'git-media/status'

module GitMedia
  module Pull

    def self.run!(opts)
      @server = GitMedia.get_transport
      self.pull_media(opts[:dir], opts[:clear])
      self.update_index(opts[:dir])
    end

    def self.pull_media(relative_path=false, clear=false, server=@server)
      refs = GitMedia::Status.get_pull_status(relative_path, server)
      refs[:unpulled].each_with_index do |file, index|
        cache_file = GitMedia.media_path(file[:sha])
        if !File.exist?(cache_file)
          puts "Downloading " + (index+1).to_s + " of " + refs[:unpulled].length.to_s + ": " + file[:sha][0,8] + " => " + file[:name]
          server.pull(file[:sha])
          not_downloaded = false
        end
        if File.exist?(cache_file)
          puts "Reusing     " + (index+1).to_s + " of " + refs[:unpulled].length.to_s + ": " + file[:sha][0,8] + " => " + file[:name] if not_downloaded
          FileUtils.cp(cache_file, File.join(file[:path], file[:name]))
          File.unlink(cache_file) if clear
        else
          puts "Problem at  " + (index+1).to_s + " of " + refs[:unpulled].length.to_s + ": Could not get media from storage"
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
        pulled_files = refs[:pulled].map { |f| File.join(f[:path], f[:name]) }
        pulled_files = pulled_files.each_slice(500).to_a
        pulled_files.each do |file|
          file = file.map { |f| "\"" + f + "\"" }
          `git update-index --assume-unchanged -- #{file.join(' ')}`
        end
      rescue
        puts "Failed to update your git index, your repo is in a non-working state!"
      end
    end

  end
end
