Redis.new.flushdb
@cloud = NOMADIC::Cloud.new

@user = @cloud.user '+17205522104'

@user.team 'my team'
@user.team 'my other team'
@user.team 'yet another team'
@user.zone '80203'
@user.zone '80501'
@user.dept 'pedicabber'
@user.dept 'roofing'
@user.update!

