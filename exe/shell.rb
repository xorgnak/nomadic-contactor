##       ###                     ##
#         #                       #
# nomadic # generic nomadic shell # 
#         #                       #
##       ###                     ##

##
# load nomadic library
begin
  require "#{Dir.pwd}/lib/nomadic.rb"
  
  #@
  # load init file
  require "#{Dir.pwd}/app.rb"
  
  ##
  # drop to the shell.
  Pry.start
  
rescue => e
  Redis.new.publish 'BUG', "#{e}"
  puts "#{e.full_message}"
end
