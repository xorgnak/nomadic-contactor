module NOMADIC
  class Zone
    include Redis::Objects
    set :users
    set :admins
    def initialize i
      @id = i 
    end
    def id; @id; end
  end
  
  class User
    include Redis::Objects
    hash_key :attr
    set :zones
    set :jobs
    sorted_set :stat
    def initialize i
      @id = i
    end
    def id; @id; end
  end
  
  class Cloud
    include Redis::Objects
    
    set :msgs
    set :zones
    hash_key :at
    
    hash_key :jid
    hash_key :job
    
    hash_key :assigned
    
    set :users
    
    def initialize
      
    end
    def id
      ENV['domain'] || "sandbox"
    end
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
            t = Clock.epoch - vv.to_i
            m = t / 60
            h = m / 60
            d = h / 24
            v << %[#{kk}: #{d}d#{h}h#{m}m ago.]
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
    def admin? u
      self.at.has_key? u
    end
    def hire! z, u
      self.at[u] = z
      user(u).zones << z
      user(u).attr['zone'] = z
      zone(z).admins << u
    end
    def fire! u
      z = self.at[u]
      self.at.delete(u)
      user(u).attr.delete('zone')
      user(u).zones.delete(z)
      zone(z).admins.delete(u)
    end
    def zone z
      self.zones << z
      Zone.new(z)
    end
    def user u
      self.users << u
      User.new u
    end
  end
end
