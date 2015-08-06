module GitMedia
  module FilterSmudge

    def self.print_stream(stream)
      while data = stream.read(4096) do
        print data
      end
    end

    def self.run!(input=STDIN, output=STDERR, info_output=false)

      # read checksum size
      orig = input.readline(64)
      sha = orig.strip # read no more than 64 bytes
      if input.eof? && sha.length == 40 && sha.match(/^[0-9a-fA-F]+$/) != nil
        # this is a media file
        media_file = GitMedia.media_path(sha.chomp)
        if File.exists?(media_file)
          if info_output
            output.puts('Recovering media : ' + sha)
          end
          File.open(media_file, 'rb') do |f|
            print_stream(f)
          end
        else
          # Read key from config
          auto_download = `git config git-media.autodownload`.chomp.downcase == "true"

          if auto_download

            server = GitMedia.get_transport

            cache_file = GitMedia.media_path(sha)
            if !File.exist?(cache_file)
              if info_output
                output.puts ("Downloading : " + sha[0,8])
              end
              # Download the file from backend storage
              server.pull(sha)
            end

            if info.output
              output.puts ("Expanding : " + sha[0,8])
            end

            if File.exist?(cache_file)
              File.open(media_file, 'rb') do |f|
                print_stream(f)
              end
            else
              if info_output
                output.puts ("Could not get media, saving placeholder : " + sha)
              end
              puts orig
            end

          else
            if info_output
              output.puts('Media missing, saving placeholder : ' + sha)
            end
            # Print orig and not sha to preserve eventual newlines at end of file
            # To avoid git thinking the file has changed
            puts orig
          end
        end
      else
        # if it is not a 40 character long hash, just output
        if info_output
          output.puts('Unknown git-media file format')
        end
        print orig
        print_stream(input)
      end
    end

  end
end
