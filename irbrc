require 'irb/completion'

IRB.conf[:PROMPT_MODE] = :SIMPLE

# History with readline
HISTFILE = "~/.irb.hist"
MAXHISTSIZE = 100

# Wirble (gem install wirble)
begin
  require 'wirble'
  Wirble.init
  Wirble.colorize
rescue LoadError
end

# Just for Rails
if ENV['RAILS_ENV']

  IRB.conf[:IRB_RC] = Proc.new do
    Rails.logger.flush
    Rails.logger.instance_variable_set("@log", STDOUT)
    Rails.logger.auto_flushing = 1
  end

end
