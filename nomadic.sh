cd /usr/share/nomadic

function seed() {
	cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1
}

redis-cli LPUSH SEED seed

if [[ "$USER" == 'root' ]]; then
	export PORT=80;
else
	export PORT=8080;
fi

ruby exe/shell.rb $*
