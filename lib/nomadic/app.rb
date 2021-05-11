module NOMADIC
class AppHandler
	def initialize r, p
	  @request, @params, @h = r, p, {}.merge(p)
          @a = @request.user_agent
          @h['referrer'] = @request.referrer
          @ua = DeviceDetector.new(@a)
          @h['ua'] = {
            name: @ua.name,
            ver: @ua.full_version,
            os: @ua.os_name,
            os_ver: @ua.os_full_version,
            dev: @ua.device_name,
            type: @ua.device_type
          }
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

        before { @fields = Fields.new; @cloud = Cloud.new }

        get('/') do
          Redis.new.publish "GET", JSON.generate(AppHandler.new(request, params).to_h)
          erb :index
	end

        post('/') do
	  Redis.new.publish "POST", JSON.generate(AppHandler.new(request, params).to_h)
          erb :result
	end
end
def app
	Process.detach( fork { App.run! } )
end
end
