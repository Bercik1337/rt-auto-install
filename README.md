
# Rtorrent + Rutorrent Auto Install Script by Bercik
### Modern script for automatic rtorrent, rutorrent installation under Linux.
	Makes your system seedbox ready in minutes!

![Logo](https://i.imgur.com/KtvJriL.jpg)

## News

**Current version** v2.0 released 2024/02/14

    * allways use of the latest ruTorrent
    * no need to care about the distro version
    * remove unnecessary stuff
    * add support for arm* systems (scgi)
    * correcting external ipv4
    * deactivate not supportet plugins
    * redirect http to https
    * correct terminal colors
    * add autodl-irssi plugins
    * update .rtorrent.rc to the new commands
    * fix changelog and todo view
    * and a little bit there and there

For details, always go to Changelog.

## Features ##

* This script performs automatic installation of rTorrent (BitTorrent client) and ruTorrent(web based GUI).
* It detects your OS and uses most recent version of rT available in repository of your Linux distribution.
* Gives menu-driven guidance when creating username.

## Supported operating systems ##

* **Debian 12    Bookworm**
* **Debian 11    Bullseye**
* **Debian 10    Buster**
* **Raspbian 10  Buster**
* **Ubuntu 22.10 Kinetic Kudu**
* **Ubuntu 22.04 Jammy Jellyfish**
* **Ubuntu 21.10 Impish Indri**
* **Ubuntu 21.04 Hirsute Hippo**
* **Ubuntu 20.10 Groovy Gorilla**
* **Ubuntu 20.04 Focal Fossa**
* **Ubuntu 19.10 Eoan Ermine**
* **Ubuntu 19.04 Disco Dingo**
* **Ubuntu 18.10 Cosmic Cuttlefish**
* **Ubuntu 18.04 Bionic Beaver**
* **Mint   21.1  Vera**
* **Mint   21    Vanessa**
* **Mint   20.3  Una**
* **Mint   20.2  Uma**
* **Mint   20.1  Ulyssa**
* **Mint   20    Ulyana**
* **Mint   19.3  Tricia**
* **Mint   19.2  Tina**
* **Mint   19.1  Tessa**
* **Mint   19    Tara**
* **LMDE   5     Elsie**

More to come, see TODO.

## What the scripts does ##
In the installation process you have to choose a system user to run rtorrent.
The script add a init script that makes rtorrent start, at a possible reboot, in the
given username's tmux session. Use "service rtorrent start" and
"service rtorrent stop" to start and stop rtorrent respectively.

Run the script with sudo or as root
	
	git clone https://github.com/MarkusLange/rt-auto-install.git
	cd rt-auto-install
	sudo ./Rt-Install-minimal
	
	or now you can simply wget https://raw.githubusercontent.com/MarkusLange/rt-auto-install/master/Rt-Install-minimal
