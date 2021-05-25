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
          Phone.new(:web, request, params.merge(AppHandler.new(request, params).to_h))
          erb :result
	end
        
        get('/call') do
          content_type 'text/xml'
          px = Phone.new(:call, request, params)
          rx = Twilio::TwiML::VoiceResponse.new do |r|
            if !@params.has_key? 'Digits'
              r.gather(method: 'GET', action: '/call') do |g|
                g.say(message: "please enter your zip code followed by the pound key.")
              end
            else
              if px.admin? || px.boss?
                r.dial(number: @cloud.jid[@params['Digits']])
              else
                r.say(message: "thank you.  our local representative will contact you shortly.")
              end
            end
          end
          return rx.to_s
        end

        get('/sms') do
          content_type 'text/xml'
          Phone.new(:sms, request, params)
        end
        
end
def app
	Process.detach( fork { App.run! } )
end
end
