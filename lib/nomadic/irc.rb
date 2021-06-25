
class Irc
  def bot
    @bot
  end
  def initialize h={}
    if h[:admin]
      [ h[:admin] ].flatten.each { |e| Redis::Set.new('admins') << e }
    end
    @bot = Cinch::Bot.new do
      configure do |c|
        c.verbose = true
        c.server   = 'localhost'
        c.channels = []
        c.nick = h[:nick]
      end
      
      helpers do
        def is_admin?(user)
          true if Redis::Set.new('admins').members.include? user.nick
        end
      end
      
      on :privmsg do |m|
        
        ##
        # join
        if mm = /^join (.+)/.match(m.message)
          if is_admin?(m.user)
            bot.join(mm[1])
            Redis::Set.new('channels') << mm[1]
            if ENV['BOX'] == 'true'
              m.reply "joined #{mm[1]}"
            end
          end
        end
        ##
        # part
        if mm = /^part (.+)/.match(m.message)
          if is_admin?(m.user)
            bot.part(mm[1])
            Redis::Set.new('channels').delete(mm[1])
            if ENV['BOX'] == 'true'
              m.reply "left #{mm[1]}"
            end
          end
        end


        if mm = /^! (.*)/.match(m.message)
          if is_admin?(m.user) 
            Redis::List.new("pins:#{m.channel}") << "[#{Time.now.utc}] #{mm[1]}"
            if ENV['BOX'] == 'true'
              m.reply "pined #{mm[1]}"
            end
          end
        end

        if m.message == '!'
          Redis::List.new("pins:#{m.channel}").values.each { |e| User(m.user.nick).send e }
        end
        
        Redis.new.publish "IRC", "DM " + m.raw
      end
      
      
      ##
      # capture all events for later handling.
      on :catchall do |m|
        if Redis::Set.new('channels').members.include? '#catbox'
          if mm = /^:(.+)!(.+)@(.+) (.+) (.*)/.match(m.raw)
            host = mm[3]
            if m.action_message
              mx = "***"
              mg = m.action_message
            else
              mx = mm[4]
              mg = mm[5]
            end
            Channel('#catbox').send("USER " + host + " " + mm[1] + " " + mx + " " + mg )
          elsif mm = /:(.+) (.+) (.+) (.+) (.*)/.match(m.raw)
            Channel('#catbox').send("SERVER " + mm[1] + " " + mm[2] + " " + mm[3] + " " + mm[4] + " " + mm[5] )
          else
            Channel('#catbox').send("RAW " + m.raw)
          end
          Redis.new.publish 'IRC', "#{m.raw}"
        end
      end
    end
    Process.detach( fork { @bot.start } )
  end
end
#@irc = Irc.new nick: :cat, admin: :pi

