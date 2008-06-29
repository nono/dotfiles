require 'yaml'
require 'irb/completion'

IRB.conf[:USE_REALINE] = true
IRB.conf[:PROMPT_MODE] = :SIMPLE

# History with readline
HISTFILE = "~/.irb.hist"
MAXHISTSIZE = 100

# what? (gem install what_methods)
require 'what_methods'

# Wirble (gem install wirble)
require 'wirble'
Wirble.init
Wirble.colorize

# Just for Rails and Merb
if ENV['RAILS_ENV'] or defined? Merb
  IRB.conf[:IRB_RC] = Proc.new do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.instance_eval { alias :[] :find }
  end


  def sql(query)
    ActiveRecord::Base.connection.select_all(query)
  end 
end

# For benchmarks
def time(times = 1)
  require 'benchmark'
  ret = nil
  Benchmark.bm { |x| x.report { times.times { ret = yield } } }
  ret
end

