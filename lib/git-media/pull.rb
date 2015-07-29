# find files that are placeholders (41 char) and download them
require 'git-media/status'

module GitMedia
  module Pull

    def self.run!
      @pull = GitMedia.get_pull_transport

      self.expand_references
      self.update_index
    end

    def self.expand_references
      status = GitMedia::Status.find_references
      status[:to_expand].each_with_index do |tuple, index|
        file = tuple[0]
        sha = tuple[1]
        cache_file = GitMedia.media_path(sha)
        if !File.exist?(cache_file)
          puts "Downloading " + sha[0,8] + " : " + file
          @pull.pull(file, sha)
        end

        puts "Expanding " + (index+1).to_s + " of " + status[:to_expand].length.to_s + " : " + sha[0,8] + " : " + file

        if File.exist?(cache_file)
          FileUtils.cp(cache_file, file)
        else
          puts 'Could not get media from storage'
        end
      end
    end

    def self.update_index
      refs = GitMedia::Status.find_references

      # Split references up into lists of at most 500
      # because most OSs have limits on the size of the argument list
      # TODO: Could probably use the --stdin flag on git update-index to be
      # able to update it in a single call
      refLists = refs[:expanded].each_slice(500).to_a

      refLists.each {
        |refList|

        refList = refList.map { |v| "\"" + v + "\""}

        `git update-index --assume-unchanged -- #{refList.join(' ')}`
      }
      
      puts "Updated git index"
    end

  end
end
