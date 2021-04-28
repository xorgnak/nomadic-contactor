module NOMADIC
class AppHandler
	def initialize r, p
		@request, @params, @h = r, p, h
	end
	def to_h
		@h
	end
end
class App < Sinatra::Base
	include NOMADIC
	configure do
	set :port, ENV['PORT']
	set :bind, '0.0.0.0'
	set :views, "#{Dir.pwd}/views/"
	set :public_folder, "#{Dir.pwd}/public/"
	end
	get('/') do
		erb :index
	end
	post('/') do
	return JSON.generate(AppHandler.new(request, params).to_h)
	end
end
def app
	Process.detach( fork { App.run! } )
end
end
