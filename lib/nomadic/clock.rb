module NOMADIC
class Clock
	def initialize
	@t = Time.now.utc
	end
	def epoch
	@t.to_i
	end
	def time
	@t
	end
end
	def clock
	Clock.new
	end
end
