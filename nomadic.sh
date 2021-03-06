#cd /usr/share/nomadic

#####################
#   CONFIGURATION   #
#####################
# the domain we are hosting
# if not set at runtime, we will set it to localhost
if [[ -z "${DOMAIN}" ]]; then
    DOMAIN='localhost';
    
fi
# the port we're running on
if [[ -z "${PORT}" ]]; then
    #PORT=1234;
    echo "usage: PORT=<the port to run your web interface on>";
fi

# user focus background color
BADGE_BG='rgba(255,255,255, 0.1)';
# user focus accent color
BTN_COLOR=orange;
# call to action text
BTN_TEXT="GET A RIDE!"
# the phone number we're hosting
PHONE='+18663897120';

# the 'god mode' phone number
#PHONE_ADMIN='+16155926675';
PHONE_ADMIN='+17205522104'

# MUST BE SET AT RUNTIME / ON HOST
#PHONE_SID
#PHONE_KEY

# no audio file call messages.
# audio/welcome.mp3 will be played if available, otherwise...
WELCOME="Welcome to the caleb martin construction some help in town job managment system. We would love to help you manage your construction job and our local representatives are waiting for your request.  To help me locate you";
# audio/thanks.mp3 will be played if available, otherwise...
THANKS="Our local representative will contact you shortly";


#####################
#   CONFIGURATION   #
#####################

if [[ -z "$PHONE_SID" ]]; then
    echo -e "#####\nrun:\nexport PHONE_SID='your twilio-account-sid';\nand rerun." && exit 1
fi
if [[ -z "$PHONE_KEY" ]]; then
    echo -e "#####\nrun:\nexport PHONE_KEY='your twilio-account-key';\nand rerun." && exit 1
fi


export DOMAIN BADGE_BG BTN_COLOR BTN_TEXT PHONE PHONE_ADMIN PHONE_SID PHONE_KEY WELCOME LIVE DB DEBUG;


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

if [[ `gem list -i "^rvm$"` == true ]]; then
    rvm all do ruby exe/shell.rb $*
else
    ruby exe/shell.rb $*
fi
