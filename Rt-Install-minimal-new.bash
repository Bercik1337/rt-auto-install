#!/bin/bash
# PLEASE DO NOT SET ANY OF THE VARIABLES, THEY WILL BE POPULATED IN THE MENU
LASTMODIFIED="2024/02/14"
SCRIPTVERSION="2.0"

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

# grep the Software Versions
RTVERSION=$(apt-cache policy rtorrent | head -3 | tail -1 | cut -d' ' -f4 | cut -d'-' -f1)
LIBTORRENTVERSION=$(apt-cache policy libtorrent?? | head -3 | tail -1 | cut -d' ' -f4 | cut -d':' -f2 | cut -d'-' -f1)
RUTORRENTVERSION=$(wget -q https://api.github.com/repos/Novik/ruTorrent/tags -O - | grep name | cut -d'"' -f4 | grep -v 'rutorrent\|plugins\|beta' | head -1)

# grep System architecture
ARCHITECTURE=$(dpkg --print-architecture)

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

	debian_eol=9
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
function APACHE_UTILS {
	AP_UT_CHECK="$(dpkg-query -W -f='${Status}' apache2-utils 2>/dev/null | grep -c "ok installed")"
	UNZIP_CHECK="$(dpkg-query -W -f='${Status}' unzip 2>/dev/null | grep -c "ok installed")"
	CURL_CHECK="$(dpkg-query -W -f='${Status}' curl 2>/dev/null | grep -c "ok installed")"
	WGET_CHECK="$(dpkg-query -W -f='${Status}' wget 2>/dev/null | grep -c "ok installed")"

	echo " Install for the script pre-installation needed packages"
	echo " (apache2-utils, unzip, curl and wget) if not allready installed."

	if [ "$AP_UT_CHECK" -ne 1 ] || [ "$UNZIP_CHECK" -ne 1 ] || [ "$CURL_CHECK" -ne 1 ] || [ "$WGET_CHECK" -ne 1 ]
	then
#		echo " One or more of the packages apache2-utils, unzip, curl or wget is not installed and is needed for the setup."
#		read -p " Do you want to install it? [y/n] " -n 1
#		if [[ $REPLY =~ [Yy]$ ]]
#		then
#			echo
			apt-get -qq update
			if [ "$AP_UT_CHECK" -ne 1 ];
			then
				base0=apache2-utils
			fi
			if [ "$UNZIP_CHECK" -ne 1 ];
			then
				base1=unzip
			fi
			if [ "$CURL_CHECK" -ne 1 ];
			then
				base2=curl
			fi
			if [ "$WGET_CHECK" -ne 1 ];
			then
				base3=wget
			fi
			#https://peteris.rocks/blog/quiet-and-unattended-installation-with-apt-get/
			DEBIAN_FRONTEND=noninteractive apt-get install -qq $base0 $base1 $base2 $base3 < /dev/null > /dev/null
#		else
#			clear -x
#			exit
			#:
#		fi
	fi
}

# Header for the menu
function HEADER {
	clear -x
	echo "${WHITE}${BOLD}--------------------------------------------------------------------------------"
	echo "                       ${CYAN}Rtorrent + Rutorrent Auto Install"
	echo "                       Bercik https://github.com/Bercik1337${NORMAL}"
	echo "${BOLD}--------------------------------------------------------------------------------${NORMAL}"
	echo
}

# License
function LICENSE {
	#clear -x
	#echo "${NORMAL}${BOLD}--------------------------------------------------------------------------------"
	echo " ${NORMAL}THE BEER-WARE LICENSE (Revision 42):"
	echo " ${GREEN}Bercik${NORMAL} wrote this script. As long as you retain this notice you"
	echo " can do whatever you want with this stuff. If we meet some day, and you"
	echo " think this stuff is worth it, you can buy me a beer in return.${NORMAL}"
	echo
	echo " Contact? use Github https://github.com/Bercik1337"
	echo
	echo "${BOLD}--------------------------------------------------------------------------------${NORMAL}"
	echo
	read -n 1 -s -p ' Press any key to continue...'
	echo
}

function WAIT_A_MINUTE {
	echo "${NORMAL}${BOLD}--------------------------------------------------------------------------------"
	echo " ${NORMAL}Now you will be ask for a valid system user and an user for the ruTorrent"
	echo " Webportal (any user possible, no bindings on system user present)"
	echo " then you will hit the Menu for the Installation and other Options."
	echo "${BOLD}--------------------------------------------------------------------------------${NORMAL}"
	#sleep 10
	#echo
	for i in {5..1}
	do
		echo -n "."
		sleep 1
	done
	echo -e
}

# Function to set the system user, rtorrent is going to run as
function SET_RTORRENT_USER {
	while true
	do
		echo -n " Please type a valid system user: ${GREEN}"
		read RTORRENT_USER

		if [[ -z $(cat /etc/passwd | grep "^$RTORRENT_USER:") ]]
		then
			echo
			echo " ${NORMAL}This user does not exist!"
		elif [[ $(cat /etc/passwd | grep "^$RTORRENT_USER:" | cut -d: -f3) -lt 1 ]]
		then
			echo
			echo " ${NORMAL}That user's UID is too low!"
		elif [[ $RTORRENT_USER == nobody ]]
		then
			echo
			echo " ${NORMAL}You cant use 'nobody' as user!"
		else
			HOMEDIR=$(cat /etc/passwd | grep /"$RTORRENT_USER":/ | cut -d: -f6)
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
			USER=$(echo "$PASSWORD1" | htpasswd -i -n "$WEB_USER")
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
function APT_DEPENDENCIES {
	echo "${CYAN}Installing dependencies${NORMAL}"
	apt-get -qq update
	apt-get -yqq install openssl git apache2 apache2-utils php php-curl php-cli libapache2-mod-php tmux mediainfo unrar-free
	CHECKLASTRC
}

# SCGI installation because it isn't supported anymore after php7.4
function INSTALL_SCGI {
	SCGI=$(apt-cache show libapache2-mod-scgi 2>&1 | grep -cv "E: No packages found")

	if [ $SCGI -ne 1 ]
	then
		echo "${CYAN}Download scgi${NORMAL}"

		case $ARCHITECTURE in
		armhf)
			wget http://ftp.debian.org/debian/pool/main/s/scgi/libapache2-mod-scgi_1.13-1.1_armhf.deb;;
		armel)
			wget http://ftp.debian.org/debian/pool/main/s/scgi/libapache2-mod-scgi_1.13-1.1_armel.deb;;
		arm64)
			wget http://ftp.debian.org/debian/pool/main/s/scgi/libapache2-mod-scgi_1.13-1.1_arm64.deb;;
		amd64)
			wget http://mirrors.kernel.org/ubuntu/pool/universe/s/scgi/libapache2-mod-scgi_1.13-1.1build1_amd64.deb;;
		esac

		echo "${CYAN}Install scgi${NORMAL}"
		dpkg -i libapache2*.deb
		rm -f libapache2*.deb
	else
		echo "${CYAN}Install scgi${NORMAL}"
		apt-get -yqq install libapache2-mod-scgi
	fi
	CHECKLASTRC
}

# Function rtorrent
function INSTALL_RTORRENT {
	# Download and install rtorrent
	echo "${CYAN}Install rtorrent${NORMAL}"
	apt-get -yqq install rtorrent
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
network.scgi.open_port = 127.0.0.1:5000

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

# Function for installing rutorrent and plugins
function INSTALL_RUTORRENT {
	# Installing rutorrent.
	echo "${CYAN}Installing rutorrent${NORMAL}"
	echo "${YELLOW}Downloading package${NORMAL}"
	curl -L https://github.com/Novik/ruTorrent/archive/refs/tags/$RUTORRENTVERSION.zip -o rutorrent.zip
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
		rm -r /var/www/rutorrent
	fi

	echo "${YELLOW}Deactivate not supported plugins${NORMAL}"
	# Deactivate not supported plugins
	# not supported: _cloudflare, screenshots, spectrogram
	# not possible by folder rights: rutracker_check
	# removed since it's deprecated: geoip
	# not used since XMLRPC is used: rpc, httprpc
	PLUGINS=("_cloudflare" "screenshots" "spectrogram" "rutracker_check" "geoip" "rpc" "httprpc")
	for PLUGIN in ${PLUGINS[@]}
	do
		sed -i '$a['"$PLUGIN"']' rutorrent/conf/plugins.ini
		sed -i '$aenabled = no' rutorrent/conf/plugins.ini
		sed -i '$a\\' rutorrent/conf/plugins.ini
	done

	# Changeing SCGI mount point in rutorrent config.
	echo "${YELLOW}Changing SCGI mount point${NORMAL}"
	sed -i "s/\/RPC2/\/rutorrent\/RPC2/g" rutorrent/conf/config.php
	CHECKLASTRC

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

# Function for configuring apache
function CONFIGURE_APACHE {
	echo "${CYAN}Configuring apache${NORMAL}"
	# Creating self-signed certs
	echo "${YELLOW}Creating self-signed certificate${NORMAL}"
	openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -subj "/OU=Bercik rt-auto-install seedbox"  -keyout /etc/ssl/private/rutorrent-selfsigned.key -out /etc/ssl/certs/rutorrent-selfsigned.crt

	if ! grep -q "^ServerName$" /etc/apache2/apache2.conf
	then
		echo "ServerName localhost" >> /etc/apache2/apache2.conf;
	fi

	a2enmod ssl
	a2enmod rewrite

	# Creating Apache virtual host
	echo "${YELLOW}Creating apache vhost${NORMAL}"
	if [ ! -f /etc/apache2/sites-available/rutorrent.conf ]
	then
		cat > "/etc/apache2/sites-available/rutorrent.conf" <<-EOF
<VirtualHost *:80>
    ServerAlias *
    RewriteEngine on
    RewriteRule ^/(.*) https://%{HTTP_HOST}/\$1 [NC,R=301,L]
</VirtualHost>

<IfModule mod_ssl.c>
    <VirtualHost *:443>
        #ServerName  www.example.com
        DocumentRoot /var/www/

        LogLevel info ssl:warn
        ErrorLog /var/log/apache2/ssl_error.log
        CustomLog /var/log/apache2/ssl_access.log common
        SCGIMount /rutorrent/RPC2 127.0.0.1:5000

        <Directory "/var/www/rutorrent">
            AuthName "Tits or GTFO"
            AuthType Basic
            Require valid-user
            AuthUserFile /var/www/rutorrent/.htpasswd
        </Directory>

        SSLEngine on
        SSLCertificateFile /etc/ssl/certs/rutorrent-selfsigned.crt
        SSLCertificateKeyFile /etc/ssl/private/rutorrent-selfsigned.key
    </VirtualHost>
</IfModule>
EOF

		a2dissite 000-default.conf
		a2ensite rutorrent.conf
		CHECKLASTRC

		systemctl restart apache2.service
	fi

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
	apt-get -yqq install irssi libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libjson-perl libjson-xs-perl libxml-libxslt-perl php-xml

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

	systemctl restart apache2.service
}

# Function for showing the end result when install is complete
function INSTALL_COMPLETE {
	HEADER
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
	ext=$(curl -s https://ipv4.icanhazip.com/)

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

function MENU() {
	while true
	do
		HEADER
		echo " ${BOLD}    rTorrent version:${NORMAL} ${RED} $RTVERSION ${NORMAL}"
		echo " ${BOLD}  libTorrent version:${NORMAL} ${RED} $LIBTORRENTVERSION ${NORMAL}"
		echo " ${BOLD}   ruTorrent version:${NORMAL} ${RED} $RUTORRENTVERSION ${NORMAL}"
		echo " ${BOLD}      Script version:${NORMAL} ${RED} $SCRIPTVERSION ${NORMAL}"
		echo " ${BOLD}Script last modified:${NORMAL} ${RED} $LASTMODIFIED ${NORMAL}"
		#echo " Remember to visit https://github.com/Bercik1337/rt-auto-install ${NORMAL}"
		echo
		echo " ${BOLD}rTorrent user:${NORMAL}${GREEN} $RTORRENT_USER${NORMAL}"
		echo -n " ${BOLD}ruTorrent user(s):${NORMAL}${GREEN}"
		LIST_WEB_USERS
		echo
		echo "${NORMAL}"
		echo " [1] - Change rTorrent user"
		echo " [2] - Add another ruTorrent user"
		echo " [c] - Show Changelog"
		echo " [t] - Show TODO"
		echo " [p] - Change rTorrent Port-Range [act: ${GREEN}$PORT_RANGE${NORMAL}]"
		echo " [0] - Start installation"
		echo " [a] - Start installation with autodl-irssi"
		echo " [q] - Quit"
		echo
		echo -n "${GREEN}>>${NORMAL} "
		read input

		case "$input" in
		1)
			HEADER
			SET_RTORRENT_USER;;
		2)
			HEADER
			SET_WEB_USER;;
		c)
			HEADER
			curl -sL https://raw.githubusercontent.com/Bercik1337/rt-auto-install/master/Changelog | sed "s/- - -.*/- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - /" | head -n 17
			read -rsp $'Press any key to continue...' -n1 ke;;
		t)
			HEADER
			curl -sL https://raw.githubusercontent.com/Bercik1337/rt-auto-install/master/TODO | sed "s/- - -.*/- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - /" | head -n 17
			read -rsp $'Press any key to continue...' -n1 ke;;
		p)
			HEADER
			SET_RT_PORT;;
		0|a)
			APT_DEPENDENCIES
			INSTALL_SCGI
			INSTALL_RTORRENT
			INSTALL_RUTORRENT
			CONFIGURE_APACHE
			if [[ $input == "a" ]]
			then
				AUTODL-IRSSI
			fi
			clear -x
			INSTALL_COMPLETE
			break;;
		q)
			break;;
		esac
	done
}

function START() {
	CHECK_ROOT
	DETECTOS
	APACHE_UTILS
	HEADER
	LICENSE
	echo
	WAIT_A_MINUTE
	HEADER
	SET_RTORRENT_USER
	echo
	SET_WEB_USER
	MENU
	tput sgr0
}

START
