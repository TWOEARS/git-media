# List files under their current status
require 'git-media/status'

module GitMedia
  module List

    def self.run!(opts)
      @server = GitMedia.get_transport
      self.list_files(opts)
    end

    def self.list_files(opts, server=@server)
      refs = GitMedia::Status.get_status(opts[:dir], server)
      # Set all opts to true if no specific one was given
      if !opts.values_at(:unpulled, :not_on_server, :pulled, :deleted, :unpushed, :cached).any?
        opts.each { |key, value| opts[key] = true }
      end
      puts
      if opts[:unpulled] and refs[:unpulled].size > 0
        GitMedia::Status.display(refs[:unpulled], "Unpulled Media")
        self.display_files(refs[:unpulled])
      end
      if opts[:not_on_server] and refs[:not_on_server].size > 0
        GitMedia::Status.display(refs[:not_on_server], "Media missing on server")
        self.display_files(refs[:not_on_server])
      end
      if opts[:pulled] and refs[:pulled].size > 0
        GitMedia::Status.display(refs[:pulled], "Pulled Media")
        self.display_files(refs[:pulled])
      end
      if opts[:deleted] and refs[:deleted].size > 0
        GitMedia::Status.display(refs[:deleted], "Deleted Media")
        self.display_files(refs[:deleted], true)
      end
      if opts[:unpulled] and refs[:unpushed].size > 0
        GitMedia::Status.display(refs[:unpushed], "Unpulled Media")
        self.display_files(refs[:unpushed])
      end
      if opts[:cached] and refs[:cached].size > 0
        GitMedia::Status.display(refs[:cached], "Cached Media")
        self.display_files(refs[:cached])
      end
    end

    def self.display_files(files, show_only_name=false)
      files.each do |file|
        if show_only_name
          puts "   " + "()".ljust(8) + " " + " "*8 + "   " + file[:name]
        else
          puts "   " + "(#{GitMedia::Status.to_human(file[:size]).rjust(4)})   " + file[:sha][0, 8] + "   " + file[:name]
        end
      end
      puts
    end

  end
end
