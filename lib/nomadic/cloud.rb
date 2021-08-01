module NOMADIC
  
  ##
  # basic group abstraction
  class Zone
    include Redis::Objects
    # the person who can fire people
    value :boss
    # members of the general public
    set :users
    # group administrators
    set :admins
    # group members
    set :members
    # group special offers
    hash_key :code
    def initialize i
      @id = i 
    end
    def id; @id; end
    def special h={}
      p, c = [], []
      (:A..:Z).each { |e| p << e }
      (0..9).each { |e| p << e }
      6.times { c << p.sample }
      Redis::HashKey.new('codes')[c.join('')] = @id
      self.code[c.join('')] = JSON.generate(h)
      return c.join('')
    end
  end
  
  ##
  # basic user abstraction
  class User
    include Redis::Objects
    # nick, pic, info, etc.
    hash_key :attr
    # xp, likes, lvl, boost, gp, likes, etc.
    sorted_set :stat
    # service: amt
    sorted_set :fare
    # amt: quantity
    sorted_set :rate
    # places and groups user has connection to.
    set :zones
    # jobs assigned to user.
    set :sponsors
    set :jobs
    def initialize i
      @id = i
    end
    def turn h={}
      h.each_pair { |k,v| self.stat.incr(k,v) }
    end
    def id; @id; end
    def voicemailbox
      Redis::HashKey.new('voicemailbox')[@id]
    end
    def special c
      z = NOMADIC.cloud.code[c]
      ticket(JSON.parse(NOMADIC.cloud.zone(z).code[c]))
    end
    def ticket h={}
      NOMADIC.ticket(@id).activate(h)
    end
    def tickets
      h = {}
      Redis.new.keys("ticket:#{@id}:*").each { |e| h[e.gsub("ticket:#{@id}:", '')] = Redis.new.get(e) }
      return h
    end
    def logo
      NOMADIC.logo self.attr['uid'], lvl: self.attr['rank'], method: 'm', object: 'u' 
    end
  end
  
  ##
  # cloud object
  ##
  # Handles general user and group interactions.
  #
  # @cloud <---- base cloub object.
  # 
  class Cloud
    include Redis::Objects
    
    # all active message ids for groups
    set :msgs
    
    set :zones
    # member: primary group
    hash_key :at
    # id: user
    hash_key :jid
    
    hash_key :job
    # id: member
    hash_key :assigned
    
    
    # everyone
    set :users
    
    def initialize
      
    end
    def id
      ENV['domain'] || "sandbox"
    end
    ##
    # cloud lookup by usr, zone, or job.
    def [] k
      v = []
      if k == '#'
        v << %[zones: #{self.zones.members.to_a}\n]
        v << %[admins:\n]
        self.at.all.each_pair { |kk,vv| v << %[#{kk}: #{vv}\n] }
        v << %[jobs:\n]
        self.jid.all.each_pair { |kk,vv| v << %[#{kk}: #{vv}\n] }
        v << %[assignments:\n]
        self.assigned.all.each_pair { |kk,vv| v << %[#{kk}: #{vv}\n] }
      elsif self.at.has_key?(k)
        #user info
        v << %[user: #{k}\n]
        v << User.new(k).zones.members.join(', ') 
        v << %[\n]
        
        User.new(k).stat.members(with_scores: true).to_h.each_pair do |k,v|
          v << %[#{k}: #{v}]
        end
        User.new(k).attr.all.each_pair { |kk,vv|
          v << %[#{kk}: #{vv}\n]
        }
      elsif self.zones.members.include?(k)
        # zone info
        v << %[zone: #{k}\n]
        Zone.new(k).admins.members.each { |e|
          u = User.new(e);
          v << %[[#{e}]\n];
          u.attr.all.each_pair { |kk,vv|
            v << %[#{kk}: #{vv}\n]
          };
          v << %[\n]
        }
      elsif self.jid.has_key?(k)
        # job info
        v << %[job: #{k}\n]
        v << %[user: #{self.jid[k]}\n]
        User.new(self.jid[k]).attr.all.each_pair {|kk,vv|
          if kk == 'since' || kk == 'last'
            c = Clock.new
            t = c.epoch - vv.to_i
            m = t / 60
            h = m / 60
            d = h / 24
            v << %[#{kk}: #{d}d#{h}h#{m}m ago.\n]
          else
            v << %[#{kk}: #{vv}\n]
          end
        }
      end
      return v.join('')
    end
    def assign(i, u)
      if !self.assigned.has_key? i
        self.assigned[i] = u
        user(u).jobs << i
      end
    end
    def finish(i, u)
      self.assigned.delete(i)
      user(u).jobs.delete(i)
    end
    def boss? u
      u == ENV['PHONE_ADMIN']
    end
    def admin? u
      self.at.has_key? u
    end
    def hire! z, u
      if !user(u).attr.has_key? 'uid'
        b = []; 4.times { b << rand(9) }
        Redis::HashKey.new('voicemailbox')[u] = b.join('')
        Redis::HashKey.new('voicemail')[b.join('')] = u
        user(u).attr['voicemailbox'] = b.join('')

        b = []; 5.times { b << rand(16).to_s(16) }
        Redis::HashKey.new('uids')[u] = b.join('')
        Redis::HashKey.new('uid')[b.join('')] = u
        user(u).attr['uid'] = b.join('')
        
        user(u).attr['lvl'] = 0
      end
      self.at[u] = z
      if !self.zones.include? z
        zone(z).boss = u
        zone(z).admins << u
      end
      user(u).zones << z
      user(u).attr['zone'] = z
      zone(z).members << u
    end
    def fire! u
      z = self.at[u]
      self.at.delete(u)
      user(u).attr.delete('zone')
      user(u).zones.delete(z)
      zone(z).admins.delete(u)
      zone(z).members.delete(u)
    end
    def zone z
      self.zones << z
      Zone.new(z)
    end
    def user u
      self.users << u
      User.new u
    end
    def code
      Redis::HashKey.new('codes')
    end
  end  
end
