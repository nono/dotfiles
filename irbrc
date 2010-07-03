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

# Just for Rails
if ENV['RAILS_ENV']

  IRB.conf[:IRB_RC] = Proc.new do
    Rails.logger.flush
    Rails.logger.instance_variable_set("@log", STDOUT)
    Rails.logger.auto_flushing = 1
  end

end
