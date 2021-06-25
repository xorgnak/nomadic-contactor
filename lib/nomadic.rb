
##       ###                                                ##
#         #  The Ultra-light-weight web framework, desktop,  #
# NOMADIC #  development envirement for IoT, radio, small    #
#         #  business in the future.             -(c) 2021   #
##       ###                                                ##

##
# LOAD LIBRARIES
{
  'redis-objects' => "advanced key/value store.",
  'paho-mqtt' => "lightweight pub/sub protocol.",
  'sinatra/base' => "streamlined web framework.",
  'pry' => "interactive, dynamic, and colorful ruby shell.",
  'device_detector' => "web request device fingerprinteing.",
  'twilio-ruby' => "sip gateway.",
  'cinch' => 'A generic irc bot framework.'
}.each_pair { |k,v| puts "loading #{k}: #{v}"; require k }

if ENV['DB'] == 'wipe'
  Redis.new.flushdb
end
s, p = [], []
[(:a..:z), (:A..:Z), (0..9)].each {|e| e.each {|ee| p << ee } }
32.times { s << p.sample }

Redis::List.new('SEED') << s.join('')

##
# CREATE NOMADC LIBRARY
module NOMADIC
end
##
# CREATE NOMADIC OBJECT
class Nomadic
  include NOMADIC
  def initialize
  end
end
##
# LOAD NOMADIC LIBRARIES
Dir["#{Dir.pwd}/lib/nomadic/*"].each { |e| puts "adding: #{e}"; load e }
@here = Nomadic.new
@here.app
