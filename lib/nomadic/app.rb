module NOMADIC
  ##
  # INTERACTION HANDLER
  ##
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
    
    before {
      headers "Access-Control-Allow-Origin" => "https://#{ENV['DOMAIN']}"
      @fields = Fields.new; @cloud = Cloud.new; @here = Nomadic.new }


    get('/service.js') { content_type 'application/javascript'; erb :service, layout: false }
    get('/manifest.webmanifest') { content_type 'text/json'; erb :manifest, layout: false }
    
    
    get('/') do
      Redis.new.publish "GET", JSON.generate(AppHandler.new(request, params).to_h)
      erb :index
    end
    
    post('/') do
      if params.has_key?('From') && !params.has_key?(:q)
        Phone.new(:web, request, params.merge(AppHandler.new(request, params).to_h))
        if params.has_key? :goto
          erb params[:goto].to_sym
        else
          erb :result
        end
      else
        Redis.new.publish('DEBUG.post.pre', "#{@q} " + JSON.generate(params))
        if params.has_key?(:q) && !params.has_key?(:a) && @here.ticket(params[:q]).active?('auth') == 'challange'
          r = []; 6.times {r << rand(9) }
          @here.ticket(params[:q]).activate(name: 'challange', ttl: 1000, value: params[:From]);
          @here.ticket(params[:q] + ':pin').activate(name: 'challange', ttl: 1000, value: r.join(''));
          params[:pin] = r.join('')
          Phone.new(:auth, request, params)
          Redis.new.publish("AUTH.test", "#{params}")
        end
        
        if params.has_key?(:a)
          if @here.ticket(params[:q] + ':pin').active?('challange') == params[:a]
            u = @here.ticket(params[:q]).active?('challange')
            @here.ticket(u).activate(name: 'token', ttl: 60 * 60 * 24, value: params[:q]);
            @here.ticket(params[:q]).activate(name: 'token', ttl: 60 * 60 * 24 * 7, value: u);
            if params.has_key? :create
              Redis.new.publish('DEBUG.post.create', "#{params}")
              if params[:hire] == 'true'
                @here.cloud.hire!(params[:create][:sponsor], u)
                @here.cloud.hire!(params[:create][:zone], u)
                us = @here.cloud.user(params[:From])
                us.sponsors << params[:create][:sponsor]
              end
            end
            Redis.new.publish("AUTH.test", "#{u} #{params}")
          else
            params[:goto] = '/comms/auth'
          end
        end
           
        if params.has_key? :config
          Redis.new.publish('DEBUG.post.config', "#{params}")
          us = @here.cloud.user(@here.ticket(params[:tok]).active?('token'))
          if params.has_key?(:campaign) && params[:config][:campaign] == 'new' 
            @here.cloud.zone(us.attr['zone']).campaigns[params[:campaign][:tag]] = params[:campaign][:offer]
            params[:config][:campaign] = params[:campaign][:tag]
          end
          
          if params.has_key?(:promo) && params[:config][:promo] == 'new'
            p = [];
            (0..9).each {|e| p << e}
            (:A..:Z).each {|e| p << e}
            @k = []; 6.times { @k << p.sample }
            @here.cloud.zone(us.attr['zone']).codes[@k.join('')] = params[:promo][:offer]
            params[:config][:promo] = @k.join('')
          end
          
          params[:config].each_pair { |k,v| us.attr[k] = v }
        end
        
        if params.has_key? :magic
          u = @here.cloud.user(@here.ticket(params[:tok]).active?('token'))
          @us = @here.cloud.user(Redis::HashKey.new('uid')[params[:usr]])
          Redis.new.publish('DEBUG.post.magic', "#{params}")
          [:nightlife, :food, :art, :music, :directions, :party, :camera ].each { |e|
            if params.has_key?("badge-#{e}");
              @us.stat.incr "#{u.attr['uid']}:#{e}";
              u.stat.incr "#{@us.attr['uid']}:#{e}";
            end
          }
          l = 0
          @us.stat.members(with_scores: true).to_h.each_pair { |k,v| l += v }
          @us.attr['badges'] = l
          @us.attr['lvl'] = "#{@us.attr['badges'].to_i}".length - 1
          if params.has_key? :boss
            params[:boss].each_pair { |k,v| if v != ''; @us.attr[k] = v; end }
          end
        end

        
        
        Redis.new.publish('DEBUG.post.post', "#{params}")
       
        redirect params[:goto]
      end
    end

    get('/nomadic.js') do
      content_type 'application/javascript'
      erb :nomadic, layout: false
    end
    
    get('/out') do
      
    end

    
    get('/audio/:track') do
      if File.exist? "audio/#{params[:track]}"
        return File.read("audio/#{params[:track]}")
      end
    end
    
    get('/call') do
      content_type 'text/xml'
      px = Phone.new(:call, request, params)
      rx = Twilio::TwiML::VoiceResponse.new do |r|
        if !@params.has_key? 'Digits'
          r.gather(method: 'GET', action: '/call') do |g|
            if File.exist? 'audio/welcome.mp3'
              g.play(url: "#{ENV['DOMAIN']}/audio/welcome.mp3")
            else
              g.say(message: "Hi. #{ENV['WELCOME']}, please enter your zip code followed by the pound key.")
            end
          end
        else
          if px.admin? || px.boss?
            r.dial(number: @cloud.jid[@params['Digits']])
          else
            if File.exist? 'audio/thanks.mp3'
              g.play(url: "https://#{ENV['DOMAIN']}/audio/thanks.mp3")
            else
              r.say(message: "thank you.  our local representative will contact you shortly.")
            end
          end
        end
      end
      return rx.to_s
    end
    
    get('/sms') do
      content_type 'text/xml'
      Phone.new(:sms, request, params)
    end
    
    get('/:type/:id' ) do
      if File.exist? 'views/' + params[:type] + '/' + params[:id] + '.erb'
        erb "#{params[:type]}/#{params[:id]}".to_sym
      else
        redirect '/'
      end
    end

    error do
      Redis.new.publish('ERROR.sinatra', @variable)
    end
    
  end
  ##
  # start app
  def app
    begin
      Process.detach( fork { App.run! } )
    rescue => e
      Redis.new.publish('ERROR.app', "#{e}")
    end
  end
end

