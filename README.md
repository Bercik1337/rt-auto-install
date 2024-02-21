
# Rtorrent + Rutorrent Auto Install Script by Bercik
### Modern script for automatic rtorrent, rutorrent installation under Linux.
	Makes your system seedbox ready in minutes!

![Logo](https://i.imgur.com/KtvJriL.jpg)

## News

**Current version** v2.1 released 2024/02/21

    * always use of the latest ruTorrent
    * no need to care about the distro version
    * remove unnecessary stuff
    * add support for arm* systems (scgi)
    * correcting external ipv4
    * deactivate not supportet plugins
    * redirect http to https
    * correct terminal colors
    * add autodl-irssi plugin (Rt-Install-minimal-new.bash)
    * update .rtorrent.rc to the new commands
    * fix changelog and todo view
    * put functions together for more order
    * make pre-installation packages fully silent
    * and a little bit there and there
    * now choose between apache2, nginx and lighttpd as webserver (Rt-Install-minimal-apache2_ngnix_lighttpd.bash)
    * create htaccess passwords now with openssl
    * remove ToDo-List from the Menu

## Features ##

* This script performs automatic installation of rTorrent (BitTorrent client) and ruTorrent(web based GUI).
* It detects your OS and uses most recent version of rT available in repository of your Linux distribution.
* Gives menu-driven guidance when creating username.
* This script is minimal inversiv to files and operating system
* Free choose between apache2, ngnix or lighttpd as webserver

## Supported operating systems ##

* **Debian**
* **Raspbian**
* **Ubuntu**
* **Mint**
* **LMDE**

## What the scripts does ##
In the installation process you have to choose a system user to run rtorrent. The script add a service that
makes rtorrent start, at a possible reboot, in the given username's tmux session. Use "systemctl rtorrent start"
and "systemctl rtorrent stop" to start and stop rtorrent respectively.

Run the script with sudo or as root
	
	git clone https://github.com/MarkusLange/rt-auto-install.git
	cd rt-auto-install
	sudo ./Rt-Install-minimal
	
	or now you can simply
	wget https://raw.githubusercontent.com/MarkusLange/rt-auto-install/master/Rt-Install-minimal
	for the version with autodl-irssi
	wget https://raw.githubusercontent.com/MarkusLange/rt-auto-install/master/Rt-Install-minimal-new.bash
	with all webservers to selection
	wget https://raw.githubusercontent.com/MarkusLange/rt-auto-install/master/Rt-Install-minimal-apache2_ngnix_lighttpd.bash
