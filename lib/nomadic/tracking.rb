require 'redis-objects'

module NOMADIC
  ##
  # tickets for auth, offers, specials
  class Ticket
    def initialize k
      @k = k
    end
    def activate h={}
      Redis.new.setex("ticket:#{@k}:#{h[:name] || h['name']}", h[:ttl] || h['ttl'], h[:value] || h['value'])
    end
    def active? n
      if Redis.new.get("ticket:#{@k}:#{n}")
        return Redis.new.get("ticket:#{@k}:#{n}")
      else
        return false
      end
    end
  end
  ##
  # TICKET TRACKING
  # set a value for an amount of time.
  # use txt for userid for auth
  # val can be rand or level
  #tkt = 'my special ticket'
  #ticket(tkt).activate 60, "my test ticket value"
  #ticket(tkt).active?
  
  
  ##
  # Trackable
  # can be a rider, influencer, or customer by phone number
  # or location id,
  class Track
    include Redis::Objects
    
    counter :level
    counter :experience
    counter :op
    
    sorted_set :with
    
    hash_key :attr
    sorted_set :stat
    
    sorted_set :lvl
    sorted_set :xp
    
    hash_key :log
    hash_key :join
    hash_key :seen
    
    def initialize i, *t
      now!
      @id = i
      a, n, x = 0, 0, 0
      if t.length > 0
        [t].flatten!.each do |e|
          if !self.join.has_key? e
            self.join[e] = @now
          end
          self.seen[e] = @now
          self.xp.incr(e)
          if self.xp[e] > 2 ** self.lvl[e]
            self.lvl.incr(e)
          end
          n += 1
          x += self.xp[e]
        end
        self.xp.members(with_scores: true).to_h.each_pair do |k,v|
          a += self.lvl[k]
          x += v
        end
        self.experience.value = x
        if a > 2 ** self.level.value
          self.level.increment
        end
        self.log[@now] = "#{@id} #{t} #{a} #{n} #{x}"
      end
    end
    def id; @id; end
    ##
    # universal timestamp
    def now!
      @now = Time.now.utc.to_f.to_s.gsub('.', '')
    end
    ##
    # add affinity
    def plus u
      [u].flatten!.each { |e| self.with.incr(e) }
    end
    
    def to_h
      {
        stats: {
          op: self.op.value,
          level: self.level.value,
          experience: self.experience.value
        },
        lvl: self.lvl.members(with_scores: true).to_h,
        xp: self.xp.members(with_scores: true).to_h,
      }
    end
    
    ##
    # affinity network
    def network
      h = {}
      self.with.members(with_scores: true).to_h.each_pair do |k,v|
        if k != @id
          t = Track.new(k)
          h[k] = { strength: v, level: t.level.value, experience: t.experience.value, op: t.op.value }
        end
      end
      return h
    end
    
    def self.[]= t, us
      if us.class == Array
        self.new(t, us).plus(us)
        [us].flatten.each { |e| self.new(e, t).plus(us) }
      elsif us.class == Hash
        self.new(t).attr.bulk_set(us)
      end
    end
    def self.[] k
      self.new(k)
    end
  end
end
##
# set rider,influencer, or customer attributes
#track[USR] = { name: 'Erik', job: 'pedicabber' }
# track location visits and affinity
#track[LOC.sample] = [ 'USR1', 'USR2' ...]

##
# testing setup
#USR = '+17205522104'

#SPONSORS = 5
#POOL = 4
#DAY_MIN = 3
#DAY_MAX = 10
#DAYS = 5

#@locs = ['bar', 'club', 'art']
#@loc = []
#SPONSORS.times { |t| @loc << @locs.sample + "-#{t}" }
#@pool = [USR]
#POOL.times { |t| @pool << "+1800555000#{t}" }

##
# set rider,influencer, or customer attributes
#track[USR] = { name: 'Erik', job: 'pedicabber' }
# track location visits and affinity
#track[LOC.sample] = [ 'USR1', 'USR2' ...]
##
# tracking reports.
# Track.new('[USR || LOC]').network
# Track.new('USR || LOC').to_h
##
# test tracking cycles.
#def test t
#  t.times do
#    a = []
#    rand(1..4).times { a << @pool.sample }
#    ##
#    # handle event.
#    track[@loc.sample] =  a 
#  end
#end
#@tot = 0
#@r = []
##
# generate test
#def day
#  rn = rand(DAY_MIN..DAY_MAX)
#  @r << rn
#  @tot += rn
#  test rn
#end
#def week
#  DAYS.times {
#    day
#  }
#  puts "WEEK: #{@tot} #{@r}"
#end
##
# user
#def peek
#  @x = track[USR]
#  puts "#{@x.to_h}"
#  @x.network.each_pair { |k,v| puts "#{k}: #{v}" }
#  return nil
#end
