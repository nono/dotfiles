#!/usr/bin/env ruby
# Author: Bruno Michel <bmichel@menfin.info>
# Licence: MIT <http://www.opensource.org/licenses/mit-license.html>

require 'erb'


SKELETON_DIR = File.expand_path("~/.vim/skeleton");
EXTENSION  = "erb"
EXCEPTIONS = {
	/vim\/ftdetect\/.*\.vim/ => "vim_ftdetect",
}

file, filetype = ARGV
filename  = File.basename(file)
skeletons = [filename, filetype]
EXCEPTIONS.each { |r,s| skeletons << s if file =~ r }
skeleton  = skeletons.map { |s|
	File.join(SKELETON_DIR, "#{s}.#{EXTENSION}")
}.find { |s|
	File.exist?(s) && File.readable?(s)
}

exit if skeleton.nil?

File.open(skeleton) do |f|
	puts ERB.new(f.read, nil, '<>').result(binding)
end

