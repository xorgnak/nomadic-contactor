module NOMADIC
  
  class GRP
    include Redis::Objects
    hash_key :attr
    sorted_set :stat
    
    sorted_set :role
    sorted_set :fare
    
    set :grp
    set :lead
   
    set :admin
    
    set :zones
    set :depts
    set :teams
    
    def initialize i
      @id = i
      update!
    end
    def id; @id; end
    def update!
      if self.attr.has_key?('team')
        self.teams << self.attr['team']
        x = Team.new(self.attr['team'])
        x.depts << self.attr['dept'] if self.attr.has_key?('dept')
        x.zones << self.attr['zone'] if self.attr.has_key?('zone')
      end
      if self.attr.has_key?('zone')
        self.zones << self.attr['zone']
        x = Zone.new(self.attr['zone'])
        x.depts << self.attr['dept'] if self.attr.has_key?('dept')
        x.teams << self.attr['team'] if self.attr.has_key?('team')
      end
      if self.attr.has_key?('dept')
        self.depts << self.attr['dept']
        x = Dept.new(self.attr['dept'])
        x.teams << self.attr['team'] if self.attr.has_key?('team')
        x.zones << self.attr['zone'] if self.attr.has_key?('zone')
      end
      
    end
    def info
      {
        attr: self.attr.all,
        role: self.role.members(with_scores: true).to_h,
        fare: self.fare.members(with_scores: true).to_h,
        stat: self.stat.members(with_scores: true).to_h,
        group: self.grp.members,
        lead: self.lead.members,
        web: {
          zones: self.zones.members,
          depts: self.depts.members,
          teams: self.teams.members
        }
      }
    end
  end

  class User < GRP
    def follow u
      User.new(u).lead << @id
      self.grp << u
    end
    def give a, s, u
      self.stat.decr(s, a)
      User.new(u).stat.incr(s, a)
    end
    def dept t
      Cloud.new.all << t
      Cloud.new.depts << t
      self.attr['dept'] = t
      self.depts << t
      x = Dept.new(t)
      x.grp << @id
      update!
      return x
    end
    def zone t
      Cloud.new.all << t
      Cloud.new.zones << t
      self.attr['zone'] = t
      self.zones << t
      x = Zone.new(t)
      x.grp << @id
      update!
      return x
    end
    def team t
      Cloud.new.all << t
      Cloud.new.teams << t
      self.attr['team'] = t
      self.teams << t
      x = Team.new(t)
      x.grp << @id
      update!
      return x
    end
  end
  
  class Team < GRP; end
  class Dept < GRP; end
  class Zone < GRP; end
  
  class Cloud
    include Redis::Objects
    set :teams
    set :zones
    set :depts
    set :users
    set :online
    set :all
    
    def initialize
      
    end
    def id
      ENV['domain'] || "sandbox"
    end
    def [] x
      r = false
      if self.all.include? x
        if self.zones.include? x
          r = Zone.new(x)
        elsif self.depts.include? x
          r = Dept.new(x)
        elsif self.teams.include? x
          r = Team.new(x)
        end     
      end
      return r
    end
    
    def user u
      self.users << u
      User.new u
    end
    
    def map &b
        b.call()
    end
  end
end
