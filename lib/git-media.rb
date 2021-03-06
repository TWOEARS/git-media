require 'rubygems'
require 'bundler/setup'
require 'trollop'
require 'fileutils'

module GitMedia

  def self.get_media_buffer
    @@git_dir ||= `git rev-parse --git-dir`.chomp
    media_buffer = File.join(@@git_dir, 'media/objects')
    FileUtils.mkdir_p(media_buffer) if !File.exist?(media_buffer)
    return media_buffer
  end

  def self.media_path(sha)
    buf = self.get_media_buffer
    sha = self.sha_to_path(sha)
    File.join(buf, sha)
  end

  def self.sha_to_path(sha)
    sha[0,2] + '/' + sha[2,38]
  end

  def self.path_to_sha(path)
    path.delete('/')
  end

  def self.get_cache_files(media_files=nil)
    # List files stored in media cache as { :size, :path, :name, :sha }
    if media_files.nil?
      cache_files = self.get_media_files
    else
      cache_files = Marshal.load(Marshal.dump(media_files)) # clone nested Hash
    end
    cache_path = self.get_media_buffer
    cache_sha = Dir.chdir(cache_path) { Dir.glob('*/*') }
    cache_sha.map! { |f| self.path_to_sha(f) }
    cache_files = cache_files.select { |f| cache_sha.include?(f[:sha]) }
    cache_files.each { |f| f[:path] = cache_path }
  end

  def self.get_media_files(relative_path=false)
    # List git-media handled files as { :size, :path, :name, :sha }
    files = self.get_files_with_size_path_name(relative_path)
    files.each do |entry|
      sha = self.get_sha_from_file(entry)
      entry.store(:sha, sha)
    end
    files
  end

  def self.get_files_with_size_path_name(relative_path=false)
    # List git-media handled files as { :size, :path, :name }
    if relative_path
      files = `git ls-tree -l -r HEAD | tr "\\000" \\\\n`.split("\n")
      repo_path = "."
    else
      files = `git ls-tree -l -r HEAD --full-tree | tr "\\000" \\\\n`.split("\n")
      repo_path = `git rev-parse --show-toplevel`.chomp
    end
    files = files.map do |file|
      s = file.split("\t")
      { size: s[0].split(' ').last, path: repo_path, name: s[1] }
    end
    # Find git-media handled files by its size
    # TODO: this seems a little bit risky, what if a file has mistakenly the
    # same size
    files = files.select { |f| f[:size] == '41' }
    # Update size by actual file size
    files = files.each do |file|
      fname = File.join(file[:path], file[:name])
      file[:size] = File.exists?(fname) ? File.size(fname).to_i : 0
    end
  end

  def self.get_sha_from_file(file_list_entry)
    require 'digest/sha1'
    file = File.join(file_list_entry[:path], file_list_entry[:name])
    begin
      # Read sha from file
      # Windows newlines can offset file size by 1
      if file_list_entry[:size] == 41 or file_list_entry[:size] == 42
        # TODO: read in the data and verify that it's a sha + newline
        file = file.tr("\\","") #remove backslash
        sha = File.read(file).strip
        if sha.length == 40 && sha =~ /^[0-9a-f]+$/
          return sha
        else
          return ""
        end
      else
        # Calculate sha from file
        sha = Digest::SHA1.file(file)
        sha.hexdigest
      end
    rescue
      ""
    end
  end


  def self.get_credentials_from_netrc(url)
    require 'uri'
    require 'netrc'

    uri = URI(url)
    hostname = uri.host
    unless hostname
      raise "Cannot identify hostname within git-media.webdavurl value"
    end
    netrc = Netrc.read
    netrc[hostname]
  end

  def self.get_transport
    # Get transport settings from .git/config
    transport = `git config git-media.transport`.chomp
    case transport
    when ""
      raise "git-media.transport not set"

    when "scp"
      require 'git-media/transport/scp'

      user = `git config git-media.scpuser`.chomp
      host = `git config git-media.scphost`.chomp
      path = `git config git-media.scppath`.chomp
      port = `git config git-media.scpport`.chomp
      if user === ""
        raise "git-media.scpuser not set for scp transport"
      end
      if host === ""
        raise "git-media.scphost not set for scp transport"
      end
      if path === ""
        raise "git-media.scppath not set for scp transport"
      end
      puts "Collecting information on ssh remote " + host + path
      GitMedia::Transport::Scp.new(user, host, path, port)

    when "local"
      require 'git-media/transport/local'

      path = `git config git-media.localpath`.chomp
      if path === ""
        raise "git-media.localpath not set for local transport"
      end
      GitMedia::Transport::Local.new(path)

    else
      raise "Invalid transport #{transport}"
    end
  end

  module Application
    def self.run!

      #RubyProf.start

      if !system('git rev-parse')
        return
      end

      cmd = ARGV.shift # get the subcommand
      case cmd
      when "filter-clean" # parse delete options
        require 'git-media/filter-clean'
        GitMedia::FilterClean.run!
      when "filter-smudge"
        require 'git-media/filter-smudge'
        GitMedia::FilterSmudge.run!
      when "clear" # parse delete options
        require 'git-media/clear'
        GitMedia::Clear.run!
      when "pull"
        require 'git-media/pull'
        opts = Trollop::options do
          opt :dir, "Pull only files for the current dir and subdirs"
          opt :clear, "Remove local cache files after uploading"
        end
        GitMedia::Pull.run!(opts)
      when "push"
        require 'git-media/push'
        opts = Trollop::options do
          opt :clear, "Remove local cache files after uploading"
        end
        GitMedia::Push.run!(opts)
      when "sync"
        require 'git-media/sync'
        opts = Trollop::options do
          opt :dir, "Pull only files for the current dir and subdirs"
          opt :clear, "Remove local cache files after uploading"
        end
        GitMedia::Sync.run!(opts)
      when 'status'
        require 'git-media/status'
        opts = Trollop::options do
          opt :dir, "Look only under the current dir for unpulled files"
        end
        GitMedia::Status.run!(opts)
      when 'list'
        require 'git-media/list'
        opts = Trollop::options do
          opt :dir,           "Look only under the current dir for unpulled files"
          opt :pulled,        "List only pulled files"
          opt :unpulled,      "List only unpulled files"
          opt :cached,        "List only cached files"
          opt :unpushed,      "List only unpushed files"
          opt :deleted,       "List only deleted files"
          opt :not_on_server, "List files missing on server"
        end
        GitMedia::List.run!(opts)
      when 'check'
        require 'git-media/check'
        GitMedia::Check.run!
      #when 'retroactively-apply'
      #  require 'git-media/filter-branch'
      #  GitMedia::FilterBranch.clean!
      #  arg2 = "--index-filter 'git media index-filter #{ARGV.shift}'"
      #  system("git filter-branch #{arg2} --tag-name-filter cat -- --all")
      #  GitMedia::FilterBranch.clean!
      #when 'index-filter'
      #  require 'git-media/filter-branch'
      #  GitMedia::FilterBranch.run!
      else
    print <<EOF
usage: git media sync|pull|push|status|list|clear

  sync                 Sync files with remote server (runs pull and push)
                       --dir:  Pull only files under current dir
                       --clear:  Remove local cache files after uploading

  pull                 Download files from remote server
                       --dir:  Pull only files under current dir
                       --clear:  Remove local cache files after uploading

  push                 Upload files to remote server
                       --clear:  Remove local cache files after uploading

  status               Show number of (un)pulled, (un)pushed files
                       --dir:   Look only for pulled files under current dir

  list                 List media files
                       --dir:            Look only for pulled files under current dir
                       --pulled:         List only pulled files
                       --unpulled:       List only unpulled files
                       --cached:         List only cached files
                       --unpushed:       List only unpushed files
                       --deleted:        List only deleted files
                       --not_on_server:  List files missing on server

  clear                Upload and delete the local cache of media files

  check                Check local media cache and re-download any corrupt files

EOF
      end
      #result = RubyProf.stop
      #printer = RubyProf::FlatPrinter.new(result)
      #printer.print(STDOUT)
    end
  end
end
