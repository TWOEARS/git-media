require 'digest'

module GitMedia
  module Check

    def self.run!
      @server = GitMedia.get_transport
      self.check_local_cache
    end

    def self.check_local_cache(server=@server)

      puts "Checking local media cache.."
      all_cache = GitMedia.get_cache_files
      all_cache.each do |file|
        media_file = GitMedia.media_path(file)
        infile = File.open(media_file, 'rb')
        hashfunc = Digest::SHA1.new
        while data = infile.read(4096)
            hashfunc.update(data)
        end
        infile.close()
        sha = file[3..-1]
        if sha != hashfunc.hexdigest then
          print "Pulling corrupt file "+sha+" ..."
          server.pull(sha)
          print " Done\n"
        end
      end

    end

  end
end
