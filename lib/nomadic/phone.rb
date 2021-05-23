module NOMADIC
  class Phone
    def initialize t, r, p
      @type, @request, @params = t, r, p
      @cloud = Cloud.new()
      @clock = Clock.new()
      if @params['From'] == ENV['PHONE_ADMIN']
        @boss = true
      else
        @boss = false
      end
      if @cloud.at.has_key?(@params['From'])
        @admin = true
      else
        @admin = false
      end
      init!
      self.send(t)
    end
    def new?
      !@cloud.job.has_key?(@params['From'])
    end
    def boss?
      @boss
    end
    def admin?
      @admin
    end
    def twilio
      Twilio::REST::Client.new(ENV['PHONE_SID'], ENV['PHONE_KEY'])
    end
    ##
    # basic user tracking.
    def init!
      @body = @params['Body'].split(' ')
      if new?
        if !@cloud.at.has_key?(@params['From'])
          a = []
          3.times { a << (0..9).to_a.sample }
          @cloud.jid[a.join('')] = @params['From']
          @cloud.job[@params['From']] = a.join('')
        end
        @user = @cloud.user(@params['From'])
        @user.attr['since'] = @clock.epoch
        @user.attr['last'] = @clock.epoch
        @cloud.users << @params['From']
      else
        @user = @cloud.user(@params['From'])
        @user.attr['last'] = @clock.epoch
      end
      @user.attr['type'] = @type
      if @cloud.zones.members.include? @body[0]
        @to = @cloud.zone(@body[0]).admins.members.to_a
      else
        @to = ENV['PHONE_ADMIN']
      end
      
    end
    
    def send_sms h={}
      to = []
      [ h[:to] ].flatten.uniq.each do |t|
        if /^\+1#.+$/.match(t)
          @cloud.zone(t).admins.members.each { |e|  }
        else
          to << t
        end  
      end
      to.each do |t|
        ms = {
          body: h[:body],
          from: ENV['PHONE'],
          to: t
        }
        if h[:image]
          if h[:image].class == Array
            ms[:media_url] = h[:image]
          else
            ms[:media_url] = [ h[:image] ]
          end
        end
        if ENV['DEBUG'] == 'true'
          Redis.new.publish "DEBUG.send_sms", "#{ms}"
        else
          twilio.messages.create(ms)
        end
      end
    end

    def send_job!
      send_sms({
                 from: ENV['PHONE'],
                 to: @to,
                 body: "[#{@cloud.job[@params['From']]}] " + @params['From'] + " " + @params['Body']
             })
    end
    def send_msg m
      send_sms({from: ENV['PHONE'], to: @params['From'], body: m })
    end
    
    def handle!
      if boss?
        if @body.length > 1
          if @body[0] == "X"
            @cloud.fire! "+1" + @body[1]
          else
            @cloud.hire! @body[0], "+1" + @body[1]
            send_sms({
                       from: ENV['PHONE'],
                       to: "+1" + @body[1],
                       body: "You have been added to the #{@body[0]} team."
                     })
          end
        else
          send_msg(@cloud[@body[0]])
        end
      elsif admin? 
        if @body[0] == "X"
          if @cloud.user(@params['From']).jobs.members.include? @body[1]
            @cloud.finish(@body[1], @params['From'])
          end
        else
          if @cloud.jid.has_key? @body[0]
            @cloud.assign @body[0], @params['From']
            send_sms({
                       from: ENV['PHONE'],
                       to: @params['From'],
                       body: "You have been assigned job #{@body[0]}"
                     })
          end
        end
      else
        #handle local request
        @cloud.zone(@body[0]).users << @params['From']
        send_job!
      end
    end

    
    def web
      Redis.new.publish("DEBUG.web", "#{admin?} #{@body} #{@params}")
      @cloud.zone(@body[0]).users << @params['From']
      handle!
    end   
    def call
      # \d{3}# => connect admin to job
      # \d{5}# => create new job
      Redis.new.publish("DEBUG.call", "#{@request} #{@params}")
    end

    def sms
      Redis.new.publish "DEBUG.sms", "#{admin?} #{@body} #{@params}"
      handle!
    end
  end
end