#require 'pp'
#Encoding.default_external = Encoding::UTF_8

module GitMedia
  module Sha

    def self.run!(opts)
    end

    def self.sha_to_file
    end

    def self.file_to_sha
    end

    def self.sha_file_map
      files = `git ls-tree -l -r HEAD --full-tree | tr "\\000" \\\\n`.split("\n")
      files = files.map { |f| s = f.split("\t"); [s[0].split(' ').last, s[1]] }
    end

  end
end
