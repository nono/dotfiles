#!/usr/bin/ruby

# TODO comments
# TODO cursor
# TODO Exception.h
# TODO main.cpp

$skeleton_rep = File::expand_path("~/.vim/skeleton");
$date = Time::now.strftime("%d/%m/%y");
$time = Time::now.strftime("%H:%M:%S");
$dir  = File::basename(Dir::pwd);

ARGV.each do |filename|
	# TODO répertoires
	if filename =~ /^(\w+)\.(\w+)$/ then
		name, ext = $1, $2;
		skeleton_file = $skeleton_rep + "/" + ext;
		if File::exist?(skeleton_file) then
			File::open(skeleton_file).each do |line|
				line.gsub!(/@file/, name);
				line.gsub!(/@File/, name.capitalize);
				line.gsub!(/@FILE/, name.upcase);
				line.gsub!(/@dir/,  $dir);
				line.gsub!(/@Dir/,  $dir.capitalize);
				line.gsub!(/@DIR/,  $dir.upcase);
				line.gsub!(/@date/, $date);
				line.gsub!(/@time/, $time);
				print line;
			end
		end
	end
end
