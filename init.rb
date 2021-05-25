
Redis.new.flushdb
@cloud = NOMADIC::Cloud.new
@user = @cloud.user ENV['PHONE_ADMIN']
@cloud.hire! '00000', ENV['PHONE_ADMIN']



