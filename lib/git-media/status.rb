# Get status and information on (un)pulled + (un)pushed files
module GitMedia
  module Status

    def self.run!(opts)
      @server = GitMedia.get_transport
      refs = self.get_status(opts[:dir])
      self.print_status(refs, opts[:dir])
    end

    def self.get_pull_status(relative_path=false, server=@server)
      self.get_status(relative_path, server)
    end

    def self.get_push_status(server=@server)
      self.get_status(false, server)
    end

    def self.get_status(relative_path=false, server=@server)
      # Find files that are likely media entries and check if they are
      # downloaded already
      refs = {:unpulled => [], :pulled => [], :deleted => [], :not_on_server => [], :unpushed => [], :cached => []}
      files = GitMedia.get_media_files(relative_path)
      files_on_server = server.get_media_files
      files_in_cache = GitMedia.get_cache_files(files)
      # Create lookup table for file size from server
      size_on_server = Hash[files_on_server.map { |f| f.values_at(:name, :size) }]
      files.each do |file|

        fname = File.join(file[:path], file[:name])

        # Update media size by values from server
        local_size = file[:size] # store local size
        if size_on_server[file[:sha]]
          file[:size] = size_on_server[file[:sha]]
        else
          file[:size] = 0
          refs[:not_on_server] << file if File.exists?(fname)
        end

        # Check if media file has been pulled by checking its local size
        if File.exists?(fname)
          # Windows newlines can offset file size by 1
          if local_size == 41 or local_size == 42
            refs[:unpulled] << file
          else
            refs[:pulled] << file
          end
        else
          # File was deleted
          refs[:deleted] << file
        end

      end

      # Check if media files from cache have been pushed
      intersection = files_in_cache.map { |f| f[:sha] } & files_on_server.map { |f| f[:sha] }
      refs[:unpushed] = files_in_cache.select { |f| !intersection.include?(f[:sha]) }
      refs[:cached] = files_in_cache - refs[:unpushed] rescue []

      refs
    end

    def self.print_status(refs, relative_path=false)
      puts

      # Unpulled media
      hint = ", run 'git media pull"
      hint << " --dir" if relative_path
      hint << "' to download them"
      if refs[:not_on_server].size > 0
        hint << ". WARNING: " + refs[:not_on_server].size.to_s + " of them are not on the server!"
      end
      self.display(refs[:unpulled], "Unpulled Media", hint)

      # Pulled media
      self.display(refs[:pulled], "Pulled Media")

      # Deleted media
      if refs[:deleted].size > 0
        hint = ", run 'git rm <file> && git commit' to remove completely\n" +
               " "*44 + "run 'git checkout -- <file>' to restore"
        self.display(refs[:deleted], "Deleted Media", hint)
      end

      # Unpushed media
      hint = ", run 'git media push' to upload them"
      self.display(refs[:unpushed], "Unpushed Media", hint)

      # Cached media (under .git/media/objects)
      if refs[:cached].size > 0
        hint = ", run 'git media clear' to remove them from temp dir"
        self.display(refs[:cached], "Cached Media", hint)
      end
    end

    def self.display(refs, message, hint="")
      hint = "" if refs.size == 0
      puts "== #{message.ljust(15)}: #{refs.size.to_s.rjust(6)} file(s), (#{self.media_size(refs).rjust(4)})" + hint 
    end

    def self.media_size(files)
      # Sum up the size of all given files
      self.to_human(files.inject(0) { |sum, file| sum + file[:size] })
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
