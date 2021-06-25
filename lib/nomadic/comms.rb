module NOMADIC
  def sub ch, &b
    m = PahoMqtt::Client.new
    PahoMqtt.logger = 'paho_mqtt'
    m.connect('localhost', 1883)
    m.on_message do |m|
      t = m.topic
      o = JSON.parse(m.payload)
      b.call(t, o)
    end
    m.subscribe([ch, 2])
  end
  
  def pub ch, o
    m = PahoMqtt::Client.new
    PahoMqtt.logger = 'paho_mqtt'
    m.connect('localhost', 1883)
    if o.class == String
      x = o
    else
      x = JSON.generate(o)
    end
    ### Publlish a message on the topic "/paho/ruby/test" with "retain == false" and "qos == 1"
    m.publish(ch, x, false, 1)
  end
end
# @here.sub('chan') {|t, o| Redis.new.publish "DEBUG.mqtt", "#{t} #{o}"}
# @here.pub('chan', { key: Time.now.utc })
