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

# Just for Rails
if ENV['RAILS_ENV']
  IRB.conf[:IRB_RC] = Proc.new do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.instance_eval { alias :[] :find }
  end


  def sql(query)
    ActiveRecord::Base.connection.select_all(query)
  end 
end
