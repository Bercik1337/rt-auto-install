#!/bin/bash
# PLEASE DO NOT SET ANY OF THE VARIABLES, THEY WILL BE POPULATED IN THE MENU
LASTMODIFIED="2015/11/17"
SCRIPTVERSION="2.6"

# https://linuxcommand.org/lc3_adv_tput.php
# Formatting variables
# colors
NORMAL=$(tput sgr0)
BOLD=$(tput bold)

#BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
#BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
#Not_used=$(tput setaf 8)
#DEFAULT=$(tput setaf 9)

#apt update done
APT_UDATE_NEEDED=true

# The system user rtorrent is going to run as
RTORRENT_USER=""
# The user that is going to log into rutorrent (htaccess)
WEB_USER=""
# Array with webusers including their hashed paswords
WEB_USER_ARRAY=()
# rTorrent users home dir
HOMEDIR=""
# rTorrent Port-Range
PORT_RANGE="6790-6999"
# Webserver
WEBSERVER="apache2"
# SSL encryption
SSL_ENCRYPTION="Self Signed"
# Domain-name
DOMAINNAME=""

# grep the Software Versions
RTVERSION=$(apt-cache policy rtorrent | head -3 | tail -1 | cut -d' ' -f4 | cut -d'-' -f1)
LIBTORRENTVERSION=$(apt-cache policy libtorrent?? | head -3 | tail -1 | cut -d' ' -f4 | cut -d':' -f2 | cut -d'-' -f1)
#RUTORRENTVERSION=$(wget -q https://api.github.com/repos/Novik/ruTorrent/tags -O - | grep name | cut -d'"' -f4 | grep -v 'rutorrent\|plugins\|beta' | head -1)
PHPVERSION=$(apt-cache policy php?.? | grep Candidate | grep -v none | cut -d' ' -f4 | cut -d'.' -f-2)

# Pretty function to spit out ok/fail after each important step.
function CHECKLASTRC {
	if [ $(echo $?) -ne 0 ]
	then
		echo "${WHITE}[${RED}failed${WHITE}]${NORMAL}"
		exit 1
	else
		echo "${WHITE}[${GREEN}ok${WHITE}]${NORMAL}"
	fi
}

# Function to check if running user is root
function CHECK_ROOT {
	if [ "$(id -u)" != "0" ]
	then
		echo
		echo "${RED}This script must be run as root.${NORMAL}" 1>&2
		echo
		exit 1
	fi
}

#os-release
#ID:       | NAME               | VERSION_ID             | /etc/debian_version          | /etc/issue                        | /etc/rpi-issue | ->Distribution
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
#linuxmint | LMDE               | release number         | (debian)point release number | NAME+VERSION \n \l                | -              | LMDE
#          | Linux Mint         | point release number   | (debian)VERSION_CODENAME/sid | PRETTYNAME+VERSION_CODENAME \n \l | -              | Linux Mint
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
#debian    | Debian GNU/Linux   | release number         | point release number         | NAME+VERSION_ID \n \l             | -              | Debian
#          | Debian GNU/Linux   | release number         | point release number         | NAME+VERSION_ID \n \l             | yes            | Raspberry Pi OS
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
#ubuntu    | Ubuntu             | point release number   | (debian)VERSION_CODENAME/sid | PRETTY_NAME \n \l                 | -              | Ubuntu
#          | Ubuntu             | point release number   | (debian)VERSION_CODENAME/sid | PRETTY_NAME \n \l                 | -              | Ubuntu LTS
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
#raspbian  | Raspbian GNU/Linux | (debian)release number | (debian)point release number | NAME+VERSION_ID \n \l             | yes            | Raspbian
#

function DETECTOS {
	echo " Detecting Operating System..."
	SUPPORTED_OS=("linuxmint" "debian" "ubuntu" "raspbian")

	ID=$(cat /etc/os-release | grep ^ID= | cut -d'=' -f2)

	case $ID in
	linuxmint)
		NAME=$(cat /etc/os-release | grep ^NAME= | cut -d'"' -f2);;
	debian)
		if [[ -e "/etc/rpi-issue" ]]
		then
			NAME="Raspberry Pi OS"
		else
			NAME=$ID
		fi;;
	ubuntu)
		if cat /etc/issue | grep -cq "LTS"
		then
			NAME="$ID LTS"
		else
			NAME=$ID
		fi;;
	*)
		NAME=$ID;;
	esac

	case $ID in
	debian)
		VERSION=$(cat /etc/debian_version);;
	*)
		VERSION=$(cat /etc/os-release | grep "VERSION_ID=" | cut -d'"' -f2);;
	esac
	#echo $NAME
	#echo $VERSION

	#EOLs
	#https://wiki.debian.org/DebianReleases
	#https://wiki.debian.org/LTS
	#https://linuxmint.com/download_all.php
	#https://wiki.ubuntu.com/Releases

	debian_eol=10
	#raspbian_eol=$debian_eol
	#raspberry_pi_os_eol=$debian_eol
	linux_mint_eol=19.3
	lmde_eol=5
	ubuntu_lts_eol=18.4
	ubuntu_eol=22.10

	case $NAME in
	LMDE)
		EOL=$lmde_eol;;
	"Linux Mint")
		EOL=$linux_mint_eol;;
	ubuntu)
		EOL=$ubuntu_eol;;
	"ubuntu LTS")
		EOL=$ubuntu_lts_eol;;
	debian|"Raspberry Pi OS"|raspbian)
		EOL=$debian_eol;;
	esac
	#echo $EOL

	#https://www.baeldung.com/linux/check-bash-array-contains-value
	#https://stackoverflow.com/questions/23086133/exact-match-using-if-statement-does-partial-match-as-well-need-to-do-exact-mat
	if [[ ${SUPPORTED_OS[@]} =~ $ID( |$) ]]
	then
		#echo "OS supported"
		:
	else
		echo " OS not supported"
		exit
	fi

	#https://stackoverflow.com/questions/8654051/how-can-i-compare-two-floating-point-numbers-in-bash
	if awk "BEGIN {exit !($VERSION > $EOL)}"
	then
		echo " You are using $ID release: $VERSION"
		sleep 3
		#:
	else
		echo " You are using $ID release: $VERSION"
		read -p " Your system has reached End Of Life, continue on own decision? [y/n] " -n 1
		if [[ $REPLY =~ [Yy]$ ]]
		then
			echo
		else
			echo
			#clear -x
			exit
			#:
		fi
	fi
}

# Checks for apache2-utils and unzip if it's installed. It's is needed to make the Web user
function PRE_UTILS {
	#AP_UT_CHECK="$(dpkg-query -W -f='${Status}' apache2-utils 2>/dev/null | grep -c "ok installed")"
	OPENSSL_CHECK="$(dpkg-query -W -f='${Status}' openssl 2>/dev/null | grep -c "ok installed")"
	#UNZIP_CHECK="$(dpkg-query -W -f='${Status}' unzip 2>/dev/null | grep -c "ok installed")"
	#CURL_CHECK="$(dpkg-query -W -f='${Status}' curl 2>/dev/null | grep -c "ok installed")"
	WGET_CHECK="$(dpkg-query -W -f='${Status}' wget 2>/dev/null | grep -c "ok installed")"

	echo -n " Install for the script pre-installation needed packages: "

	if [ "$OPENSSL_CHECK" -ne 1 ] || [ "$WGET_CHECK" -ne 1 ]
	then
		echo -n "("
		if [ "$OPENSSL_CHECK" -ne 1 ];
		then
			base0=openssl
			echo -n ""$base0" "
		fi
		if [ "$WGET_CHECK" -ne 1 ];
		then
			base1=wget
			echo -n ""$base1" "
		fi
		echo ")"

		apt-get update
		apt-get -yqq dist-upgrade
		APT_UDATE_NEEDED=false
		apt-get install -yqq $base0 $base1
		#https://peteris.rocks/blog/quiet-and-unattended-installation-with-apt-get/
		#DEBIAN_FRONTEND=noninteractive apt-get install -qq $base0 $base1 < /dev/null > /dev/null
	else
		echo -n "(none)"
	fi

	# grep the rutorrent Software Versions
	p=0
	while true
	do
		p=$(($p + 1))
		PARTS=$(wget -q https://api.github.com/repos/Novik/ruTorrent/tags?page=$p -O - | grep name | cut -d'"' -f4 | grep -v 'rutorrent\|plugins\|beta')

		if [ -z $(echo $PARTS | cut -d' ' -f1) ]
		then
			break
		else
			RUTORRENTVERSION="$RUTORRENTVERSION $PARTS"
			#echo $RUTORRENTVERSION
		fi
	done

	RUTORRENTVERSION_v4=$(echo "$RUTORRENTVERSION" | grep -v 'v5.' | head -1 | sed 's/ //g')
	RUTORRENTVERSION_v5=$(echo "$RUTORRENTVERSION" | grep -v 'v4.' | head -1 | sed 's/ //g')
	#RUTORRENTVERSION=$RUTORRENTVERSION_v5
}

function INSTALL_COMMON {
	if $APT_UDATE_NEEDED
	then
		apt-get -qq update
		apt-get -yqq dist-upgrade
	fi
	apt-get install -yqq curl unzip
}

# Header for the menu
function HEADER {
	clear -x
	echo "${WHITE}${BOLD}--------------------------------------------------------------------------------"
	echo "                       ${CYAN}Rtorrent + Rutorrent Auto Install"
	echo "                       Markus https://github.com/MarkusLange${NORMAL}"
	echo "${BOLD}--------------------------------------------------------------------------------${NORMAL}"
	echo
}

# License
function LICENSE {
	#clear -x
	#echo "${NORMAL}${BOLD}--------------------------------------------------------------------------------"
	echo " ${NORMAL}THE BEER-WARE LICENSE (Revision 42):"
	echo " ${GREEN}I${NORMAL} wrote this script, a modified version of Berciks script what is a modified"
	echo " version of Kerwoods script. As long as you retain this notice you"
	echo " can do whatever you want with this stuff. If we meet some day, and you"
	echo " think this stuff is worth it, you can buy me a beer in return.${NORMAL}"
	echo
	echo " Contact? use Github https://github.com/MarkusLange"
	echo
	echo "${BOLD}--------------------------------------------------------------------------------${NORMAL}"
	echo
	read -n 1 -s -p ' Press any key to continue...'
	echo
}

function CHOOSE_BRANCHE {
	echo " Choose the rutorrent branche, V4 supports autodl, in V5 autodl is"
	echo " brocken by now, so the installation of autodl would be prohibited"
	echo
	echo " [4] - Long Term Support for Version 4 (Super Stable)"
	echo " [5] - Long Term Support for Version 5 (Stable)"
	echo
	echo -n "${GREEN}>>${NORMAL} "
	read input
	
	case "$input" in
	4)
		RUTORRENTVERSION=$RUTORRENTVERSION_v4;;
	5)
		RUTORRENTVERSION=$RUTORRENTVERSION_v5;;
	esac
}

# Function to set the system user, rtorrent is going to run as
function SET_RTORRENT_USER {
	#UID_MIN=$(cat /etc/login.defs | grep "^UID_MIN" | grep -o '[[:digit:]]*')
	#UID_MAX=$(cat /etc/login.defs | grep "^UID_MAX" | grep -o '[[:digit:]]*')
	UID_MIN=$(awk '/^UID_MIN/ {print $2}' /etc/login.defs)
	UID_MAX=$(awk '/^UID_MAX/ {print $2}' /etc/login.defs)
	
	while true
	do
		echo -n " Please type a valid system user: ${GREEN}"
		read RTORRENT_USER
		UID_USER=$(cat /etc/passwd | grep "^$RTORRENT_USER:" | cut -d':' -f3)

		if [[ -z $(cat /etc/passwd | grep "^$RTORRENT_USER:") ]]
		then
			echo
			echo " ${NORMAL}This user does not exist!"
		elif [[ $UID_USER -gt $UID_MAX ]] || [[ $UID_USER -lt $UID_MIN ]]
		then
			echo
			echo " ${NORMAL}That user's is not regular user!"
		else
			HOMEDIR=$(cat /etc/passwd | grep /"$RTORRENT_USER":/ | cut -d':' -f6)
			RTORRENT_GROUP=$(id -g $RTORRENT_USER)
			break
		fi
	done
}

# Function to create users for the webinterface
function SET_WEB_USER {
	while true
	do
		echo -n " ${NORMAL}Please type a username for the webinterface: ${GREEN}"
		read WEB_USER
		tput sgr0
		echo -n " ${NORMAL}Password: "
		read -s PASSWORD1
		echo
		echo -n " ${NORMAL}Re-type Password: "
		read -s PASSWORD2
		echo

		if [ "$PASSWORD1" == "$PASSWORD2" ]
		then
			#USER=$(echo "$PASSWORD1" | htpasswd -i -n "$WEB_USER")
			USER=$(echo "$WEB_USER:$(openssl passwd -apr1 $PASSWORD1)")
			if [ $? = 0 ]
			then
				WEB_USER_ARRAY+=($USER)
				break
			fi
		else
			echo
			echo " ${RED}Something went wrong!"
			echo " You have entered an unusable username and/or different passwords.${NORMAL}"
			echo
		fi
		tput sgr0
	done
}

# Function to change rtorrent port
function SET_RT_PORT {
	echo -n " Please specify port range for rTorrent [act: ${GREEN}$PORT_RANGE${NORMAL}]: "
	read RT_PORT

	if [ -z "$RT_PORT" ]
	then
		echo " No changing in rtorrent.rc config file range is empty"
	else
		echo " Changing port in rtorrent.rc config file"
		PORT_RANGE=$RT_PORT
		CHECKLASTRC
	fi
}

# Function to list WebUI users in the menu
function LIST_WEB_USERS {
	for i in ${WEB_USER_ARRAY[@]}
	do
		USER_CUT=$(echo $i | cut -d \: -f 1)
		echo -n " $USER_CUT"
	done
}

# Function for installing dependencies
function INSTALL_APACHE {
	echo "${CYAN}Installing dependencies${NORMAL}"
	apt-get install -yqq apache2 libapache2-mod-php php-cli php-curl php-mbstring php-xml
	CHECKLASTRC

	#https://www.digitalocean.com/community/tutorials/apache-configuration-error-ah00558-could-not-reliably-determine-the-server-s-fully-qualified-domain-name
	echo "ServerName 127.0.0.1" >> /etc/apache2/apache2.conf

	#https://www.inmotionhosting.com/support/server/apache/hide-apache-version-and-linux-os/
	#https://stackoverflow.com/questions/24889346/how-to-uncomment-a-line-that-contains-a-specific-string-using-sed
	sed -i '/ServerTokens OS/  s/^/#/' /etc/apache2/conf-enabled/security.conf
	sed -i '/#ServerTokens Full/a ServerTokens Prod' /etc/apache2/conf-enabled/security.conf

	sed -i '/ServerSignature On/  s/^/#/' /etc/apache2/conf-enabled/security.conf
	sed -i '/ServerSignature Off/  s/^#//' /etc/apache2/conf-enabled/security.conf

	systemctl restart apache2.service
}

function INSTALL_NGINX {
	echo "${CYAN}Installing dependencies${NORMAL}"
	apt-get install -yqq nginx php-fpm php-cli php-curl php-mbstring
	CHECKLASTRC

	#https://www.inmotionhosting.com/support/server/nginx/hide-nginx-server-version/
	sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf
}

function INSTALL_LIGHTTPD {
	echo "${CYAN}Installing dependencies${NORMAL}"
	apt-get install -yqq lighttpd php-fpm php-cgi php-curl php-mbstring
	CHECKLASTRC
}

# Function rtorrent
function INSTALL_RTORRENT {
	# Download and install rtorrent
	echo "${CYAN}Install rtorrent${NORMAL}"
	apt-get install -yqq rtorrent tmux
	CHECKLASTRC

	# create directories
	mkdir -p $HOMEDIR/{Downloads,log,.rtorrent-session,watch/{load,start}}

	chown $RTORRENT_USER:$RTORRENT_GROUP $HOMEDIR/Downloads
	chown $RTORRENT_USER:$RTORRENT_GROUP $HOMEDIR/log
	chown $RTORRENT_USER:$RTORRENT_GROUP $HOMEDIR/.rtorrent-session
	chown $RTORRENT_USER:$RTORRENT_GROUP $HOMEDIR/watch
	chown $RTORRENT_USER:$RTORRENT_GROUP $HOMEDIR/watch/load
	chown $RTORRENT_USER:$RTORRENT_GROUP $HOMEDIR/watch/start

	# Copying rtorrent.rc file.
	echo "${YELLOW}Copying .rtorrent.rc${NORMAL}"
	cat > "$HOMEDIR/.rtorrent.rc" <<-EOF
################################################################################
# A minimal rTorrent configuration that provides the basic features
# you want to have in addition to the built-in defaults.
################################################################################

## Instance layout (base paths)
method.insert = cfg.basedir,  private|const|string, (cat,"/home/$RTORRENT_USER/")
method.insert = cfg.download, private|const|string, (cat,(cfg.basedir),"Downloads/")
method.insert = cfg.logs,     private|const|string, (cat,(cfg.basedir),"log/")
method.insert = cfg.logfile,  private|const|string, (cat,(cfg.logs),"rtorrent-",(system.time),".log")
method.insert = cfg.session,  private|const|string, (cat,(cfg.basedir),".rtorrent-session/")
method.insert = cfg.watch,    private|const|string, (cat,(cfg.basedir),"watch/")

## Listening port for incoming peer traffic
network.port_range.set = $PORT_RANGE
## Start opening ports at a random position within the port range
network.port_random.set = yes

## Tracker-less torrent and UDP tracker support
## (conservative settings for 'private' trackers, change for 'public')
dht.mode.set = disable
## UDP port to use for DHT
dht.port.set = 6881

trackers.use_udp.set = no

## Enable peer exchange (for torrents not marked private)
protocol.pex.set = no

## Peer settings
throttle.max_uploads.set = 100
throttle.max_uploads.global.set = 250

throttle.min_peers.normal.set = 20
throttle.max_peers.normal.set = 60
throttle.min_peers.seed.set = 30
throttle.max_peers.seed.set = 80
trackers.numwant.set = 80

#throttle.global_down.max_rate.set = 0
#throttle.global_up.max_rate.set = 0

## Encryption options, set to none (default) or any combination of the following:
## allow_incoming, try_outgoing, require, require_RC4, enable_retry, prefer_plaintext
protocol.encryption.set = allow_incoming,try_outgoing,enable_retry

## The IP address reported to the tracker
#network.local_address.set = 127.0.0.1
#network.local_address.set = rakshasa.no

## The IP address the listening socket and outgoing connections is bound to
#network.bind_address.set = 127.0.0.1
#network.bind_address.set = rakshasa.no

## Alternative calls to bind and IP that should handle dynamic IP's
#schedule2 = ip_tick,0,1800,ip=rakshasa
#schedule2 = bind_tick,0,1800,bind=rakshasa

## Basic operational settings (no need to change these)
session.path.set = (cat, (cfg.session))
directory.default.set = (cat, (cfg.download))
log.execute = (cat, (cfg.logs), "execute.log")
#log.xmlrpc = (cat, (cfg.logs), "xmlrpc.log")
#execute.nothrow = sh, -c, (cat, "echo >", (session.path), "rtorrent.pid", " ",(system.pid))

## Watch directories (add more as you like, but use unique schedule names)
## Add torrent
schedule2 = watch_load, 11, 10, ((load.verbose, (cat, (cfg.watch), "load/*.torrent")))
## Add & download straight away
schedule2 = watch_start, 10, 10, ((load.start_verbose, (cat, (cfg.watch), "start/*.torrent")))
## Close torrents when diskspace is low.
schedule2 = monitor_diskspace, 15, 60, ((close_low_diskspace, 1000M))

## SCGI Connectivity (for alternative rtorrent interfaces, XMLRPC)
## Use a IP socket with scgi_port
#network.scgi.open_port = 127.0.0.1:5000

## Run the rTorrent process as a daemon in the background
## (and control via XMLRPC sockets)
#system.daemon.set = true
network.scgi.open_local = /run/rtorrent/rpc.socket
execute.nothrow = chmod,777,/run/rtorrent/rpc.socket

## Other operational settings (check & adapt)
encoding.add = UTF-8
system.umask.set = 0027
system.cwd.set = (directory.default)
network.http.dns_cache_timeout.set = 25
pieces.hash.on_completion.set = no
#view.sort_current = seeding, greater=d.ratio=
#keys.layout.set = qwerty
#network.http.capath.set = "/etc/ssl/certs"
#network.http.ssl_verify_peer.set = 0
#network.http.ssl_verify_host.set = 0

## Some additional values and commands
method.insert = system.startup_time, value|const, (system.time)
method.insert = d.data_path, simple, "if=(d.is_multi_file), (cat, (d.directory), /), (cat, (d.directory), /, (d.name))"
method.insert = d.session_file, simple, "cat=(session.path), (d.hash), .torrent"

## Do not modify the following parameters unless you know what you're doing.
##
## Limits for file handle resources, this is optimized for
## an `ulimit` of 1024 (a common default). You MUST leave
## a ceiling of handles reserved for rTorrent's internal needs!
network.http.max_open.set = 50
network.max_open_files.set = 600
network.max_open_sockets.set = 300

## Memory resource usage (increase if you have a large number of items loaded,
## and/or the available resources to spend)
pieces.memory.max.set = 1800M
network.xmlrpc.size_limit.set = 4M

## Heavy I/O seedbox configuration
## Uncomment lines below if you have 1Gbit+ Internet link
## thanks Zebirek
#network.http.max_open.set = 99
#network.max_open_files.set = 600
#network.max_open_sockets.set = 999
#pieces.memory.max.set = 8048M
#network.receive_buffer.size.set = 32M
#network.send_buffer.size.set = 64M
#pieces.preload.type.set = 2
#pieces.preload.min_size.set = 262144
#pieces.preload.min_rate.set = 5120

## Logging:
## Levels = critical error warn notice info debug
## Groups = connection_* dht_* peer_* rpc_* storage_* thread_* tracker_* torrent_*
print = (cat, "Logging to ", (cfg.logfile))
log.open_file = "log", (cfg.logfile)
log.add_output = "info", "log"
#log.add_output = "tracker_debug", "log"
EOF

	CHECKLASTRC
	chown $RTORRENT_USER:$RTORRENT_GROUP $HOMEDIR/.rtorrent.rc

	echo "${CYAN}Creating rtorrent systemd file${NORMAL}"
	cat > "/etc/systemd/system/rtorrent.service" <<-EOF
[Unit]
Description=rtorrent (in tmux)

[Service]
Type=forking
RemainAfterExit=yes
User=$RTORRENT_USER
ExecStart=/usr/bin/tmux -2 new-session -d -s session-rtorrent rtorrent
ExecStop=/usr/bin/tmux send-keys -t session-rtorrent C-q
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=default.target
EOF

	systemctl enable rtorrent.service
	systemctl start rtorrent.service
}

# Function for installing rutorrent
function INSTALL_RUTORRENT {
	# Installing rutorrent.
	echo "${CYAN}Installing rutorrent${NORMAL}"
	
	#ffmpeg: enable screenshots plugin
	#sox: enable spectrogram plugin
	#mediainfo: enable mediainfo plugin
	#php-geoip: enable geoip plugin
	#unrar: enable unpack plugin
	#unzip: enable unpack plugin
	#python-cloudscraper: cloudflare plugin requirement
	apt-get install -yqq ffmpeg sox mediainfo unrar-free
	
	echo "${YELLOW}Downloading package${NORMAL}"
	wget -q https://github.com/Novik/ruTorrent/archive/refs/tags/$RUTORRENTVERSION.zip -O rutorrent.zip
	CHECKLASTRC

	echo "${YELLOW}Unpacking${NORMAL}"
	unzip -qqo rutorrent.zip
	CHECKLASTRC

	echo "${YELLOW}Renaming${NORMAL}"
	LATEST="ruTorrent-${RUTORRENTVERSION:1}"
	mv $LATEST rutorrent
	CHECKLASTRC

	if [ -d /var/www/rutorrent ]
	then
		rm -rf /var/www/rutorrent
	fi

	echo "${YELLOW}Deactivate not supported plugins${NORMAL}"
	# Deactivate not supported plugins
	# not supported: _cloudflare (not needed by now: https://github.com/Novik/ruTorrent/issues/1870#issuecomment-480913560)
	# not possible by folder rights: rutracker_check (Updatechecker for the russiantracker rutrack)
	# removed: geoip (it's deprecated since php 7.4)
	# not used: rpc (httprpc is used instead)
	# not activated in this setup: dump
	PLUGINS=("_cloudflare" "rutracker_check" "geoip" "rpc" "dump")
	sed -i '$a\\' rutorrent/conf/plugins.ini
	for PLUGIN in ${PLUGINS[@]}
	do
		sed -i '$a['"$PLUGIN"']' rutorrent/conf/plugins.ini
		sed -i '$aenabled = no' rutorrent/conf/plugins.ini
	done

	# Changeing SCGI mount to rpc.socket
	sed -i '/scgi_port/ s|5000|0|g' rutorrent/conf/config.php
	sed -i '/scgi_host/ s|127.0.0.1|unix:///run/rtorrent/rpc.socket|g' rutorrent/conf/config.php
	
	# Move ruTorrent errorlog to a folder writeable by www-data
	sed -i '/log_file/ s|/tmp/errors.log|/var/log/apache2/rutorrent-errors.log|g' rutorrent/conf/config.php

	echo "${YELLOW}Moving to /var/www/ ${NORMAL}"
	mv -f rutorrent /var/www/
	CHECKLASTRC

	echo "${YELLOW}Cleanup${NORMAL}"
	rm rutorrent.zip
	CHECKLASTRC

	# Changing permissions for rutorrent and plugins.
	echo "${YELLOW}Changing permissions for rutorrent${NORMAL}"
	chown -R www-data:www-data /var/www/rutorrent
	chmod -R 775 /var/www/rutorrent
	CHECKLASTRC
}

# create self-signed cert
function CREATE_SELF_SIGNED_CERT {
	# Creating Self-Signed certs
	echo "${YELLOW}Creating self-signed certificate${NORMAL}"
	openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -subj "/OU=My own rt-auto-install seedbox"  -keyout /etc/ssl/private/rutorrent-selfsigned.key -out /etc/ssl/certs/rutorrent-selfsigned.crt
}

# create let's encrypt cert
function CREATE_LETS_ENCRYPT_SIGNED_CERT {
	# Creating Let's Encrypt Signed certs
	echo "${YELLOW}Creating Let's Encrypt certificate${NORMAL}"
	apt-get install -yqq certbot
	
	certbot certonly --standalone --rsa-key-size 4096 --staple-ocsp --preferred-challenges dns --register-unsafely-without-email --agree-tos -d "$DOMAINNAME"
}

# apache2 can't work from tmp so all work from run for the socket
function CREATE_TMPFILES () {
	#https://serverfault.com/questions/779634/create-a-directory-under-var-run-at-boot
	cat > "/usr/lib/tmpfiles.d/rtorrent.conf" <<-EOF
#Type Path            Mode UID      GID        Age Argument
d     /run/rtorrent   0775 $RTORRENT_USER www-data   -   -
EOF

	# inital placement for the direct run
	mkdir -p /run/rtorrent
	chown -R $RTORRENT_USER:www-data /run/rtorrent
	chmod -R 775 /run/rtorrent
}

# Function for configuring apache
function CONFIGURE_APACHE {
	echo "${CYAN}Configuring apache${NORMAL}"

	a2enmod ssl
	a2enmod rewrite
	a2enmod proxy

	#https://raymii.org/s/tutorials/Strong_SSL_Security_On_Apache2.html
	#https://www.namecheap.com/support/knowledgebase/article.aspx/9821/38/apache-redirect-to-https/
	echo "${YELLOW}Creating apache vhost${NORMAL}"
	if [ ! -f /etc/apache2/sites-available/rutorrent.conf ]
	then
		cat > "/etc/apache2/sites-available/rutorrent.conf" <<-EOF
<VirtualHost *:80>
    ServerAlias *
    RewriteEngine on
    #RewriteRule ^/(.*) https://%{HTTP_HOST}/\$1 [NC,R=301,L]
    RewriteCond %{HTTPS} !=on
    RewriteRule ^/?rutorrent https://%{SERVER_NAME}/rutorrent [NC,R=301,L]
</VirtualHost>

<IfModule mod_ssl.c>
    <VirtualHost *:443>
        #ServerName  www.example.com
        DocumentRoot /var/www/

        LogLevel info ssl:warn
        ErrorLog /var/log/apache2/ssl_error.log
        CustomLog /var/log/apache2/ssl_access.log common
        ProxyPass /RPC2 unix:///run/rtorrent/rpc.socket|scgi://localhost

        <Directory "/var/www/rutorrent">
            AuthName "Restricted Area"
            AuthType Basic
            Require valid-user
            AuthUserFile /var/www/rutorrent/.htpasswd
        </Directory>

        SSLEngine on
        SSLCertificateFile /etc/ssl/certs/rutorrent-selfsigned.crt
        SSLCertificateKeyFile /etc/ssl/private/rutorrent-selfsigned.key
        SSLProtocol -all +TLSv1.3 +TLSv1.2
        SSLOpenSSLConfCmd Curves X25519:secp521r1:secp384r1:prime256v1
        SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
        SSLHonorCipherOrder on
    </VirtualHost>
</IfModule>
EOF

		a2dissite 000-default.conf
		a2ensite rutorrent.conf
		CHECKLASTRC

		systemctl restart apache2.service
	fi
}

# modifed from https://gist.github.com/juniorh/30bce3317207d6b2a887
function CONFIGURE_NGINX {
	echo "${CYAN}Configuring nginx${NORMAL}"

	#https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
	if [ ! -f /etc/nginx/sites-available/rutorrent ]
	then
		cat > "/etc/nginx/sites-available/rutorrent" <<-EOF
upstream backendrutorrent {
    server unix:/var/run/php/php$PHPVERSION-fpm.sock;
}

upstream backendrtorrent {
    server unix:/run/rtorrent/rpc.socket;
}

server{
    listen 80;
    location /rutorrent {
        return 301 https://\$host\$request_uri;
    }
}

server{
    listen 443 ssl;
    ssl on;
    ssl_certificate /etc/ssl/certs/rutorrent-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/rutorrent-selfsigned.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;

    root /var/www;

    auth_basic "Restricted";
    auth_basic_user_file /var/www/rutorrent/.htpasswd;

    location /RPC2 {
        include scgi_params;
        scgi_pass backendrtorrent;
    }

    location / {
        location ~ .php\$ {
            fastcgi_split_path_info ^(.+\.php)(.*)\$;
            fastcgi_pass    backendrutorrent;
            fastcgi_index   index.php;
            fastcgi_param   SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            include fastcgi_params;
        }
    }
}
EOF

		unlink /etc/nginx/sites-enabled/default
		ln -s /etc/nginx/sites-available/rutorrent /etc/nginx/sites-enabled/

		systemctl restart php$PHPVERSION-fpm.service
		systemctl restart nginx.service
	fi
}

function CONFIGURE_LIGHTTPD {
	echo "${CYAN}Configuring lighttpd${NORMAL}"
	sed -i "s#/var/www/html#/var/www#" /etc/lighttpd/lighttpd.conf

	lighty-enable-mod fastcgi 
	lighty-enable-mod fastcgi-php
	lighty-enable-mod auth

	# https://raymii.org/s/tutorials/Strong_SSL_Security_On_lighttpd.html
	if [ ! -f /etc/lighttpd/conf-available/30-rutorrent.conf ]
	then
		cat > "/etc/lighttpd/conf-available/30-rutorrent.conf" <<-EOF
server.modules += ( "mod_redirect" )
server.modules += ( "mod_openssl" )

# SSL Settings
\$SERVER["socket"] == ":443" {
    ssl.engine  = "enable"
    ssl.pemfile = "/etc/ssl/certs/rutorrent-selfsigned.crt"
    ssl.privkey = "/etc/ssl/private/rutorrent-selfsigned.key"
    # or joined as pem for older versions from lighttpd
    # ssl.pemfile = "/etc/ssl/certs/rutorrent-selfsigned.pem"
    ssl.openssl.ssl-conf-cmd = ("Protocol" => "-TLSv1.1, -TLSv1, -SSLv3")
    ssl.cipher-list = "EECDH+AESGCM:EDH+AESGCM:AES128+EECDH:AES128+EDH"
    ssl.use-compression = "disable"

    scgi.server = ( "/RPC2" =>
        ( "127.0.0.1" =>
            (
                "socket" => "/run/rtorrent/rpc.socket",
                "disable-time" => 0,
                "check.local" => "disable"
            )
        )
    )

    auth.backend = "htpasswd"
    auth.backend.htpasswd.userfile = "/var/www/rutorrent/.htpasswd"
    auth.require = ( "/rutorrent" =>
        (
            "method"  => "basic",
            "realm"   => "Login",
            "require" => "valid-user"
        )
    )
}

# Redirect all HTTP requests to HTTPS
\$HTTP["scheme"] == "http" {
    # capture vhost name with regex conditional -> %0 in redirect pattern
    # must be the most inner block to the redirect rule
    \$HTTP["host"] =~ ".*" {
        url.redirect = (".*/rutorrent" => "https://%0\$0")
    }
}
EOF

		unlink /etc/lighttpd/conf-enabled/99-unconfigured.conf
		ln -s /etc/lighttpd/conf-available/30-rutorrent.conf /etc/lighttpd/conf-enabled/

		systemctl restart lighttpd.service
	fi
}

function CREATE_HTACCESS {
	# Creating .htaccess file
	echo "${YELLOW}Creating .htaccess file${NORMAL}"
	printf "%s\n" "${WEB_USER_ARRAY[@]}" > /var/www/rutorrent/.htpasswd
}

function AUTODL-IRSSI {
	#Set IRSSI_USER equal to RTORRENT_USER grep from rtorrent.service
	IRSSI_USER=$(cat /etc/systemd/system/rtorrent.service | grep User | cut -d= -f2)
	IRSSI_GROUP=$(id -g $IRSSI_USER)

	IRSSI_PORT=$(shuf -i 20000-30000 -n 1)
	IRSSI_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)

	#install irssi
	apt-get install -yqq git irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libjson-perl libjson-xs-perl libxml-libxslt-perl php-xml

	cat > "/etc/systemd/system/irssi.service" <<-EOF
[Unit]
Description=irssi (in tmux)
After=network.target

[Service]
Type=forking
RemainAfterExit=yes
User=$IRSSI_USER
ExecStart=/usr/bin/tmux -2 new-session -d -s session-irssi irssi
ExecStop=/usr/bin/tmux send-keys -t session-irssi "/quit" KPEnter
WorkingDirectory=/home/$IRSSI_USER/
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=default.target
EOF

	#install autodl-irssi a plugin for irssi that monitors IRC announce channels and downloads torrent files based on user-defined filters.
	wget -q https://github.com/autodl-community/autodl-irssi/releases/download/2.6.2/autodl-irssi-v2.6.2.zip -O autodl-irssi.zip

	mkdir -p /home/$IRSSI_USER/.irssi/scripts/autorun/
	unzip -qqo autodl-irssi.zip -d /home/$IRSSI_USER/.irssi/scripts/
	mv /home/$IRSSI_USER/.irssi/scripts/autodl-irssi.pl /home/$IRSSI_USER/.irssi/scripts/autorun/

	mkdir -p /home/$IRSSI_USER/.autodl

	cat > "/home/$IRSSI_USER/.autodl/autodl.cfg" <<-EOF
[options]
gui-server-port = $IRSSI_PORT
gui-server-password = $IRSSI_PASSWORD
EOF

	chown -R $IRSSI_USER:$IRSSI_GROUP /home/$IRSSI_USER/.autodl/
	chown -R $IRSSI_USER:$IRSSI_GROUP /home/$IRSSI_USER/.irssi/

	rm autodl-irssi.zip

	#install autodl-rutorrent is a plugin for ruTorrent to monitor and configure autodl-irssi
	git clone -q https://github.com/stickz/autodl-rutorrent.git /var/www/rutorrent/plugins/autodl-irssi
	rm -rf /var/www/rutorrent/plugins/autodl-irssi/.git*

	chown -R www-data:www-data /var/www/rutorrent/plugins/autodl-irssi
	chmod -R 775 /var/www/rutorrent/plugins/autodl-irssi

	# Putting autodl-irssi login into config.php to make it usable on common ground
	sed -i '3i\\t$autodlPort = '"$IRSSI_PORT"';' /var/www/rutorrent/conf/config.php
	sed -i '4i\\t$autodlPassword = \"'"$IRSSI_PASSWORD"'\";' /var/www/rutorrent/conf/config.php

	systemctl enable irssi.service
	systemctl start irssi.service
}

# Function for showing the end result when install is complete
function INSTALL_COMPLETE {
	echo "${GREEN}Installation is complete.${NORMAL}"
	echo
	echo "${RED}Your default Apache2 vhost file has been disabled and replaced with a new one."
	echo "If you were using it, combine the default and rutorrent vhost file and enable"
	echo "it again.${NORMAL}"
	echo
	echo "${MAGENTA}Your downloads folder is in ${CYAN}$HOMEDIR/Downloads${NORMAL}"
	echo "${MAGENTA}Sessions data is ${CYAN}$HOMEDIR/.rtorrent-session${NORMAL}"
	echo "${MAGENTA}rtorrent's configuration file is ${CYAN}$HOMEDIR/.rtorrent.rc${NORMAL}"
	echo
	echo "${MAGENTA}If you want to change settings for rtorrent, such as download folder, etc.,"
	echo "you need to edit the '${CYAN}.rtorrent.rc${MAGENTA}' file. E.g. '${CYAN}nano $HOMEDIR/.rtorrent.rc${MAGENTA}'${NORMAL}"
	echo

	# The IPv6 local address, is not very used for now, anyway if needed, just change 'inet' to 'inet6'
	lcl=$(ip addr | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | grep -v "127." | head -n 1)
	ext=$(wget -O - -q ipv4.icanhazip.com)

	if [[ ! -z "$lcl" ]] && [[ ! -z "$ext" ]]
	then
		if [[ $HTTP_PORT != "" ]]
		then
			echo "${CYAN}LOCAL IP:${NORMAL} http://$lcl:$HTTP_PORT/rutorrent"
		else
			echo "${CYAN}LOCAL IP:${NORMAL} http://$lcl/rutorrent"
		fi
		echo "${CYAN}EXTERNAL IP:${NORMAL} http://$ext/rutorrent"
		echo
		echo "Visit rutorrent through the above address."
		echo "${RED}Now available with HTTPS redirection!${NORMAL}"
	else
		if [[ -z "$lcl" ]]
		then
			echo "Can't detect the local IP address"
			echo "Try visit rutorrent at http://127.0.0.1/rutorrent"
			echo
		elif [[ -z "$ext" ]]
		then
			echo "${CYAN}LOCAL:${NORMAL} http://$lcl/rutorrent"
			echo "Visit rutorrent through your local network"
			echo
		else
			echo "Can't detect the IP address"
			echo "Try visit rutorrent at http://127.0.0.1/rutorrent"
			echo
		fi
	fi
}

function CHOOSE_WEBSEVER {
	echo " Change the Webserver [act: ${GREEN}$WEBSERVER${NORMAL}]"
	echo " [1] - lighttpd"
	echo " [2] - nginx"
	echo " [3] - apache2"
	echo
	echo -n "${GREEN}>>${NORMAL} "
	read decision
	
	case "$decision" in
	1)
		WEBSERVER="lighttpd";;
	2)
		WEBSERVER="nginx";;
	3|*)
		WEBSERVER="apache2";;
	esac
}

# https://stackoverflow.com/questions/2642585/read-a-variable-in-bash-with-a-default-value
function CHOOSE_SSL_ENCRYPTION {
	echo " Change SSL Encyption [act: ${GREEN}$SSL_ENCRYPTION${NORMAL}]"
	echo " [L] - Let's Encrypt"
	echo " [S] - Self Signed"
	echo
	echo -n "${GREEN}>>${NORMAL} "
	read decision
	
	case "$decision" in
	L|l)
		SSL_ENCRYPTION="Lets Encrypt"
		HEADER
		CHECK_YOUR_HOSTNAME;;
	S|s|*)
		SSL_ENCRYPTION="Self Signed";;
	esac
}

function CHECK_YOUR_HOSTNAME {
	DOMAINNAME=$(wget -q -O - ipinfo.io/json | grep "hostname" | cut -d'"' -f4)
	echo -n " "
	read -e -i "$DOMAINNAME" -p "Please enter/verify your domainname: " input
	DOMAINNAME="${input:-$DOMAINNAME}"

	#echo
	#echo "the name is"
	#echo $DOMAINNAME
}

function UPDATE_RUTORRENT {
	ACT_RUTORRENT=$(cat /var/www/rutorrent/js/webui.js | grep -m 1 version: | cut -d'"' -f2)
	
	if [[ $(find /etc/systemd/ -name lighttpd.service | wc -l) -ne 0 ]]
	then
		ACT_WEBSERVER=lighttpd
	elif [[ $(find /etc/systemd/ -name nginx.service | wc -l) -ne 0 ]]
	then
		ACT_WEBSERVER=nginx
	else
		ACT_WEBSERVER=apache2
	fi
	
	PRE_CHOOSE=$RUTORRENTVERSION
	
	if [[ ${ACT_RUTORRENT:0:1} == 4 ]]
	then
		RUTORRENTVERSION=$RUTORRENTVERSION_v4
	else
		RUTORRENTVERSION=$RUTORRENTVERSION_v5
	fi
	
	echo " Update ruTorrent from actual installed version ${GREEN}$ACT_RUTORRENT${NORMAL} to current ${GREEN}${RUTORRENTVERSION:1}${NORMAL}"
	echo " When updating ruTorrent and autodl-irssi is installed the irrsi login"
	echo " will transfered. Websiteprotection (htpasswd) would be reestablished."
	echo
	echo " Webserver is ${GREEN}$ACT_WEBSERVER${NORMAL}"
	echo
	echo " [u] - Update"
	echo " [d] - Dismiss"
	echo
	echo -n "${GREEN}>>${NORMAL} "
	read input
	
	case "$input" in
	u)
		case "$ACT_WEBSERVER" in
		apache2)
			systemctl stop apache2.service;;
		lighttpd)
			systemctl stop lighttpd.service;;
		nginx)
			systemctl stop php$PHPVERSION-fpm.service
			systemctl stop nginx.service;;	
		esac
		
		mapfile -t OLD_WEB_USER_ARRAY < /var/www/rutorrent/.htpasswd
		
		INSTALL_RUTORRENT
		
		printf "%s\n" "${OLD_WEB_USER_ARRAY[@]}" > /var/www/rutorrent/.htpasswd
		
		if [[ $(find /home/ -name autodl.cfg | wc -l) -ne 0 ]]
		then
			ACT_AUTODL_PORT=$(cat $(find /home/ -name autodl.cfg )| grep "gui-server-port" | cut -d' ' -f3)
			ACT_AUTODL_PASSWORD=$(cat $(find /home/ -name autodl.cfg )| grep "gui-server-password" | cut -d' ' -f3)
			
			# Putting autodl-irssi login into config.php to make it usable on common ground
			sed -i '3i\\t$autodlPort = '"$ACT_AUTODL_PORT"';' /var/www/rutorrent/conf/config.php
			sed -i '4i\\t$autodlPassword = \"'"$ACT_AUTODL_PASSWORD"'\";' /var/www/rutorrent/conf/config.php
			
			#install autodl-rutorrent is a plugin for ruTorrent to monitor and configure autodl-irssi
			git clone -q https://github.com/stickz/autodl-rutorrent.git /var/www/rutorrent/plugins/autodl-irssi
			rm -rf /var/www/rutorrent/plugins/autodl-irssi/.git*
			
			chown -R www-data:www-data /var/www/rutorrent/plugins/autodl-irssi
			chmod -R 775 /var/www/rutorrent/plugins/autodl-irssi
		fi
		
		case "$ACT_WEBSERVER" in
		apache2)
			systemctl start apache2.service;;
		lighttpd)
			systemctl start lighttpd.service;;
		nginx)
			systemctl start php$PHPVERSION-fpm.service
			systemctl start nginx.service;;	
		esac
		;;
	d)
		;;
	esac
 	
	RUTORRENTVERSION=$PRE_CHOOSE 
}

function MENU() {
	while true
	do
		HEADER
		echo " ${BOLD}    rTorrent version:${NORMAL} ${GREEN} $RTVERSION ${NORMAL}"
		echo " ${BOLD}  libTorrent version:${NORMAL} ${GREEN} $LIBTORRENTVERSION ${NORMAL}"
		echo " ${BOLD}   ruTorrent version:${NORMAL} ${GREEN} ${RUTORRENTVERSION:1} ${NORMAL}"
		echo " ${BOLD}      Script version:${NORMAL} ${GREEN} $SCRIPTVERSION ${NORMAL}"
		echo
		echo " [1] - Add/Change rTorrent user: ${GREEN}$RTORRENT_USER${NORMAL}"
		echo -n " [2] - Add ruTorrent user(s):${GREEN}"
		LIST_WEB_USERS
		echo "${NORMAL}"
		echo " [w] - Change Webserver [act: ${GREEN}$WEBSERVER${NORMAL}]"
		echo " [p] - Change rTorrent Port-Range [act: ${GREEN}$PORT_RANGE${NORMAL}]"
		echo " [s] - Change SSL Encyption [act: ${GREEN}$SSL_ENCRYPTION${NORMAL}]"
		echo " [c] - Show Changelog"
		echo " [t] - Show To-Do"
		echo " [0] - Start installation"
		if [[ $RUTORRENTVERSION == $RUTORRENTVERSION_v4 ]]
		then
			echo " [a] - Start installation with autodl-irssi"
		fi
		echo " [u] - Update ruTorrent"
		echo " [q] - Quit"
		
#		if [[ -z "$RTORRENT_USER" ]]; then
#			echo "rTorrent user is empty"
#		fi
#		if [[ -z "${WEB_USER_ARRAY[@]}" ]]; then
#			echo "ruTorrent user is empty"
#		fi

		echo
		echo
		if [[ $RUTORRENTVERSION == $RUTORRENTVERSION_v5 ]]
		then
			echo
		fi
		echo -n "${GREEN}>>${NORMAL} "
		read input
		
		if [[ $RUTORRENTVERSION == $RUTORRENTVERSION_v5 ]]
		then
			if [[ $input == "a" ]]
			then
				input="0"
			fi
		fi

		case "$input" in
		1)
			HEADER
			SET_RTORRENT_USER;;
		2)
			HEADER
			SET_WEB_USER;;
		w)
			HEADER
			CHOOSE_WEBSEVER;;
		c)
			HEADER
			wget -q -O - https://raw.githubusercontent.com/MarkusLange/rt-auto-install/master/Changelog | head -n 17
			read -rsp $'Press any key to continue...' -n1 ke;;
		t)
			HEADER
			wget -q -O - https://raw.githubusercontent.com/MarkusLange/rt-auto-install/master/ToDo | head -n 17
			read -rsp $'Press any key to continue...' -n1 ke;;
		p)
			HEADER
			SET_RT_PORT;;
		s)
			HEADER
			CHOOSE_SSL_ENCRYPTION;;
		0|a)
			if [[ -z "$RTORRENT_USER" ]] || [[ -z "${WEB_USER_ARRAY[@]}" ]]
			then
				HEADER
				echo " rTorrent user and/or ruTorrent uses is/are missing installation aborted"
				sleep 3
			else
				INSTALL_COMMON
				
				case $SSL_ENCRYPTION in
				"Self Signed")
					CREATE_SELF_SIGNED_CERT;;
				"Lets Encrypt")
					CREATE_LETS_ENCRYPT_SIGNED_CERT;;
				esac
				
				case "$WEBSERVER" in
				apache2)
					INSTALL_APACHE;;
				lighttpd)
					INSTALL_LIGHTTPD;;
				nginx)
					INSTALL_NGINX;;
				esac
				
				CREATE_TMPFILES
				INSTALL_RTORRENT
				INSTALL_RUTORRENT
				
				case "$WEBSERVER" in
				apache2)
					CONFIGURE_APACHE;;
				lighttpd)
					CONFIGURE_LIGHTTPD;;
				nginx)
					CONFIGURE_NGINX;;
				esac
				
				if [[ $SSL_ENCRYPTION == "Lets Encrypt" ]]
				then
					case "$WEBSERVER" in
					apache2)
						sed -i 's#/etc/ssl/certs/rutorrent-selfsigned.crt#/etc/letsencrypt/live/'"$DOMAINNAME"'/fullchain.pem#' /etc/apache2/sites-available/rutorrent.conf
						sed -i 's#/etc/ssl/private/rutorrent-selfsigned.key#/etc/letsencrypt/live/'"$DOMAINNAME"'/privkey.pem#' /etc/apache2/sites-available/rutorrent.conf
						;;
					lighttpd)
						sed -i 's#/etc/ssl/certs/rutorrent-selfsigned.crt#/etc/letsencrypt/live/'"$DOMAINNAME"'/fullchain.pem#' /etc/lighttpd/conf-available/30-rutorrent.conf
						sed -i 's#/etc/ssl/private/rutorrent-selfsigned.key#/etc/letsencrypt/live/'"$DOMAINNAME"'/privkey.pem#' /etc/lighttpd/conf-available/30-rutorrent.conf
						;;
					nginx)
						sed -i 's#/etc/ssl/certs/rutorrent-selfsigned.crt#/etc/letsencrypt/live/'"$DOMAINNAME"'/fullchain.pem#' /etc/nginx/sites-available/rutorrent
						sed -i 's#/etc/ssl/private/rutorrent-selfsigned.key#/etc/letsencrypt/live/'"$DOMAINNAME"'/privkey.pem#' /etc/nginx/sites-available/rutorrent
						;;
					esac
				fi
				
				CREATE_HTACCESS
				
				if [[ $input == "a" ]]
				then
					AUTODL-IRSSI
				fi
				
				case "$WEBSERVER" in
				apache2)
					systemctl restart apache2.service;;
				lighttpd)
					systemctl restart lighttpd.service;;
				nginx)
					systemctl restart php$PHPVERSION-fpm.service
					systemctl restart nginx.service;;	
				esac
				
				clear -x
				HEADER
				INSTALL_COMPLETE
				break
			fi
			;;
		u)
			HEADER
			UPDATE_RUTORRENT;;
		q)
			break;;
		esac
	done
}

function START() {
	CHECK_ROOT
	DETECTOS
	PRE_UTILS
	HEADER
	LICENSE
	HEADER
	CHOOSE_BRANCHE
	MENU
	tput sgr0
}

START
