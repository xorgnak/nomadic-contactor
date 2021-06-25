module NOMADIC
  
  class SEED
    def initialize
      @seeds = Redis::List.new("SEED")
    end	
    def current
      @seeds[-1]
    end
    def valid? s
      @seeds.include? s
    end
    def values
      @seeds.values
    end
  end
end
