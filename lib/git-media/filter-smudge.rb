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
          if info_output
            output.puts('Media missing, saving placeholder : ' + sha)
          end
          # Print orig and not sha to preserve eventual newlines at end of file
          # To avoid git thinking the file has changed
          puts orig
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
