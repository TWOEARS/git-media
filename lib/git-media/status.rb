require 'pp'
Encoding.default_external = Encoding::UTF_8

module GitMedia
  module Status

    def self.run!(opts)
      @server = GitMedia.get_transport
      r = self.get_pull_status(opts[:dir])
      c = self.get_push_status
      self.print_pull_status(r, opts[:dir])
      self.print_push_status(c)
    end

    def self.get_pull_status(relative_path=false, server=@server)
      # Find files that are likely media entries and check if they are
      # downloaded already
      references = {:unpulled => [], :pulled => [], :deleted => [], :not_on_server => []}
      files = GitMedia.get_media_files(relative_path)
      files.each do |file|
        fname = File.join(file[:path], file[:name])
        if File.exists?(fname)
          # Windows newlines can offset file size by 1
          if file[:size].to_i == 41 or file[:size].to_i == 42
            references[:unpulled] << file
            references[:not_on_server] << file if !server.exist?(file[:sha])
          else
            references[:pulled] << file
          end
        else
          # File was deleted
          references[:deleted] << file
        end
      end
      references
    end

    def self.get_push_status(server=@server)
      # Find files in media buffer and check if they are uploaded already
      refs = {:unpushed => [], :cached => []}
      cache_files = GitMedia.get_cache_files
      unpushed_files = server.get_unpushed(cache_files) rescue []
      refs[:unpushed] = unpushed_files
      refs[:cached] = cache_files - unpushed_files rescue []
      refs
    end

    def self.print_pull_status(refs, relative_path=false)

      # Unpulled media
      if refs[:unpulled].size > 0
        hint = ", run 'git media pull"
        hint << " --dir" if relative_path
        hint << "' to download them"
      else
        hint = ""
      end
      if refs[:not_on_server].size > 0
        hint << ". WARNING: " + refs[:not_on_server].size.to_s + " of them are not on the server!"
      end
      puts "== Unpulled Media: " + refs[:unpulled].size.to_s + " file(s)" + hint

      # Pulled media
      puts "== Pulled Media:   " + refs[:pulled].size.to_s + " file(s)"

      # Deleted media
      if refs[:deleted].size > 0
        hint = ", run 'git rm <file(s)> && git commit' to remove completely"
        puts "== Deleted Media:  " + refs[:deleted].size.to_s + " file(s)" + hint
      end

    end

    def self.print_push_status(refs)

      # Unpushed media
      if refs[:unpushed].size > 0
        hint = ", run 'git media push' to upload them"
      else
        hint = ""
      end
      puts "== Unpushed Media: " + refs[:unpushed].size.to_s + " file(s)" + hint

      # Cached media (under .git/media/objects)
      if refs[:cached].size > 0
        hint = ", run 'git media clear' to remove them from temp dir"
        puts "== Cached Media:   " + refs[:cached].size.to_s + " file(s)" + hint
      end

    end

  end
end

# vim: sw=2 ts=2:
