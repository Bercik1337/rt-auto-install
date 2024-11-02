
# Rtorrent + Rutorrent Auto Install Script by Bercik
### Modern script for automatic rtorrent, rutorrent installation under Linux.
	Makes your system seedbox ready in minutes!


![Logo](https://i.imgur.com/KtvJriL.jpg)

## News

**Current version** v2.2 released 2024/12/25

	Added support for batch mode (unattended install)

For details, always go to Changelog.

## Features ##

* This script performs automatic installation of rTorrent (BitTorrent client) and ruTorrent(web based GUI).
* It detects your OS and uses most recent version of rT available in repository of your Linux distribution.
* Uses SINGLE file for all supported operating systems.
* Gives menu-driven guidance when creating username.
* It's actively developed and I'm not planning to drop it like others did :P

## Supported operating systems ##

| Distro    | Manual installation (default) | Batch Support verified |
| -------- | ------- | ------- |
| Ubuntu 24.04 Noble Numbat | ✅ |  ✅ |
| Ubuntu 23.10 Mantic Minotaur | ✅ | ✅ |
| Ubuntu 23.04 Lunar Lobster | ✅ | ✅ |
| Ubuntu 22.04 Jammy Jellyfish | ✅ | ✅ |
| Ubuntu 20.04 Focal Fossa | ✅ | ✅ |
| Debian 12    Bookworm | ✅ | ✅ |
| Debian 11    Bullseye | ✅ | ✅ |
| ~~Raspbian 10  Buster~~| see #66  |  |
| Mint   22    Wilma | in progress |  |
| Mint   21.3  Virginia | in progress |  |
| Mint   21.2  Victoria | in progress |  |
| Mint   21.1  Vera | in progress |  |
| Mint   21    Vanessa | ✅ |  |
| Mint   20.3  Una | ✅ |  |
| Mint   20.2  Uma | ✅ |  |
| Mint   20.1  Ulyssa | ✅ |  |
| Mint   20    Ulyana | ✅ |  |
| Others    | in progress    |

More to come, see TODO.

## What the scripts does ##
In the installation process you have to choose a system user to run rtorrent.
Also you will get the opportunity of installing a total of 46 plugins. See list further down.
The script add a init script that makes rtorrent start, at a possible reboot, in the
given username's screen/tmux session. Use "service rtorrent start" and
"service rtorrent stop" to start and stop rtorrent respectively.

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


## Batch mode for advanced users
Since v2.2 script supports automatic deploment using batch mode. You can provide all necessary parameters to install entire environment. Excellent for deploying seedboxes or to combine with cloud-init.

In future CI/CD pipeline for automated tests is planned (under GitLab).
Automated installation has been CONFIRMED to be 100% working with these distros:


Try it yourself:
`sudo ./Rt-Install-minimal -f -b  -u ubuntu -r rutorrent -p rupassword -o ubu2004`
`sudo ./Rt-Install-minimal -f -b  -u ubuntu -r rutorrent -p rupassword -o deb11bullseye`

To see more info about batch parameters: `./Rt-Install-minimal -h`

