
##
#
# NOMADIC SETUP
#
##
# Everything in this file is executed right before the shell starts
#

##
# start the server
##
ME = '+17205522104'
@me = @here.cloud.user(ME)
##
# setup administrator
#
# create user
@here.cloud.user ENV['PHONE_ADMIN']
@here.cloud.user ME
# elevate user
@here.cloud.hire! '00000', ENV['PHONE_ADMIN']
['00000', '11111', '22222'].each { |e| @here.cloud.hire! e, ME }

##
# nomadic comms
##

@here.sub('#') { |t, o| Redis.new.publish "MQTT.#{t}", "#{o}" }

# sudscribe to channel. "#" is a channel wildcard

@here.sub(Redis::List.new('SEED').values[-1]) do |t, p|
  case p['method']
  when 'ping'
    @here.pub(p['target'], JSON.generate({ alive: Time.now.utc.to_i }))
  else
    Redis.new.publish("NODE.#{t}", p)
  end
end


@here.sub('connect') {|t, o|
  tik = @here.ticket(o['tok']).active?('token')
  u = @here.cloud.user(tik)
  u.attr['tok'] = o['tok']
  Redis.new.publish("CONNECT", "#{o} #{tik} #{u}")
  Redis::HashKey.new('book')[o['to']] = o['tok']
}

@here.sub('user/') {|t, o|
  Redis.new.publish("USER", "#{o}")
  from = @here.cloud.user(@here.ticket(o['tok']).active?('token')) 
  if o['method'] == 'save'
    ['name', 'tagline', 'img', 'venmo', 'tip', 'social', 'thanks', 'shield', 'border'].each do |e|
      from.attr[e] = o[e]
      @here.pub("user/#{o['tok']}", { to: from.attr['uid'], html: "<span>#{e}</span><span>#{@me.attr[e]}</span>"})
    end
  else
    @here.pub("user/#{o['tok']}", { to: from.attr['uid'], html: "<span>#{o}</span>"})
  end
}

# publish object to channel
#@here.pub('utc', { utc: Time.now.utc })


# set rider,influencer, or customer attributes
#@here.track[ENV['PHONE_ADMIN']] = { name: 'Erik', job: 'pedicabber' }

# track location visits and affinity
#@co = @here.cloud.zone('00000').special name: 'test special', ttl: 60 * 60, value: 'hope and pray.'
#@here.cloud.user(ME).special(@co)


#@track['location id'] = [ 'USR1', 'USR2' ...] 

#@here.game.play(ENV['PHONE_ADMIN'], sucess: 3, prize: 100, xp: 15, likes: 4, gp: 28)
#@here.game.vs(ENV['PHONE_ADMIN'], ME)


@tokens = {}

def token t, *a
  b = @tokens[t] = @here.bank.of(t)
  if !@tokens.has_key? t
    if b[:vault].account['World'] >= 0
      b[:branch].borrow(a[0] || 1)
    end
  end
  return b
end
##
# generate transactions
#
# user -> user
#@bank[:branch].tx from: 'Person 1', to: 'Person 2', qty: 5, payload: "pedicab ride"
# bank -> user
#@bank[:branch].tx to: 'Erik', qty: 100, payload: 'test credit'
# user -> bank
#@bank[:branch].tx from: 'Erik', qty: 1, payload: 'test debt'

##
# Bank ledger
#@ledger = NOMADIC.bank.ledger
