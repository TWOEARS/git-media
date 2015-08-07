require 'pp'
Encoding.default_external = Encoding::UTF_8

module GitMedia
  module Status

    def self.run!(opts)
      @server = GitMedia.get_transport
      r = self.get_pull_status(opts[:dir])
      c = self.get_push_status
      self.print_pull_status(r, opts[:long], opts[:dir])
      self.print_push_status(c, opts[:long])
    end

    def self.get_pull_status(relative_path=false, server=@server)
      # Find files that are likely media entries and check if they are
      # downloaded already
      references = {:unpulled => [], :pulled => [], :deleted => [], :not_on_server => []}
      files = GitMedia.get_files_with_size_path_name_sha(relative_path)
      files.each do |file|
        fname = File.join(file[:path], file[:name])
        if File.exists?(fname)
          # Windows newlines can offset file size by 1
          if file[:size].to_i == 41 or file[:size].to_i == 42
            references[:unpulled] << [file[:name], file[:sha]]
            references[:not_on_server] << [file[:name]] if !server.exist?(file[:sha])
          else
            references[:pulled] << [file[:name]]
          end
        else
          # File was deleted
          references[:deleted] << [file[:name]]
        end
      end
      references
    end

    def self.get_push_status(server=@server)
      # Find files in media buffer and check if they are uploaded already
      references = {:unpushed => [], :pushed => []}
      all_cache = GitMedia.get_cache_files
      unpushed_files = server.get_unpushed(all_cache) || []
      references[:unpushed] = unpushed_files
      references[:pushed] = all_cache - unpushed_files rescue []
      references
    end

    def self.print_pull_status(refs, long=false, relative_path=false)

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
      if long
        refs[:unpulled].each do |file, sha|
          # TODO: get local file name
          puts "   " + sha[0, 8] + " " + file
        end
        puts
      end

      # Pulled media
      puts "== Pulled Media:   " + refs[:pulled].size.to_s + " file(s)"
      if long
        refs[:pulled].each do |file|
          size = File.size(file)
          puts "   " + "(#{self.to_human(size)})".ljust(8) + " #{file}"
        end
        puts
      end

      # Deleted media
      if refs[:deleted].size > 0
        hint = ", run 'git rm <file(s)> && git commit' to remove completely"
        puts "== Deleted Media:  " + refs[:deleted].size.to_s + " file(s)" + hint
        if long
          refs[:deleted].each do |file|
            puts "           " + " #{file}"
          end
          puts
        end
      end

    end

    def self.print_push_status(refs, long=false)

      # Unpushed media
      if refs[:unpushed].size > 0
        hint = ", run 'git media push' to upload them"
      else
        hint = ""
      end
      puts "== Unpushed Media: " + refs[:unpushed].size.to_s + " file(s)" + hint
      if long
        refs[:unpushed].each do |sha|
          cache_file = GitMedia.media_path(sha)
          size = File.size(cache_file)
          puts "   " + "(#{self.to_human(size)})".ljust(8) + " " + sha[0, 8] + " " + cache_file
        end
        puts
      end

      # Cached media (under .git/media/objects)
      if refs[:pushed].size > 0
        hint = ", run 'git media clear' to remove them from temp dir"
        puts "== Cached Media:   " + refs[:pushed].size.to_s + " file(s)" + hint
        if long
          refs[:pushed].each do |sha|
            cache_file = GitMedia.media_path(sha)
            size = File.size(cache_file)
            puts "   " + "(#{self.to_human(size)})".ljust(8) + ' ' + sha[0, 8]
          end
          puts
        end
      end

    end

    def self.to_human(size)
      if size < 1024
        return size.to_s + 'b'
      elsif size < 1048576
        return (size / 1024).to_s + 'k'
      else
        return (size / 1048576).to_s + 'm'
      end
    end

  end
end

# vim: sw=2 ts=2:
