require 'yaml'
require 'irb/completion'

IRB.conf[:PROMPT_MODE] = :SIMPLE

# History with readline
HISTFILE = "~/.irb.hist"
MAXHISTSIZE = 100

# Wirble (gem install wirble)
require 'wirble'
Wirble.init
Wirble.colorize

# Just for Rails
if ENV['RAILS_ENV']

  def define_model_find_shortcuts
    model_files = Dir["app/models/**/*.rb"]
    table_names = model_files.map {|f| File.basename(f).chomp('.rb') }
    table_names.each do |name|
      Object.send(:define_method, name) do |*args|
        name.camelize.constantize.send(:find, *args)
      end
    end
  end

  def sql(query)
    ActiveRecord::Base.connection.select_all(query)
  end 

  IRB.conf[:IRB_RC] = Proc.new do
    Rails.logger.flush
    Rails.logger.instance_variable_set("@log", STDOUT)
    Rails.logger.auto_flushing = 1
    ActiveRecord::Base.instance_eval { alias :[] :find }
    define_model_find_shortcuts
  end

end
