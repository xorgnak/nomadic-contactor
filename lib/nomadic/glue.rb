module NOMADIC
  def cloud
    Cloud.new
  end
  def self.cloud
    Cloud.new
  end
  def self.ticket k
    Ticket.new(k)
  end
  def ticket k
    Ticket.new k
  end
  def self.track
    Track
  end
  def track
    Track
  end
  def bank
    Bank
  end
  def self.bank
    Bank
  end
  def game
    Game
  end
  def self.game
    Game
  end
  def clock
    Clock.new
  end
  def self.clock
    Clock.new
  end
  def seed
    SEED.new
  end
  def self.seed
    SEED.new
  end
  def venmo h={}
    Venmo.new(h)
  end
  def self.venmo h={}
    Venmo.new(h)
  end
  def badge u
    Badge.new(u)
  end
  def self.badge u
    Badge.new(u)
  end
  def logo i, h={}
    Logo.new(i, h)
  end
  def self.logo i, h={}
    Logo.new(i, h)
  end
end
