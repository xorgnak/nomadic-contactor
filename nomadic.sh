#cd /usr/share/nomadic

#####################
#   CONFIGURATION   #
#####################

#PORT=1234;
BTN_COLOR=orange;
BTN_TEXT='FREE INSPECTION'
PHONE='+18663897120';
PHONE_ADMIN='+16155926675'
#PHONE_SID
#PHONE_KEY


#####################
#   CONFIGURATION   #
#####################

if [[ -z "$PHONE_SID" ]]; then
    echo -e "#####\nrun:\nexport PHONE_SID='your twilio-account-sid';\nand rerun." && exit 1
fi
if [[ -z "$PHONE_KEY" ]]; then
    echo -e "#####\nrun:\nexport PHONE_KEY='your twilio-account-key';\nand rerun." && exit 1
fi


export BTN_COLOR BTN_TEXT PHONE PHONE_ADMIN PHONE_SID PHONE_KEY;

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
