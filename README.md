
# Rtorrent + Rutorrent Auto Install Script by Bercik
### Modern script for automatic rtorrent, rutorrent installation under Linux.
	Makes your system seedbox ready in minutes!


![Logo](https://i.imgur.com/KtvJriL.jpg)

## News

**Current version** v2.0 released 2024/03/10

	Disabled support for non x86_64 systems (like ARM). More under #66
	Added support for Ubuntu 23.10 (Mantic Minotaur)
	Fixed chown warning

For details, always go to Changelog.

## Features ##

* This script performs automatic installation of rTorrent (BitTorrent client) and ruTorrent(web based GUI).
* It detects your OS and uses most recent version of rT available in repository of your Linux distribution.
* Uses SINGLE file for all supported operating systems.
* Gives menu-driven guidance when creating username.
* It's actively developed and I'm not planning to drop it like others did :P

## Supported operating systems ##

* **Debian 12    Bookworm**
* **Debian 11    Bullseye**
* **Debian 10    Buster**
* ~~Raspbian 10  Buster~~ 
* **Ubuntu 23.10 Mantic Minotaur**
* **Ubuntu 23.04 Lunar Lobster**
* **Ubuntu 22.04 Jammy Jellyfish**
* ~~Ubuntu 21.10 Impish Indri~~ 
* ~~Ubuntu 21.04 Hirsute Hippo~~ 
* ~~Ubuntu 20.10 Groovy Gorilla~~ 
* **Ubuntu 20.04 Focal Fossa**
* ~~Ubuntu 19.10 Eoan Ermine~~ 
* ~~Ubuntu 19.04 Disco Dingo~~ 
* ~~Ubuntu 18.10 Cosmic Cuttlefish~~ 
* **Ubuntu 18.04 Bionic Beaver**
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
Also you will get the opportunity of installing a total of 46 plugins. See list further down.
The script add a init script that makes rtorrent start, at a possible reboot, in the
given username's screen/tmux session. Use "service rtorrent-init start" and
"service rtorrent-init stop" to start and stop rtorrent respectively.

Promo
------------

[![rt-auto-install promo](https://img.youtube.com/vi/F0MvYg7bAqk/0.jpg)](https://youtu.be/F0MvYg7bAqk)

Screenshoot
------------

![Screenshot1](https://i.ibb.co/5R1YWtN/rt-main-menu.png)
![Screenshot2](https://i.ibb.co/GvB8Tdq/rt-complete.png)


Installation
------------

**Installation video**

[![rt-auto-install script youtube](https://img.youtube.com/vi/uBxfSg0blPM/0.jpg)](https://www.youtube.com/watch?v=uBxfSg0blPM)



Run the script with sudo or as root
	
	git clone https://github.com/Bercik1337/rt-auto-install.git
	cd rt-auto-install
	sudo ./Rt-Install-minimal
	
	or now you can simply wget https://raw.githubusercontent.com/Bercik1337/rt-auto-install/master/Rt-Install-minimal

FAQ
------------
### But _WHY_ if we have Docker version?
I took over abandoned installation script because author didn't want to develop it anymore. Excuse was that everything moved to Docker.

In my personal opinion that's a **bad move**, and no one else fixed script - so I did. Docker itself is not a bad idea, but I would like to see it in dynamic, scalable environments where it grows and shrinks depending on workload.

That's certainly NOT the case here. rtorrent is ran usually 24/7, does not work in cluster solutions or anything close to that. So sticking it into Docker is 1. waste of resources (CPU, disk) 2. Security risk (everything you'd normally have PLUS Docker problems).
I might be the only person using this script - so be it. No containers for this app.


### Support for more OSes? 
See TODO
