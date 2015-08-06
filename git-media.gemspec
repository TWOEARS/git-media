Gem::Specification.new do |s|
  s.name = "git-media"
  s.version = "0.1.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Scott Chacon", "Alexander Lebedev", "Hagen Wierstorf"]
  s.date = "2015-07-29"
  s.email = "hagen.wierstorf@tu-berlin.de"
  s.executables = ["git-media"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md",
    "TODO"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.md",
    "Rakefile",
    "TODO",
    "VERSION",
    "bin/git-media",
    "git-media.gemspec",
    "lib/git-media.rb",
    "lib/git-media/check.rb",
    "lib/git-media/clear.rb",
    "lib/git-media/filter-clean.rb",
    "lib/git-media/filter-smudge.rb",
    "lib/git-media/filter-branch.rb",
    "lib/git-media/pull.rb",
    "lib/git-media/push.rb",
    "lib/git-media/status.rb",
    "lib/git-media/sync.rb",
    "lib/git-media/transport.rb",
    "lib/git-media/transport/atmos_client.rb",
    "lib/git-media/transport/local.rb",
    "lib/git-media/transport/s3.rb",
    "lib/git-media/transport/scp.rb",
    "lib/git-media/transport/webdav.rb",
    "spec/media_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/TWOEARS/git-media"
  s.require_paths = ["lib"]
  s.summary = "Adds large files support to git"
  s.description = %q{"Adds large files support to git using clean/smudge filters"}
  s.licenses = ["MIT"]


  s.add_development_dependency "bundler", "~> 1.7"
  s.add_development_dependency "rake", "~> 10.0"

end

