# upload files in media buffer that are not in offsite bin
require 'git-media/status'

module GitMedia
  module Push

    def self.run!(opts)
      @server = GitMedia.get_transport
      self.push_media(opts[:clean])
    end

    def self.push_media(clean=false, server=@server)
      # Find files in media buffer and upload them
      refs = GitMedia::Status.get_push_status(server)
      refs[:unpushed].each_with_index do |file, index|
        puts "Uploading " + (index+1).to_s + " of " + refs[:unpushed].length.to_s + ": " + file[:name] + " => " + file[:sha][0, 8]
        server.push(file[:sha])
        if server.exist?(file[:sha]) && clean
          File.unlink(File.join(file[:path], file[:sha]))
        end
      end
    end

  end
end
