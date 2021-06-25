module NOMADIC

  class Deck
    class Card
      def initialize h={}
        @h = h
      end
      def [] k
        @h[k]
      end
      def to_h
        @h
      end
      def to_s

      end
    end
    def initialize h={}
      @deck, @burn = [], []
      @card = {}
      if h[:suits]
      h[:suits].each do |suit|
        h[:face].each_with_index { |e, i| mk(suit, e, i) }
        h[:numb].each_with_index { |e, i| mk(suit, e, i) }
      end
      end
      if h[:specials]
        h[:specials].each_with_index { |e, i| mk(e, i, i) }
      end
      @deck.shuffle
    end
    def deck
      @deck
    end
    def burn
      @burn
    end
    def card
      @card
    end
    def mk *a
      n = "#{a[1]}#{a[0]}"
      h = { suit: a[0], face: a[1], index: a[2], rand: rand(9), flip: rand(1) }
      @card[n] = Card.new(h)
      @deck << n
    end
    def shuffle
      @deck.shuffle
    end
    def deal
      c = @deck.shift
      @burn << c
      return @card[c]
    end
    def hand n
      r = []; n.times { r << deal }
      return r
    end
  end

  def deck h={}
    Deck.new h
  end
  def self.deck h={}
    Deck.new h
  end
  
  class Dice
    class Roll
      def initialize h={}
        @h = h
      end
      def [] k
        @h[k]
      end
      def to_h
        @h
      end
    end
    
    def initialize h={}
      @h = h
      @hist = []
    end
    def hist
      @hist
    end
    def roll
      if @h[:with]
        if @h[:with] > 0
          r = "#{@h[:num].to_i}d#{@h[:sides].to_i}+#{@h[:with].to_i}"
        else
          r = "#{@h[:num].to_i}d#{@h[:sides].to_i}#{@h[:with].to_i}"
        end
      else
        r = "#{@h[:num].to_i}d#{@h[:sides].to_i}"
      end
      rr = []
      raw, tot = 0, 0
      @h[:num].times {
        rx = rand(@h[:sides])
        tt = rx + @h[:with] || 0
        if tt >= @h[:success].to_i
          s = true
        else
          s = false
        end
        raw += rx
        tot += tt
        rr << Roll.new( roll: r, result: rx, total: tt, with: @h[:with] || 0, goal: @h[:success].to_i, success: s )
      }
      if raw >= @h[:success].to_i
        ww = true
      else
        ww = false
      end
      if tot >= @h[:success].to_i
        ss = true
      else
        ss = false
      end
      @hist << { raw: raw, total: tot, average: tot / @h[:num], goal: @h[:success].to_i, roll: rr, natural: ww, success: ss }
      return @hist[-1]
    end
  end


  ##
  # NOMADIC GAME INTERFACE
  # 1. apply h as turn
  # 2. roll for success
  # 3. apply result
  module Game

    def self.dice h={}
      Dice.new(h)
    end

    def self.deck h={}
      Deck.new h
    end
    
    def self.play u, h={}
    s = h.delete(:success)
    p = h.delete(:prize)
    u = User.new(u)
    u.turn h
    r = Game.dice( num: (u.zones.length + 1).to_i, sides: (u.stat[:lvl] + 2).to_i, with: u.stat[:likes].to_i, success: s).roll
    u.stat.incr('xp', r[:raw])
    if r[:success] == true
      u.stat.incr('gp', p)
    end
    return r
  end

  def self.vs defender, *attackers
    d = User.new(defender)
    r = []
    attackers.each do |attacker|
      a = User.new(attacker)
      rx = Game.dice( num: (a.zones.length + 1).to_i, sides: (a.stat[:lvl] + 2).to_i, with: a.stat[:likes].to_i, success: d.stat['xp'].to_i).roll
      puts "#{rx}"
      a.stat.incr('xp', rx[:raw].to_i)
      d.stat.incr('xp', rx[:raw].to_i)
      r << rx
    end
    return r
  end
  end
end
