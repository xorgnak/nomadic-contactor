#cd /usr/share/nomadic

#####################
#   CONFIGURATION   #
#####################

#PORT=1234;
BTN_COLOR=orange;
BTN_TEXT='FREE INSPECTION'
PHONE='+18663897120';
PHONE_ADMIN='+16155926675'
#PHONE_ADMIN='+17205522104'
#PHONE_SID
#PHONE_KEY
WELCOME="Welcome to the caleb martin construction some help in town job managment system. We would love to help you manage your construction job and our local representatives are waiting for your request.  To help me locate you"

#####################
#   CONFIGURATION   #
#####################

if [[ -z "$PHONE_SID" ]]; then
    echo -e "#####\nrun:\nexport PHONE_SID='your twilio-account-sid';\nand rerun." && exit 1
fi
if [[ -z "$PHONE_KEY" ]]; then
    echo -e "#####\nrun:\nexport PHONE_KEY='your twilio-account-key';\nand rerun." && exit 1
fi


export BTN_COLOR BTN_TEXT PHONE PHONE_ADMIN PHONE_SID PHONE_KEY WELCOME;

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
