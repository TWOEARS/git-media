# git-media

GitMedia extension allows you to use Git with large media files
without storing the media in Git itself.

## Prerequisities

### Linux/Mac

* Ruby (>= v2.0) as part of package ruby2.0-dev

### Windows

* [Ruby](http://rubyinstaller.org/) (>= v2.0)
* Git Bash as part of [Git for Windows](https://git-for-windows.github.io/)

## Installing

The installation is performed via command line (e.g. bash under Linux and git
bash under Windwos):

    $ git clone git@github.com:TWOEARS/git-media.git
    $ cd git-media
    $ sudo gem install bundler
    $ bundle install
    $ gem build git-media.gemspec

To finally install it the next command under Windows will be

    $ gem install git-media-*.gem

and under Linux most probably

    $ sudo gem install git-media-*.gem

In order to use bundle you will need most probably the ruby-dev package
installed on your system.

If you have file permissions problems running `bundle install`, you could
try instead:

    $ bundle install --path ~/.gem

## Configuration

Setup the attributes filter settings.

	(once after install)
	$ git config filter.media.clean "git-media filter-clean"
	$ git config filter.media.smudge "git-media filter-smudge"

Setup the `.gitattributes` file to map extensions to the filter.

	(in repo - once)
	$ echo "*.mov filter=media -crlf" > .gitattributes

Staging files with those extensions will automatically copy them to the
media buffer area (.git/media) until you run 'git media sync' wherein they
are uploaded.  Checkouts that reference media you don't have yet will try to
be automatically downloaded, otherwise they are downloaded when you sync.

Next you need to configure git to tell it where you want to store the large files.
There are five options:

1. Storing locally in a filesystem path
2. Storing remotely via SCP (should work with any SSH server)

Here are the relevant sections that should go either in `~/.gitconfig` (for global settings)
or in `clone/.git/config` (for per-repo settings).

```ini
[git-media]
	transport = <scp|local>

	# settings for scp transport
	scpuser = <user>
	scphost = <host>
	scppath = <path_on_remote_server>

	# settings for local transport
	localpath = <local_filesystem_path>
```


## Usage

For an overview of all commands, run

    $ git media help

You can check the status of your media files via

	$ git media status

Which will show you files that are waiting to be uploaded and how much data that
is. It will also provide some help on what you can do next.

If you want to pull all available media files, run

    $ git media pull

If you want to download only the media files in your current folder and its
subfolders, run

    $ git media pull --dir

If you have added and commited new data to your git repository, you can upload
them via

    $ git media push

If you want to delete the local cache of media files, run:

	$ git media clear

If you want to replace file in git-media with changed version (for example, video file has been edited),
you need to explicitly tell git that some media files has changed:

    $ git update-index --really-refresh

## Notes for Windows

It is important to switch off git smart newline character support for media files.
Use `-crlf` switch in `.gitattributes` (for example `*.mov filter=media -crlf`) or config option `core.autocrlf = false`.

If installing on windows, you might run into a problem verifying certificates
for S3 or something. If that happens, modify

	C:\Ruby191\lib\ruby\gems\1.9.1\gems\right_http_connection-1.2.4\lib\right_http_connection.rb

And add at line 310, right before `@http.start`:

      @http.verify_mode     = OpenSSL::SSL::VERIFY_NONE

## Copyright

Copyright (c) 2009 Scott Chacon. See LICENSE for details.
