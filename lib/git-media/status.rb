require 'pp'
Encoding.default_external = Encoding::UTF_8

module GitMedia
  module Status

    def self.run!(opts)
      @push = GitMedia.get_push_transport
      r = self.get_pull_status(opts[:dir])
      c = self.get_push_status
      self.print_pull_status(r, opts[:long], opts[:dir])
      self.print_push_status(c, opts[:long])
    end

    def self.get_pull_status(relative_path=false)
      # Find files that are likely media entries and check if they are
      # downloaded already
      references = {:unpulled => [], :pulled => [], :deleted => []}
      if relative_path
        files = `git ls-tree -l -r HEAD | tr "\\000" \\\\n`.split("\n")
        repo_path = "."
      else
        files = `git ls-tree -l -r HEAD --full-tree | tr "\\000" \\\\n`.split("\n")
        repo_path = `git rev-parse --show-toplevel`.chomp
      end
      files = files.map { |f| s = f.split("\t"); [s[0].split(' ').last, s[1]] }
      # => files = [[file_size, file_name], [...], ...]
      # Find unpulled files after looking at its size
      # TODO: this seems a little bit risky, what if a file has mistakenly the
      # same size
      files = files.select { |f| f[0] == '41' } # it's the right size
      files.each do |tree_size, fname|
        fname = File.join(repo_path, fname)
        if File.exists?(fname)
          size = File.size(fname)
          # Windows newlines can offset file size by 1
          if size == tree_size.to_i or size == tree_size.to_i + 1
            # TODO: read in the data and verify that it's a sha + newline
            fname = fname.tr("\\","") #remove backslash
            sha = File.read(fname).strip
            if sha.length == 40 && sha =~ /^[0-9a-f]+$/
              references[:unpulled] << [fname, sha]
            end
          else
            references[:pulled] << fname
          end
        else
          # File was deleted
          references[:deleted] << fname
        end
      end
      references
    end

    def self.get_push_status
      # Find files in media buffer and check if they are uploaded already
      references = {:unpushed => [], :pushed => []}
      all_cache = Dir.chdir(GitMedia.get_media_buffer) { Dir.glob('*') }
      unpushed_files = @push.get_unpushed(all_cache) || []
      references[:unpushed] = unpushed_files
      references[:pushed] = all_cache - unpushed_files rescue []
      references
    end

    def self.print_pull_status(refs, long=false, relative_path=false)
      if refs[:unpulled].size > 0
        hint = ", run 'git media pull"
        relative_path ? hint << " --dir'" : hint << "'"
        hint << " to download them"
      else
        hint = ""
      end
      puts "== Unpulled Media: " + refs[:unpulled].size.to_s + " file(s)" + hint
      if long
        refs[:unpulled].each do |file, sha|
          # TODO: get local file name
          puts "   " + sha[0, 8] + " " + file
        end
        puts
      end
      puts "== Pulled Media:   " + refs[:pulled].size.to_s + " file(s)"
      if long
        refs[:pulled].each do |file|
          size = File.size(file)
          puts "   " + "(#{self.to_human(size)})".ljust(8) + " #{file}"
        end
        puts
      end
      if refs[:deleted].size > 0
        puts "== Deleted Media:  " + refs[:deleted].size.to_s + " file(s)"
        if long
          refs[:deleted].each do |file|
            puts "           " + " #{file}"
          end
          puts
        end
      end
    end

    def self.print_push_status(refs, long=false)
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
      if refs[:pushed].size > 0
        hint = ", run 'git media clear' to remove them from temp dir"
      else
        hint = ""
      end
      puts "== Pushed Media:   " + refs[:pushed].size.to_s + " file(s)" + hint
      if long
        refs[:pushed].each do |sha|
          cache_file = GitMedia.media_path(sha)
          size = File.size(cache_file)
          puts "   " + "(#{self.to_human(size)})".ljust(8) + ' ' + sha[0, 8]
        end
        puts
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
