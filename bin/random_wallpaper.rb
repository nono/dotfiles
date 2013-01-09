#!/usr/bin/env ruby
# Author: Bruno Michel <bmichel@menfin.info>
# Licence: MIT <http://www.opensource.org/licenses/mit-license.php>

DIRECTORY = "/home/nono/Documents/Wallpapers"
COMMAND   = "Esetroot -s %s"

srand
all = Dir[DIRECTORY + "/*"]
cmd = COMMAND % all.sample

system(cmd)
