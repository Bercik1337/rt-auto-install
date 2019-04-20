
# Rtorrent + Rutorrent Auto Install Script by Bercik
### Modern script for automatic rtorrent, rutorrent installation under Linux.



## Types of installation 

* **minimal**
It uses packages from repository. No need to pull sources, compile or install development tools.

* **sources**
It behaves like original version of Patrick's script. Gets sources for each package and compiles them.

Please use `systemctl start rtorrent` and `systemctl stop rtorrent` instead of the service command.


## Supported operating systems ##
* **Debian 10 Buster**

More to come, see TODO.

## What the scripts does ##
In the installation process you have to choose a system user to run rtorrent.
Also you will get the opportunity of installing a total of 46 plugins. See list further down.
The script add a init script that makes rtorrent start, at a possible reboot, in the
given username's screen/tmux session. Use "service rtorrent-init start" and
"service rtorrent-init stop" to start and stop rtorrent respectively.


Installation
------------

Installation video - gonna record new clip

git clone https://github.com/Bercik1337/rt-auto-install.git

Run the script with sudo or as root

	cd Rtorrent-Auto-Install
	sudo ./Rt-Install-0.1-Debian10-Buster-minimal

FAQ
------------
### But why if we have Docker version?
I took over abandoned installation script because author didn't want to develop it anymore. Excuse was that everything moved to Docker.

In my personal opinion that's a **bad move**, and no one else fixed script - so I did. Docker itself is not a bad idea, but I would like to see it in dynamic, scalable environments where it grows and shrinks depending on workload.

That's certainly NOT the case here. rtorrent is ran usually 24/7, does not work in cluster solutions or anything close to that. So sticking it into Docker is 1. waste of resources (CPU, disk) 2. Security risk (everything you'd normally have PLUS Docker problems).
I might be the only person using this script - so be it. No containers for this app.

### Where is the -sources version
Getting there...

### Support for more OSes? 
See TODO
