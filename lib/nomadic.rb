
module NOMADIC
end
class Nomadic
include NOMADIC
	def initialize
		app
	end
end

Dir["#{Dir.pwd}/lib/nomadic/*"].each { |e| load e }

@here = Nomadic.new
