require 'digest'

module GitMedia
  module Check

    def self.run!
      @server = GitMedia.get_transport
      self.check_local_cache
    end

    def self.check_local_cache(server=@server)

      puts "Checking local media cache.."
      cache_files = GitMedia.get_cache_files
      cache_files.each do |file|
        media_file = File.join(file[:path], file[:name])
        infile = File.open(media_file, 'rb')
        hashfunc = Digest::SHA1.new
        while data = infile.read(4096)
            hashfunc.update(data)
        end
        infile.close()
        sha = file[3..-1]
        if sha != hashfunc.hexdigest
          print "Pulling corrupt file "+sha+" ..."
          server.pull(sha)
          print " Done\n"
        end
      end

    end

  end
end
