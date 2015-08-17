require 'git-media/status'

module GitMedia
  module Clear

    def self.run!
      @server = GitMedia.get_transport
      self.clear_local_cache
    end

    def self.clear_local_cache
      # Remove no longer needed files from cache
      refs = GitMedia::Status.get_status(false, @server)
      refs[:cached].each { |file| self.remove_cache_file(file, true) }
    end

    def self.remove_cache_file(file, verbose=false)
      cache_file = File.join(file[:path], GitMedia.sha_to_path(file[:sha]))
      if File.exists?(cache_file)
        puts "Removing " + cache_file if verbose
        File.unlink(cache_file)
      end
    end

  end
end
