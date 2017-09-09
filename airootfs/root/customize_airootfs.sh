#!/bin/bash

USER="liveuser"
OSNAME="Namib"

function initFunc() {
	set -e -u
	umask 022
}

function localeGenFunc() {
	## Set locales
	sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
	locale-gen
}

function setTimeZoneAndClockFunc() {
	## Timezone
	ln -sf /usr/share/zoneinfo/UTC /etc/localtime

	## Set clock to UTC
	hwclock --systohc --utc
}

function setDefaultsFunc() {
	## Set default Browser
	export _BROWSER=firefox
	echo "BROWSER=/usr/bin/${_BROWSER}" >> /etc/environment
	echo "BROWSER=/usr/bin/${_BROWSER}" >> /etc/profile

	## Set Nano Editor
	export _EDITOR=nano
	echo "EDITOR=${_EDITOR}" >> /etc/environment
	echo "EDITOR=${_EDITOR}" >> /etc/profile
}

function initkeysFunc() {
	## Setup Pacman
	pacman-key --init archlinux
	pacman-key --populate archlinux
}

function fixPermissionsFunc() {
	## Add missing /media directory
	mkdir -p /media
	chmod 755 -R /media

	## Fix permissions
	chown root:root /usr
	chmod 755 /etc
}

function enableServicesFunc() {
	systemctl enable org.cups.cupsd.service
	systemctl enable avahi-daemon.service
	systemctl enable vboxservice.service
	systemctl enable bluetooth.service
	systemctl enable haveged
	systemctl enable systemd-networkd.service
	systemctl enable systemd-resolved.service
	systemctl -fq enable NetworkManager.service
	systemctl mask systemd-rfkill@.service
	systemctl set-default graphical.target
}

function enableCalamaresAutostartFunc() {
	## Enable Calamares Autostart
	mkdir -p /home/liveuser/.config/autostart
	mkdir -p /home/liveuser/Desktop
	ln -s /usr/share/applications/calamares.desktop /home/liveuser/.config/autostart/calamares.desktop
	ln -s /usr/share/applications/calamares.desktop /home/liveuser/Desktop/calamares.desktop
	chmod +rx /home/liveuser/.config/autostart/calamares.desktop
	chmod +rx /home/liveuser/Desktop/calamares.desktop
	chown liveuser /home/liveuser/.config/autostart/calamares.desktop
	chown liveuser /home/liveuser/Desktop/calamares.desktop
	chown liveuser /home/liveuser/.config/
	chown liveuser /home/liveuser/Desktop/
}

function fixWifiFunc() {
	## Wifi not available with networkmanager (BugFix)
	su -c 'echo "" >> /etc/NetworkManager/NetworkManager.conf'
	su -c 'echo "[device]" >> /etc/NetworkManager/NetworkManager.conf'
	su -c 'echo "wifi.scan-rand-mac-address=no" >> /etc/NetworkManager.conf'
}

function fontFix() {
	## To disable scaling of bitmap fonts (which often makes them blurry)
	rm -rf /etc/fonts/conf.d/10-scale-bitmap-fonts.conf
}

function configRootUserFunc() {
	usermod -s /usr/bin/bash root
	echo 'export PROMPT_COMMAND=""' >> /root/.bashrc
	chmod 700 /root
}

function createLiveUserFunc() {
	## Add groups autologin and nopasswdlogin (for lightdm autologin)
	groupadd -r autologin
	groupadd -r nopasswdlogin

	## Add liveuser
	id -u $USER &>/dev/null || useradd -m $USER -g users -G "adm,audio,floppy,log,network,rfkill,scanner,storage,optical,autologin,nopasswdlogin,power,wheel"
    	passwd -d $USER
	echo 'Live User Created'
}

function editOrCreateConfigFilesFunc() {
	## Locale
    	echo "LANG=en_US.UTF-8" > /etc/locale.conf
    	echo "LC_COLLATE=C" >> /etc/locale.conf

    	## Vconsole
    	echo "KEYMAP=us" > /etc/vconsole.conf
	echo "FONT=" >> /etc/vconsole.conf

	## Hostname
	echo "namib" > /etc/hostname

	sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
	sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf
}

function upgradeSystem() {
	pacman -Syuu --noconfirm	
}

function syncPacman() {
	pacman -Syy	
}

function iconCache() {
	gtk-update-icon-cache -f -q '/usr/share/icons/Arc'	
}



initFunc
initkeysFunc
localeGenFunc
setTimeZoneAndClockFunc
editOrCreateConfigFilesFunc
configRootUserFunc
createLiveUserFunc
setDefaultsFunc
enableCalamaresAutostartFunc
enableServicesFunc
fontFix
fixWifiFunc
fixPermissionsFunc
initkeysFunc
syncPacman
upgradeSystem
dconf update ## Apply dconf settings
iconCache
