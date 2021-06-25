module NOMADIC
  class Clock
    def initialize
      @t = Time.now.utc
    end
    def epoch
      @t.to_f.to_s.gsub('.', '')[0..15]
    end
    def time
      @t
    end
  end
end
