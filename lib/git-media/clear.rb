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
      refs[:cached].each do |file|
        puts "Removing " + file[:sha][0, 8]
        File.unlink(File.join(file[:path], file[:sha]))
      end
    end

  end
end
