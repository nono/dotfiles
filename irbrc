require 'irb/completion'
require 'irb/ext/save-history'

# History with readline
HISTFILE = "~/.irb.hist"
MAXHISTSIZE = 200

# Wirble (gem install wirble)
begin
  require 'wirble'
  Wirble.init
  Wirble.colorize
rescue LoadError
end

# http://gist.github.com/124272
def copy(str)
  IO.popen('xclip -i', 'w') { |f| f << str.to_s }
end

def paste
  `xclip -o`
end

# http://ozmm.org/posts/time_in_irb.html
def time(times = 1)
  require 'benchmark'
  ret = nil
  Benchmark.bm { |x| x.report { times.times { ret = yield } } }
  ret
end

# http://github.com/rtomayko/dotfiles/blob/rtomayko/.irbrc
# list object methods
def local_methods(obj=self)
  (obj.methods - obj.class.superclass.instance_methods).sort
end

def ls(obj=self)
  width = `stty size 2>/dev/null`.split(/\s+/, 2).last.to_i
  width = 80 if width == 0
  local_methods(obj).each_slice(3) do |meths|
    pattern = "%-#{width / 3}s" * meths.length
    puts pattern % meths
  end
end

# Just for Rails3
if defined?(ActiveSupport::Notifications)

  $odd_or_even_queries = false
  ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
    $odd_or_even_queries = !$odd_or_even_queries
    color = $odd_or_even_queries ? "\e[36m" : "\e[35m"
    event = ActiveSupport::Notifications::Event.new(*args)
    time = "%.1fms" % event.duration
    name = event.payload[:name]
    sql = event.payload[:sql].gsub("\n", " ").squeeze(" ")
    puts " \e[1m#{color}#{name} (#{time})\e[0m #{sql}"
  end

# And for Rails2
elsif ENV.include?('RAILS_ENV') && !Object.const_defined?('RAILS_DEFAULT_LOGGER')

  require 'logger'
  RAILS_DEFAULT_LOGGER = Logger.new(STDOUT)
end
