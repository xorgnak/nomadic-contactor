#cd /usr/share/nomadic

#####################
#   CONFIGURATION   #
#####################

#PORT=1234;
BG=/img-house.jpg;
LOGO=/logo.png;
BTN_COLOR=orange;
BTN_TEXT='FREE INSPECTION'
PHONE='12345551212';
RESPONSE='<%= Time.now %>'
#####################
#   CONFIGURATION   #
#####################

export BG LOGO BTN_COLOR BTN_TEXT PHONE RESPONSE;

redis-cli LPUSH SEED `cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1`
redis-cli SET COMMIT `git log --format="%h" -n 1`

if [[ "$USER" == 'root' ]]; then
	export PORT=80;
else
    if [[ -z "$PORT" ]]; then
	export PORT=8080;
    fi
fi

rm lib/nomadic/*~
rm views/*~
rm public/*~

ruby exe/shell.rb $*
