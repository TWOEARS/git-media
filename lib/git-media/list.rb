# List files under their current status
require 'git-media/status'

module GitMedia
  module List

    def self.run!(opts)
      @server = GitMedia.get_transport
      self.list_files(opts[:dir])
    end

    def self.list_files(relative_path=false, server=@server)
      refs = GitMedia::Status.get_pull_status(relative_path, server)
      if refs[:unpulled].size > 0
        puts "== Unpulled files: "
        self.display_files(refs[:unpulled])
      end
      if refs[:not_on_server].size > 0
        puts "== Files missing on server: "
        self.display_files(refs[:not_on_server])
      end
      if refs[:pulled].size > 0
        puts "== Pulled files: "
        self.display_files(refs[:pulled])
      end
      if refs[:deleted].size > 0
        puts "== Deleted files: "
        self.display_files(refs[:deleted], true)
      end
      refs = GitMedia::Status.get_push_status(server)
      if refs[:unpushed].size > 0
        puts "== Unpushed files: "
        self.display_files(refs[:unpushed])
      end
      if refs[:cached].size > 0
        puts "== Cached files: "
        self.display_files(refs[:cached])
      end
    end

    def self.display_files(files, show_only_name=false)
      files.each do |file|
        if show_only_name
          puts "   " + "()".ljust(8) + " " + " "*8 + "   " + file[:name]
        else
          puts "   " + "(#{self.to_human(file[:size])})".ljust(8) + " " + file[:sha][0, 8] + "   " + file[:name]
        end
      end
      puts
    end

    def self.to_human(size)
      size = size.to_i
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
