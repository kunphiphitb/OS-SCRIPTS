#!/bin/bash
# ================================
#
# อัพเดทระบบ
apt-get update; apt-get -y upgrade;
if [ ! -e /usr/bin/curl ]; then
    apt-get -y update && apt-get -y upgrade
	apt-get -y install curl
fi
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(curl -4 icanhazip.com)
if [ $MYIP = "" ]; then
   MYIP=`ifconfig | grep 'inet addr:' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d: -f2 | awk '{ print $1}' | head -1`;
fi
MYIP2="s/xxxxxxxxx/$MYIP/g";
cd

# ตั้งเวลาในประเทศไทย
ln -fs /usr/share/zoneinfo/Asia/Bangkok /etc/localtime

# ปิดการใช้งาน ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# เพิ่ม DNS ipv4
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
sed -i '$ i\echo "nameserver 8.8.8.8" > /etc/resolv.conf' /etc/rc.local
sed -i '$ i\echo "nameserver 8.8.4.4" >> /etc/resolv.conf' /etc/rc.local

# ติดตั้งแพ็คเกตที่จำเป็น 
apt-get -y install wget;
apt-get -y install ufw;
apt-get -y install sudo;

# เพิ่มฐานข้อมูล และติดตั้ง
echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.4 main" > /etc/apt/sources.list.d/mongodb-org-3.4.list
echo "deb http://repo.pritunl.com/stable/apt jessie main" > /etc/apt/sources.list.d/pritunl.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 0C49F3730359A14518585931BC711F9BA15703C6
apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A
cat > /etc/apt/sources.list <<-END
deb http://security.debian.org/ jessie/updates main contrib non-free
deb-src http://security.debian.org/ jessie/updates main contrib non-free
deb http://http.us.debian.org/debian jessie main contrib non-free
deb http://packages.dotdeb.org jessie all
deb-src http://packages.dotdeb.org jessie all
END
apt-get update;
apt-get --assume-yes install pritunl mongodb-org
systemctl start mongod pritunl
systemctl enable mongod pritunl
wget "http://www.dotdeb.org/dotdeb.gpg"
cat dotdeb.gpg | apt-key add -;rm dotdeb.gpg

# ถอนการติดตั้ง unused
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;
apt-get -y purge sendmail*
apt-get -y remove sendmail*

# install webserver
apt-get -y install nginx php5-fpm php5-cli

# install essential package
echo "mrtg mrtg/conf_mods boolean true" | debconf-set-selections
apt-get -y install bmon iftop htop nmap axel nano iptables traceroute sysv-rc-conf dnsutils bc nethogs vnstat less screen psmisc apt-file whois ngrep mtr git zsh mrtg snmp snmpd snmp-mibs-downloader unzip unrar rsyslog debsums rkhunter
apt-get -y install build-essential
apt-get -y install libio-pty-perl libauthen-pam-perl apt-show-versions

# disable exim
service exim4 stop
sysv-rc-conf exim4 off

# update apt-file
apt-file update

# setting vnstat
vnstat -u -i eth0
service vnstat restart

# install screenfetch
cd
cat > /usr/bin/screenfetch <<-END
#!/usr/bin/env bash

# screenFetch - a CLI Bash script to show system/theme info in screenshots

# Copyright (c) 2010-2016 Brett Bohnenkamper <kittykatt@kittykatt.us>

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Yes, I do realize some of this is horribly ugly coding. Any ideas/suggestions would be
# appreciated by emailing me or by stopping by http://github.com/KittyKatt/screenFetch. You
# could also drop in on the IRC channel at irc://irc.rizon.net/screenFetch.
# to put forth suggestions/ideas. Thank you.

# Requires: bash 4.0+
# Optional dependencies: xorg-xdpyinfo (resoluton detection)
#                        scrot (screenshot taking)
#                        curl (screenshot uploading)


LANG=C
LANGUAGE=C
LC_ALL=C

scriptVersion="3.7.0"

######################
# Settings for fetcher
######################

# This setting controls what ASCII logo is displayed.
# distro="Linux"

# This sets the information to be displayed. Available: distro, Kernel, DE, WM, Win_theme, Theme, Icons, Font, Background, ASCII. To get just the information, and not a text-art logo, you would take "ASCII" out of the below variable.
#display="distro host kernel uptime pkgs shell res de wm wmtheme gtk disk cpu gpu mem"
valid_display=( distro host kernel uptime pkgs shell res de wm wmtheme gtk disk cpu gpu mem )
display=( distro host kernel uptime pkgs shell res de wm wmtheme gtk cpu gpu mem )
# Display Type: ASCII or Text
display_type="ASCII"
# Plain logo
display_logo="no"

# Colors to use for the information found. These are set below according to distribution. If you would like to set your OWN color scheme for these, uncomment the lines below and edit them to your heart's content.
# textcolor="\e[0m"
# labelcolor="\e[1;34m"

# WM & DE process names
# Removed WM's: compiz
wmnames=( fluxbox openbox blackbox xfwm4 metacity kwin twin icewm pekwm flwm flwm_topside fvwm dwm awesome wmaker stumpwm musca xmonad.* i3 ratpoison scrotwm spectrwm wmfs wmii beryl subtle e16 enlightenment sawfish emerald monsterwm dminiwm compiz Finder herbstluftwm howm notion bspwm cinnamon 2bwm echinus swm budgie-wm dtwm 9wm chromeos-wm deepin-wm sway )
denames=( gnome-session xfce-mcs-manage xfce4-session xfconfd ksmserver lxsession lxqt-session gnome-settings-daemon mate-session mate-settings-daemon Finder deepin )

# Screenshot Settings
# This setting lets the script know if you want to take a screenshot or not. 1=Yes 0=No
screenshot=
# This setting lets the script know if you want to upload the screenshot to a filehost. 1=Yes 0=No
upload=
# This setting lets the script know where you would like to upload the file to. Valid hosts are: teknik, mediacrush, imgur, hmp, and a configurable local.
uploadLoc=
# You can specify a custom screenshot command here. Just uncomment and edit. Otherwise, we'll be using the default command: scrot -cd3.
# screenCommand="scrot -cd5"
shotfile=$(printf "screenFetch-`date +'%Y-%m-%d_%H-%M-%S'`.png")

# Verbose Setting - Set to 1 for verbose output.
verbosity=

#############################################
#### CODE No need to edit past here CODE ####
#############################################

#########################################
# Static Variables and Common Functions #
#########################################
c0="\033[0m" # Reset Text
bold="\033[1m" # Bold Text
underline="\033[4m" # Underline Text
display_index=0

# User options
gtk_2line="no"

# Static Color Definitions
colorize () {
	printf "\033[38;5;$1m"
}
getColor() {
	if [[ -n "$1" ]]; then
		if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
			if [[ ${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -gt 1 ]] || [[ ${BASH_VERSINFO[0]} -gt 4 ]]; then
				tmp_color=${1,,}
			else
				tmp_color="$(tr '[:upper:]' '[:lower:]' <<< ${1})"
			fi
		else
			tmp_color="$(tr '[:upper:]' '[:lower:]' <<< ${1})"
		fi
		case "${tmp_color}" in
			'black')		color_ret='\033[0m\033[30m';;
			'red')			color_ret='\033[0m\033[31m';;
			'green')		color_ret='\033[0m\033[32m';;
			'brown')		color_ret='\033[0m\033[33m';;
			'blue')			color_ret='\033[0m\033[34m';;
			'purple')		color_ret='\033[0m\033[35m';;
			'cyan')			color_ret='\033[0m\033[36m';;
			'light grey')	color_ret='\033[0m\033[37m';;
			'dark grey')	color_ret='\033[0m\033[1;30m';;
			'light red')	color_ret='\033[0m\033[1;31m';;
			'light green')	color_ret='\033[0m\033[1;32m';;
			'yellow')		color_ret='\033[0m\033[1;33m';;
			'light blue')	color_ret='\033[0m\033[1;34m';;
			'light purple')	color_ret='\033[0m\033[1;35m';;
			'light cyan')	color_ret='\033[0m\033[1;36m';;
			'white')		color_ret='\033[0m\033[1;37m';;
			# Some 256 colors
			'orange') color_ret="$(colorize '202')";;
			# HaikuOS
			'black_haiku') color_ret="$(colorize '7')";;
		esac
		[[ -n "${color_ret}" ]] && echo "${color_ret}"
	else
		:
	fi
}

verboseOut() {
	if [[ "$verbosity" -eq "1" ]]; then
		printf "\033[1;31m:: \033[0m$1\n"
	fi
}

errorOut() {
	printf "\033[1;37m[[ \033[1;31m! \033[1;37m]] \033[0m$1\n"
}
stderrOut() {
	while IFS='' read -r line; do printf "\033[1;37m[[ \033[1;31m! \033[1;37m]] \033[0m${line}\n"; done
}


####################
#  Color Defines
####################

colorNumberToCode() {
	number="$1"
	if [[ "${number}" == "na" ]]; then
		unset code
	elif [[ $(tput colors) -eq "256" ]]; then
		code=$(colorize "${number}")
	else
		case "$number" in
			0|00) code=$(getColor 'black');;
			1|01) code=$(getColor 'red');;
			2|02) code=$(getColor 'green');;
			3|03) code=$(getColor 'brown');;
			4|04) code=$(getColor 'blue');;
			5|05) code=$(getColor 'purple');;
			6|06) code=$(getColor 'cyan');;
			7|07) code=$(getColor 'light grey');;
			8|08) code=$(getColor 'dark grey');;
			9|09) code=$(getColor 'light red');;
			  10) code=$(getColor 'light green');;
			  11) code=$(getColor 'yellow');;
			  12) code=$(getColor 'light blue');;
			  13) code=$(getColor 'light purple');;
			  14) code=$(getColor 'light cyan');;
			  15) code=$(getColor 'white');;
			*) unset code;;
		esac
	fi
	echo -n "${code}"
}


detectColors() {
	my_colors=$(sed 's/^,/na,/;s/,$/,na/;s/,/ /' <<< "${OPTARG}")
	my_lcolor=$(awk -F' ' '{print $1}' <<< "${my_colors}")
	my_lcolor=$(colorNumberToCode "${my_lcolor}")

	my_hcolor=$(awk -F' ' '{print $2}' <<< "${my_colors}")
	my_hcolor=$(colorNumberToCode "${my_hcolor}")
}

supported_distros="Alpine Linux, Antergos, Arch Linux (Old and Current Logos), BLAG, BunsenLabs, CentOS, Chakra, Chapeau, Chrome OS, Chromium OS, CrunchBang, CRUX, Debian, Deepin, Devuan, Dragora, elementary OS, Evolve OS, Exherbo, Fedora, Frugalware, Fuduntu, Funtoo, Gentoo, gNewSense, Jiyuu Linux, Kali Linux, KaOS, KDE neon, Kogaion, Korora, LinuxDeepin, Linux Mint, LMDE, Logos, Mageia, Mandriva/Mandrake, Manjaro, Mer, Netrunner, NixOS, openSUSE, Oracle Linux, Parabola GNU/Linux-libre, PCLinuxOS, PeppermintOS, Qubes OS, Raspbian, Red Hat Enterprise Linux, Sabayon, SailfishOS, Scientific Linux, Slackware, Solus, SparkyLinux, SteamOS, SUSE Linux Enterprise, TinyCore, Trisquel, Ubuntu, Viperr and Void."
supported_other="Dragonfly/Free/Open/Net BSD, Haiku, Mac OS X, Windows+Cygwin and Windows+MSYS."
supported_dms="KDE, GNOME, Unity, Xfce, LXDE, Cinnamon, MATE, Deepin, CDE, RazorQt and Trinity."
supported_wms="2bwm, 9wm, Awesome, Beryl, Blackbox, Cinnamon, chromeos-wm, Compiz, deepin-wm, dminiwm, dwm, dtwm, E16, E17, echinus, Emerald, FluxBox, FLWM, FVWM, herbstluftwm, howm, IceWM, KWin, Metacity, monsterwm, Musca, Gala, Mutter, Muffin, Notion, OpenBox, PekWM, Ratpoison, Sawfish, ScrotWM, SpectrWM, StumpWM, subtle, sway, TWin, WindowMaker, WMFS, wmii, Xfwm4, XMonad and i3."

displayHelp() {
	printf "${underline}Usage${c0}:\n"
	printf "  ${0} [OPTIONAL FLAGS]\n\n"
	printf "screenFetch - a CLI Bash script to show system/theme info in screenshots.\n\n"
	printf "${underline}Supported GNU/Linux Distributions${c0}:\n"
	printf "${supported_distros}" | fold -s | sed 's/^/\t/g'
	printf "\n\n"
	printf "${underline}Other Supported Systems${c0}:\n"
	printf "${supported_other}" | fold -s | sed 's/^/\t/g'
	printf "\n\n"
	printf "${underline}Supported Desktop Managers${c0}:\n"
	printf "${supported_dms}" | fold -s | sed 's/^/\t/g'
	printf "\n\n"
	printf "${underline}Supported Window Managers${c0}:\n"
	printf "${supported_wms}" | fold -s | sed 's/^/\t/g'
	printf "\n\n"
	printf "${underline}Options${c0}:\n"
	printf "   ${bold}-v${c0}                 Verbose output.\n"
	printf "   ${bold}-o 'OPTIONS'${c0}       Allows for setting script variables on the\n"
	printf "                      command line. Must be in the following format...\n"
	printf "                      'OPTION1=\"OPTIONARG1\";OPTION2=\"OPTIONARG2\"'\n"
	printf "   ${bold}-d '+var;-var;var'${c0} Allows for setting what information is displayed\n"
	printf "                      on the command line. You can add displays with +var,var. You\n"
	printf "                      can delete displays with -var,var. Setting without + or - will\n"
	printf "                      set display to that explicit combination. Add and delete statements\n"
	printf "                      may be used in conjunction by placing a ; between them as so:\n"
	printf "                      +var,var,var;-var,var.\n"
	printf "   ${bold}-n${c0}                 Do not display ASCII distribution logo.\n"
	printf "   ${bold}-L${c0}                 Display ASCII distribution logo only.\n"
	printf "   ${bold}-N${c0}                 Strip all color from output.\n"
	printf "   ${bold}-t${c0}                 Truncate output based on terminal width (Experimental!).\n"
	printf "   ${bold}-p${c0}                 Portrait output.\n"
	printf "   ${bold}-s [-u IMGHOST]${c0}    Using this flag tells the script that you want it\n"
	printf "                      to take a screenshot. Use the -u flag if you would like\n"
	printf "                      to upload the screenshots to one of the pre-configured\n"
	printf "                      locations. These include: teknik, imgur, mediacrush and hmp.\n"
	printf "   ${bold}-c string${c0}          You may change the outputted colors with -c. The format is\n"
	printf "                      as follows: [0-9][0-9],[0-9][0-9]. The first argument controls the\n"
	printf "                      ASCII logo colors and the label colors. The second argument\n"
	printf "                      controls the colors of the information found. One argument may be\n"
	printf "                      used without the other.\n"
	printf "   ${bold}-a 'PATH'${c0}          You can specify a custom ASCII art by passing the path\n"
	printf "                      to a Bash script, defining \`startline\` and \`fulloutput\`\n"
	printf "                      variables, and optionally \`labelcolor\` and \`textcolor\`.\n"
	printf "                      See the \`asciiText\` function in the source code for more\n"
	printf "                      informations on the variables format.\n"
	printf "   ${bold}-S 'COMMAND'${c0}       Here you can specify a custom screenshot command for\n"
	printf "                      the script to execute. Surrounding quotes are required.\n"
	printf "   ${bold}-D 'DISTRO'${c0}        Here you can specify your distribution for the script\n"
	printf "                      to use. Surrounding quotes are required.\n"
	printf "   ${bold}-A 'DISTRO'${c0}        Here you can specify the distribution art that you want\n"
	printf "                      displayed. This is for when you want your distro\n"
	printf "                      detected but want to display a different logo.\n"
	printf "   ${bold}-E${c0}                 Suppress output of errors.\n"
	printf "   ${bold}-V, --version${c0}      Display current script version.\n"
	printf "   ${bold}-h, --help${c0}         Display this help.\n"
}


displayVersion() {
	printf ${underline}"screenFetch"${c0}" - Version ${scriptVersion}\n"
	printf "Created by and licensed to Brett Bohnenkamper <kittykatt@kittykatt.us>\n"
	printf "OS X porting done almost solely by shrx (https://github.com/shrx) and John D. Duncan, III (https://github.com/JohnDDuncanIII).\n\n"
	printf "This is free software; see the source for copying conditions.  There is NO warranty; not even MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n"
}


#####################
# Begin Flags Phase
#####################

case $1 in
	--help) displayHelp; exit 0;;
	--version) displayVersion; exit 0;;
esac


while getopts ":hsu:evVEnLNtlS:A:D:o:Bc:d:pa:" flags; do
	case $flags in
		h) displayHelp; exit 0 ;;
		s) screenshot='1' ;;
		S) screenCommand="${OPTARG}" ;;
		u) upload='1'; uploadLoc="${OPTARG}" ;;
		v) verbosity=1 ;;
		V) displayVersion; exit 0 ;;
		E) errorSuppress='1' ;;
		D) distro="${OPTARG}" ;;
		A) asc_distro="${OPTARG}" ;;
		t) truncateSet='Yes' ;;
		n) display_type='Text' ;;
		L) display_type='ASCII'; display_logo='Yes' ;;
		o) overrideOpts="${OPTARG}" ;;
		c) detectColors "${OPTARGS}" ;;
		d) overrideDisplay="${OPTARG}" ;;
		N) no_color='1' ;;
		p) portraitSet='Yes' ;;
		a) art="${OPTARG}" ;;
		:) errorOut "Error: You're missing an argument somewhere. Exiting."; exit 1 ;;
		?) errorOut "Error: Invalid flag somewhere. Exiting."; exit 1 ;;
		*) errorOut "Error"; exit 1 ;;
	esac
done

###################
# End Flags Phase
###################


############################
# Override Options/Display
############################

if [[ "$overrideOpts" ]]; then
	verboseOut "Found 'o' flag in syntax. Overriding some script variables..."
	OLD_IFS="$IFS"
	IFS=";"
	for overopt in "${overrideOpts}"; do
		eval "${overrideOpts}"
	done
	IFS="$OLD_IFS"
fi


#########################
# Begin Detection Phase
#########################

# Distro Detection - Begin
detectdistro () {
	if [[ -z "${distro}" ]]; then
		distro="Unknown"
		# LSB Release Check
		if type -p lsb_release >/dev/null 2>&1; then
			# read distro_detect distro_release distro_codename <<< $(lsb_release -sirc)
			distro_detect=( $(lsb_release -sirc) )
			if [[ ${#distro_detect[@]} -eq 3 ]]; then
				distro_codename=${distro_detect[2]}
				distro_release=${distro_detect[1]}
				distro_detect=${distro_detect[0]}
			else
				for ((i=0; i<${#distro_detect[@]}; i++)); do
					if [[ ${distro_detect[$i]} =~ ^[[:digit:]]+((.[[:digit:]]+|[[:digit:]]+|)+)$ ]]; then
						distro_release=${distro_detect[$i]}
						distro_codename=${distro_detect[@]:$(($i+1)):${#distro_detect[@]}+1}
						distro_detect=${distro_detect[@]:0:${i}}
						break 1
					elif [[ ${distro_detect[$i]} =~ [Nn]/[Aa] || ${distro_detect[$i]} == "rolling" ]]; then
						distro_release=${distro_detect[$i]}
						distro_codename=${distro_detect[@]:$(($i+1)):${#distro_detect[@]}+1}
						distro_detect=${distro_detect[@]:0:${i}}
						break 1
					fi
				done
			fi
			case "${distro_detect}" in
				"CentOS"|"Chapeau"|"Deepin"|"Devuan"|"Fedora"|"gNewSense"|"Jiyuu Linux"|"Kogaion"|"Korora"|"Mageia"|"Netrunner"|"NixOS"|"Raspbian"|"Sabayon"|"Solus"|"SteamOS"|"Trisquel"|"Ubuntu")
					# no need to fix $distro/$distro_codename/$distro_release
					distro="${distro_detect}"
					;;
				"archlinux"|"Arch Linux"|"arch"|"Arch"|"archarm")
					distro="Arch Linux"
					distro_release="n/a"
					if grep -q 'antergos' /etc/os-release; then
						distro="Antergos"
						distro_release="n/a"
					fi
					if grep -q -i 'logos' /etc/os-release; then
						distro="Logos"
						distro_release="n/a"
					fi
					;;
				"BLAG")
					distro="BLAG"
					distro_more="$(head -n1 /etc/fedora-release)"
					;;
				"Chakra")
					distro="Chakra"
					distro_release=""
					;;
				"BunsenLabs")
					distro=$(source /etc/lsb-release; echo "$DISTRIB_ID")
					distro_release=$(source /etc/lsb-release; echo "$DISTRIB_RELEASE")
					distro_codename=$(source /etc/lsb-release; echo "$DISTRIB_CODENAME")
					;;
				"Debian")
					if [[ -f /etc/crunchbang-lsb-release || -f /etc/lsb-release-crunchbang ]]; then
						distro="CrunchBang"
						distro_release=$(awk -F'=' '/^DISTRIB_RELEASE=/ {print $2}' /etc/lsb-release-crunchbang)
						distro_codename=$(awk -F'=' '/^DISTRIB_DESCRIPTION=/ {print $2}' /etc/lsb-release-crunchbang)
					elif [[ -f /etc/os-release ]]; then
						if [[ "$(cat /etc/os-release)" =~ "Raspbian" ]]; then
							distro="Raspbian"
							distro_release=$(awk -F'=' '/^PRETTY_NAME=/ {print $2}' /etc/os-release)
						else
							distro="Debian"
						fi
					else
						distro="Debian"
					fi
					;;
				"elementary"|"elementary OS")
					distro="elementary OS"
					;;
				"EvolveOS")
					distro="Evolve OS"
					;;
				"KaOS"|"kaos")
					distro="KaOS"
					;;
				"frugalware")
					distro="Frugalware"
					distro_codename=null
					distro_release=null
					;;
				"Fuduntu")
					distro="Fuduntu"
					distro_codename=null
					;;
				"Gentoo")
					if [[ "$(lsb_release -sd)" =~ "Funtoo" ]]; then
						distro="Funtoo"
					else
						distro="Gentoo"
					fi
					;;
				"LinuxDeepin")
					distro="LinuxDeepin"
					distro_codename=null
					;;
				"Kali"|"Debian Kali Linux")
					distro="Kali Linux"
					if [[ "${distro_codename}" =~ "kali-rolling" ]]; then
						distro_codename="n/a"
						distro_release="n/a"
					fi
					;;
				"Lunar Linux"|"lunar")
					distro="Lunar Linux"
					;;
				"MandrivaLinux")
					distro="Mandriva"
					case "${distro_codename}" in
						"turtle"|"Henry_Farman"|"Farman"|"Adelie"|"pauillac")
							distro="Mandriva-${distro_release}"
							distro_codename=null
							;;
					esac
					;;
				"ManjaroLinux")
					distro="Manjaro"
					;;
				"Mer")
					distro="Mer"
					if [[ -f /etc/os-release ]]; then
						if grep -q 'SailfishOS' /etc/os-release; then
							distro="SailfishOS"
							distro_codename="$(grep 'VERSION=' /etc/os-release | cut -d '(' -f2 | cut -d ')' -f1)"
							distro_release="$(awk -F'=' '/^VERSION=/ {print $2}' /etc/os-release)"
						fi
					fi
					;;
				"neon"|"KDE neon")
					distro="KDE neon"
					distro_codename="n/a"
					distro_release="n/a"
					if [[ -f /etc/issue ]]; then
						if grep -q "^KDE neon" /etc/issue ; then
							distro_release="$(grep '^KDE neon' /etc/issue | cut -d ' ' -f3)"
						fi
					fi
					;;
				"Ol"|"ol"|"Oracle Linux")
					distro="Oracle Linux"
					[ -f /etc/oracle-release ] && distro_release="$(sed 's/Oracle Linux //' /etc/oracle-release)"
					;;
				"LinuxMint")
					distro="Mint"
					if [[ "${distro_codename}" == "debian" ]]; then
						distro="LMDE"
						distro_codename="n/a"
						distro_release="n/a"
					fi
					;;
				"openSUSE"|"openSUSE project"|"SUSE LINUX")
					distro="openSUSE"
					if [ -f /etc/os-release ]; then
						if [[ "$(cat /etc/os-release)" =~ "SUSE Linux Enterprise" ]]; then
							distro="SUSE Linux Enterprise"
							distro_codename="n/a"
							distro_release=$(awk -F'=' '/^VERSION_ID=/ {print $2}' /etc/os-release | tr -d '"')
						fi
					fi
					if [[ "${distro_codename}" == "Tumbleweed" ]]; then
						distro_release="n/a"
					fi
					;;
				"Parabola GNU/Linux-libre"|"Parabola")
					distro="Parabola GNU/Linux-libre"
					distro_codename="n/a"
					distro_release="n/a"
					;;
				"PCLinuxOS")
					distro="PCLinuxOS"
					distro_codename="n/a"
					distro_release="n/a"
					;;
				"Peppermint")
					distro="Peppermint"
					distro_codename=null
					;;
				"rhel")
					distro="Red Hat Enterprise Linux"
					;;
				"SailfishOS")
					distro="SailfishOS"
					if [[ -f /etc/os-release ]]; then
						distro_codename="$(grep 'VERSION=' /etc/os-release | cut -d '(' -f2 | cut -d ')' -f1)"
						distro_release="$(awk -F'=' '/^VERSION=/ {print $2}' /etc/os-release)"
					fi
					;;
				"Sparky"|"SparkyLinux")
					distro="SparkyLinux"
					;;
				"Viperr")
					distro="Viperr"
					distro_codename=null
					;;
				*)
					if [ "x$(printf "${distro_detect}" | od -t x1 | sed -e 's/^\w*\ *//' | tr '\n' ' ' | grep 'eb b6 89 ec 9d 80 eb b3 84 ')" != "x" ]; then
						distro="Red Star OS"
						distro_codename="n/a"
						distro_release=$(printf "${distro_release}" | grep -o '[0-9.]' | tr -d '\n')
					fi
					;;
			esac
			if [[ "${distro_detect}" =~ "RedHatEnterprise" ]]; then distro="Red Hat Enterprise Linux"; fi
			if [[ "${distro_detect}" =~ "SUSELinuxEnterprise" ]]; then distro="SUSE Linux Enterprise"; fi
			if [[ -n ${distro_release} && ${distro_release} != "n/a" ]]; then distro_more="$distro_release"; fi
			if [[ -n ${distro_codename} && ${distro_codename} != "n/a" ]]; then distro_more="$distro_more $distro_codename"; fi
		fi

		# Existing File Check
		if [ "$distro" == "Unknown" ]; then
			if [ $(uname -o 2>/dev/null) ]; then
				case "$(uname -o)" in
					"Cygwin")
						distro="Cygwin"
						fake_distro="${distro}"
					;;
					"Msys")
						distro="Msys"
						fake_distro="${distro}"
						distro_more="${distro} $(uname -r | head -c 1)"
					;;
					"Haiku")
						distro="Haiku"
						distro_more="$(uname -v | tr ' ' '\n' | grep 'hrev')"
					;;
					"GNU/Linux")
						if type -p crux >/dev/null 2>&1; then
							distro="CRUX"
							distro_more="$(crux | awk '{print $3}')"
						fi
						if type -p nixos-version >/dev/null 2>&1; then
							distro="NixOS"
							distro_more="$(nixos-version)"
						fi
					;;
				esac
			fi
			if [[ "${distro}" == "Cygwin" || "${distro}" == "Msys" ]]; then
				# https://msdn.microsoft.com/en-us/library/ms724832%28VS.85%29.aspx
				if [ "$(wmic os get version | grep -o '^\(6\.[23]\|10\)')" ]; then
					fake_distro="Windows - Modern"
				fi
			fi
			if [[ "${distro}" == "Unknown" ]]; then
				if [ -f /etc/os-release ]; then
					distrib_id=$(</etc/os-release);
					for l in $(echo $distrib_id); do
						if [[ ${l} =~ ^ID= ]]; then
							distrib_id=${l//*=}
							distrib_id=${distrib_id//\"/}
							break 1
						fi
					done
					if [[ -n ${distrib_id} ]]; then
						if [[ -n ${BASH_VERSINFO} && ${BASH_VERSINFO} -ge 4 ]]; then
							distrib_id=$(for i in ${distrib_id}; do echo -n "${i^} "; done)
							distro=${distrib_id% }
							unset distrib_id
						else
							distrib_id=$(for i in ${distrib_id}; do FIRST_LETTER=$(echo -n "${i:0:1}" | tr "[:lower:]" "[:upper:]"); echo -n "${FIRST_LETTER}${i:1} "; done)
							distro=${distrib_id% }
							unset distrib_id
						fi
					fi

					# Hotfixes
					[[ "${distro}" == "void" ]] && distro="Void"
					[[ "${distro}" == "evolveos" ]] && distro="Evolve OS"
					[[ "${distro}" == "antergos" ]] && distro="Antergos"
					[[ "${distro}" == "logos" ]] && distro="Logos"
					[[ "${distro}" == "Arch" || "${distro}" == "Archarm" || "${distro}" == "archarm" ]] && distro="Arch Linux"
					[[ "${distro}" == "elementary" ]] && distro="elementary OS"
					[[ "${distro}" == "Fedora" && -d /etc/qubes-rpc ]] && distro="qubes" # Inner VM
					[[ "${distro}" == "Ol" || "${distro}" == "ol" ]] && distro="Oracle Linux"
					if [[ "${distro}" == "Oracle Linux" ]] && [ -f /etc/oracle-release ]; then
						distro_more="$(sed 's/Oracle Linux //' /etc/oracle-release)"
					fi
					[[ "${distro}" == "rhel" ]] && distro="Red Hat Enterprise Linux"
					[[ "${distro}" == "Neon" ]] && distro="KDE neon"
					[[ "${distro}" == "SLED" || "${distro}" == "sled" || "${distro}" == "SLES" || "${distro}" == "sles" ]] && distro="SUSE Linux Enterprise"
					if [[ "${distro}" == "SUSE Linux Enterprise" ]] && [ -f /etc/os-release ]; then
						distro_more="$(awk -F'=' '/^VERSION_ID=/ {print $2}' /etc/os-release | tr -d '"')"
					fi
				fi
			fi

			if [[ "${distro}" == "Unknown" ]]; then
				if [[ "${OSTYPE}" == "linux-gnu" || "${OSTYPE}" == "linux" ]]; then
					if [ -f /etc/lsb-release ]; then
						LSB_RELEASE=$(</etc/lsb-release)
						distro=$(echo ${LSB_RELEASE} | awk 'BEGIN {
							distro = "Unknown"
						}
						{
							if ($0 ~ /[Uu][Bb][Uu][Nn][Tt][Uu]/) {
								distro = "Ubuntu"
								exit
							}
							else if ($0 ~ /[Mm][Ii][Nn][Tt]/ && $0 ~ /[Dd][Ee][Bb][Ii][Aa][Nn]/) {
								distro = "LMDE"
								exit
							}
							else if ($0 ~ /[Mm][Ii][Nn][Tt]/) {
								distro = "Mint"
								exit
							}
						} END {
							print distro
						}')
					fi
				fi
			fi

			if [[ "${distro}" == "Unknown" ]]; then
				if [[ "${OSTYPE}" == "linux-gnu" || "${OSTYPE}" == "linux" || "${OSTYPE}" == "gnu" ]]; then
					if [ -f /etc/arch-release ]; then distro="Arch Linux"
					elif [ -f /etc/chakra-release ]; then distro="Chakra"
					elif [ -f /etc/crunchbang-lsb-release ]; then distro="CrunchBang"
					elif [ -f /etc/debian_version ]; then
						if [ -f /etc/issue ]; then
							if grep -q "gNewSense" /etc/issue ; then
								distro="gNewSense"
							elif grep -q "^KDE neon" /etc/issue ; then
								distro="KDE neon"
								distro_more="$(cut -d ' ' -f3 /etc/issue)"
							else
								distro="Debian"
							fi
						fi
						if grep -q "Kali" /etc/debian_version ; then
							distro="Kali Linux"
						fi
					elif [ -f /etc/dragora-version ]; then distro="Dragora" && distro_more="$(cut -d, -f1 /etc/dragora-version)"
					elif [ -f /etc/evolveos-release ]; then distro="Evolve OS"
					elif [ -f /etc/exherbo-release ]; then distro="Exherbo"
					elif [ -f /etc/fedora-release ]; then
						if grep -q "Korora" /etc/fedora-release; then
							distro="Korora"
						elif grep -q "BLAG" /etc/fedora-release; then
							distro="BLAG"
							distro_more="$(head -n1 /etc/fedora-release)"
						else
							distro="Fedora"
						fi
					elif [ -f /etc/frugalware-release ]; then distro="Frugalware"
					elif [ -f /etc/gentoo-release ]; then
						if grep -q "Funtoo" /etc/gentoo-release ; then
							distro="Funtoo"
						else
							distro="Gentoo"
						fi
					elif [ -f /etc/kogaion-release ]; then distro="Kogaion"
					elif [ -f /etc/mageia-release ]; then distro="Mageia"
					elif [ -f /etc/mandrake-release ]; then
						if grep -q "PCLinuxOS" /etc/mandrake-release ; then
							distro="PCLinuxOS"
						else
							distro="Mandrake"
						fi
					elif [ -f /etc/mandriva-release ]; then
						if grep -q "PCLinuxOS" /etc/mandriva-release ; then
							distro="PCLinuxOS"
						else
							distro="Mandriva"
						fi
					elif [ -f /etc/NIXOS ]; then distro="NixOS"
					elif [ -f /etc/obarun-release ]; then distro="Obarun"
					elif [ -f /etc/oracle-release ]; then
						distro="Oracle Linux"
						distro_more="$(sed 's/Oracle Linux //' /etc/oracle-release)"
					elif [ -f /etc/SuSE-release ]; then
						distro="openSUSE"
						if [ -f /etc/os-release ]; then
							if [[ "$(cat /etc/os-release)" =~ "SUSE Linux Enterprise" ]]; then
								distro="SUSE Linux Enterprise"
								distro_more=$(awk -F'=' '/^VERSION_ID=/ {print $2}' /etc/os-release | tr -d '"')
							fi
						fi
						if [[ "${distro_more}" =~ "Tumbleweed" ]]; then distro_more="Tumbleweed"; fi
					elif [ -f /etc/pclinuxos-release ]; then distro="PCLinuxOS"
					elif [ -f /etc/redstar-release ]; then
						distro="Red Star OS"
						distro_more=$(grep -o '[0-9.]' /etc/redstar-release | tr -d '\n')
					elif [ -f /etc/redhat-release ]; then
						if grep -q "CentOS" /etc/redhat-release; then
							distro="CentOS"
						elif grep -q "PCLinuxOS" /etc/redhat-release; then
							distro="PCLinuxOS"
						elif [ "x$(od -t x1 /etc/redhat-release | sed -e 's/^\w*\ *//' | tr '\n' ' ' | grep 'eb b6 89 ec 9d 80 eb b3 84 ')" != "x" ]; then
							distro="Red Star OS"
							distro_more=$(grep -o '[0-9.]' /etc/redhat-release | tr -d '\n')
						else
							distro="Red Hat Enterprise Linux"
						fi
					elif [ -f /etc/slackware-version ]; then distro="Slackware"
					elif [ -f /usr/share/doc/tc/release.txt ]; then
						distro="TinyCore"
						distro_more="$(cat /usr/share/doc/tc/release.txt)"
					elif [ -f /etc/sabayon-edition ]; then distro="Sabayon"; fi
				else
					if [[ -x /usr/bin/sw_vers ]] && /usr/bin/sw_vers | grep -i "Mac OS X" >/dev/null; then
						distro="Mac OS X"
					elif [[ -f /var/run/dmesg.boot ]]; then
						distro=$(awk 'BEGIN {
							distro = "Unknown"
						}
						{
							if ($0 ~ /DragonFly/) {
								distro = "DragonFlyBSD"
								exit
							}
							else if ($0 ~ /FreeBSD/) {
								distro = "FreeBSD"
								exit
							}
							else if ($0 ~ /NetBSD/) {
								distro = "NetBSD"
								exit
							}
							else if ($0 ~ /OpenBSD/) {
								distro = "OpenBSD"
								exit
							}
						} END {
							print distro
						}' /var/run/dmesg.boot)
					fi
				fi
			fi

			if [[ "${distro}" == "Unknown" ]] && [[ "${OSTYPE}" == "linux-gnu" || "${OSTYPE}" == "linux" || "${OSTYPE}" == "gnu" ]]; then
				if [[ -f /etc/issue ]]; then
					distro=$(awk 'BEGIN {
						distro = "Unknown"
					}
					{
						if ($0 ~ /"LinuxDeepin"/) {
							distro = "LinuxDeepin"
							exit
						}
						else if ($0 ~ /"Obarun"/) {
							distro = "Obarun"
							exit
						}
						else if ($0 ~ /"Parabola GNU\/Linux-libre"/) {
							distro = "Parabola GNU/Linux-libre"
							exit
						}
						else if ($0 ~ /"Solus"/) {
							distro = "Solus"
							exit
						}
					} END {
						print distro
					}' /etc/issue)
				fi
			fi

			if [[ "${distro}" == "Unknown" ]] && [[ "${OSTYPE}" == "linux-gnu" || "${OSTYPE}" == "linux" || "${OSTYPE}" == "gnu" ]]; then
				if [[ -f /etc/system-release ]]; then
					if grep -q "Scientific Linux" /etc/system-release; then
						distro="Scientific Linux"
					elif grep -q "Oracle Linux" /etc/system-release; then
						distro="Oracle Linux"
					fi
				elif [[ -f /etc/lsb-release ]]; then
					if grep -q "CHROMEOS_RELEASE_NAME" /etc/lsb-release; then
						distro="$(awk -F'=' '/^CHROMEOS_RELEASE_NAME=/ {print $2}' /etc/lsb-release)"
						distro_more="$(awk -F'=' '/^CHROMEOS_RELEASE_VERSION=/ {print $2}' /etc/lsb-release)"
					fi
				fi
			fi
		fi
	fi

	if [[ -n ${distro_more} ]]; then
		distro_more="${distro} ${distro_more}"
	fi

	if [[ "${distro}" != "Haiku" ]]; then
		if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
			if [[ ${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -gt 1 ]] || [[ ${BASH_VERSINFO[0]} -gt 4 ]]; then
				distro=${distro,,}
			else
				distro="$(tr '[:upper:]' '[:lower:]' <<< ${distro})"
			fi
		else
			distro="$(tr '[:upper:]' '[:lower:]' <<< ${distro})"
		fi
	fi

	case $distro in
		alpine) distro="Alpine Linux" ;;
		antergos) distro="Antergos" ;;
		arch*linux*old) distro="Arch Linux - Old" ;;
		arch|arch*linux) distro="Arch Linux" ;;
		blag) distro="BLAG" ;;
		bunsenlabs) distro="BunsenLabs" ;;
		centos) distro="CentOS" ;;
		chakra) distro="Chakra" ;;
		chapeau) distro="Chapeau" ;;
		chrome*|chromium*) distro="Chrome OS" ;;
		crunchbang) distro="CrunchBang" ;;
		crux) distro="CRUX" ;;
		cygwin) distro="Cygwin" ;;
		debian) distro="Debian" ;;
		devuan) distro="Devuan" ;;
		deepin) distro="Deepin" ;;
		dragonflybsd) distro="DragonFlyBSD" ;;
		dragora) distro="Dragora" ;;
		elementary|'elementary os') distro="elementary OS";;
		evolveos) distro="Evolve OS" ;;
		exherbo|exherbo*linux) distro="Exherbo" ;;
		fedora) distro="Fedora" ;;
		freebsd) distro="FreeBSD" ;;
		freebsd*old) distro="FreeBSD - Old" ;;
		frugalware) distro="Frugalware" ;;
		fuduntu) distro="Fuduntu" ;;
		funtoo) distro="Funtoo" ;;
		gentoo) distro="Gentoo" ;;
		gnewsense) distro="gNewSense" ;;
		haiku) distro="Haiku" ;;
		kali*linux) distro="Kali Linux" ;;
		kaos) distro="KaOS";;
		kde*neon|neon) distro="KDE neon" ;;
		kogaion) distro="Kogaion" ;;
		korora) distro="Korora" ;;
		linuxdeepin) distro="LinuxDeepin" ;;
		lmde) distro="LMDE" ;;
		logos) distro="Logos" ;;
		lunar|lunar*linux) distro="Lunar Linux";;
		mac*os*x|os*x) distro="Mac OS X" ;;
		manjaro) distro="Manjaro" ;;
		mageia) distro="Mageia" ;;
		mandrake) distro="Mandrake" ;;
		mandriva) distro="Mandriva" ;;
		mer) distro="Mer" ;;
		mint|linux*mint) distro="Mint" ;;
		msys|msys2) distro="Msys" ;;
		netbsd) distro="NetBSD" ;;
		netrunner) distro="Netrunner" ;;
		nix|nix*os) distro="NixOS" ;;
		obarun) distro="Obarun" ;;
		ol|oracle*linux) distro="Oracle Linux" ;;
		openbsd) distro="OpenBSD" ;;
		opensuse) distro="openSUSE" ;;
		parabolagnu|parabolagnu/linux-libre|'parabola gnu/linux-libre'|parabola) distro="Parabola GNU/Linux-libre" ;;
		pclinuxos|pclos) distro="PCLinuxOS" ;;
		peppermint) distro="Peppermint" ;;
		qubes) distro="Qubes OS" ;;
		raspbian) distro="Raspbian" ;;
		red*hat*|rhel) distro="Red Hat Enterprise Linux" ;;
		red*star|red*star*os) distro="Red Star OS" ;;
		sabayon) distro="Sabayon" ;;
		sailfish|sailfish*os) distro="SailfishOS" ;;
		slackware) distro="Slackware" ;;
		solus) distro="Solus" ;;
		steam|steam*os) distro="SteamOS" ;;
		suse*linux*enterprise) distro="SUSE Linux Enterprise" ;;
		tinycore|tinycore*linux) distro="TinyCore" ;;
		trisquel) distro="Trisquel";;
		ubuntu)
			distro="Ubuntu"
			if grep -q 'Microsoft' /proc/version 2>/dev/null || \
			   grep -q 'Microsoft' /proc/sys/kernel/osrelease 2>/dev/null
			then
				uow=$(echo -e "$(getColor 'yellow') [Ubuntu on Windows 10]")
			fi
			;;
		viperr) distro="Viperr" ;;
		void) distro="Void" ;;
	esac
	verboseOut "Finding distro...found as '${distro} ${distro_release}'"
}
# Distro Detection - End

# Host and User detection - Begin
detecthost () {
	myUser=${USER}
	myHost=${HOSTNAME}
	if [[ "${distro}" == "Mac OS X" ]]; then myHost=${myHost/.local}; fi
	verboseOut "Finding hostname and user...found as '${myUser}@${myHost}'"
}

# Find Number of Running Processes
# processnum="$(( $( ps aux | wc -l ) - 1 ))"

# Kernel Version Detection - Begin
detectkernel () {
	# compatibility for older versions of OS X:
	kernel=$(uname -m && uname -sr)
	kernel=${kernel//$'\n'/ }
	#kernel=( $(uname -srm) )
	#kernel="${kernel[${#kernel[@]}-1]} ${kernel[@]:0:${#kernel[@]}-1}"
	verboseOut "Finding kernel version...found as '${kernel}'"
}
# Kernel Version Detection - End


# Uptime Detection - Begin
detectuptime () {
	unset uptime
	if [[ "${distro}" == "Mac OS X" || "${distro}" == "FreeBSD" || "${distro}" == "DragonFlyBSD" ]]; then
		boot=$(sysctl -n kern.boottime | cut -d "=" -f 2 | cut -d "," -f 1)
		now=$(date +%s)
		uptime=$(($now-$boot))
	elif [[ "${distro}" == "OpenBSD" ]]; then
		boot=$(sysctl -n kern.boottime)
		now=$(date +%s)
		uptime=$((${now} - ${boot}))
	elif [[ "${distro}" == "Haiku" ]]; then
		uptime=$(uptime | cut -d ',' -f2,3 | sed 's/ up //; s/ hour,/h/; s/ minutes/m/;')
	else
		if [[ -f /proc/uptime ]]; then
			uptime=$(</proc/uptime)
			uptime=${uptime//.*}
		fi
	fi

	if [[ -n ${uptime} ]] && [[ "${distro}" != "Haiku" ]]; then
		secs=$((${uptime}%60))
		mins=$((${uptime}/60%60))
		hours=$((${uptime}/3600%24))
		days=$((${uptime}/86400))
		uptime="${mins}m"
		if [ "${hours}" -ne "0" ]; then
			uptime="${hours}h ${uptime}"
		fi
		if [ "${days}" -ne "0" ]; then
			uptime="${days}d ${uptime}"
		fi
	else
		if [[ "$distro" =~ "NetBSD" ]]; then uptime=$(awk -F. '{print $1}' /proc/uptime); fi
		if [[ "$distro" =~ "BSD" ]]; then uptime=$(uptime | awk '{$1=$2=$(NF-6)=$(NF-5)=$(NF-4)=$(NF-3)=$(NF-2)=$(NF-1)=$NF=""; sub(" days","d");sub(",","");sub(":","h ");sub(",","m"); print}'); fi
	fi
	verboseOut "Finding current uptime...found as '${uptime}'"
}
# Uptime Detection - End


# Package Count - Begin
detectpkgs () {
	pkgs="Unknown"
	case "${distro}" in
		'Alpine Linux') pkgs=$(apk info | wc -l) ;;
		'Arch Linux'|'Parabola GNU/Linux-libre'|'Chakra'|'Manjaro'|'Antergos'|'Netrunner'|'KaOS'|'Obarun') pkgs=$(pacman -Qq | wc -l) ;;
		'Dragora') pkgs=$(ls -1 /var/db/pkg | wc -l) ;;
		'Frugalware') pkgs=$(pacman-g2 -Q | wc -l) ;;
		'Fuduntu'|'Ubuntu'|'Mint'|'KDE neon'|'Debian'|'Devuan'|'Raspbian'|'LMDE'|'CrunchBang'|'Peppermint'|'LinuxDeepin'|'Deepin'|'Kali Linux'|'Trisquel'|'elementary OS'|'gNewSense'|'BunsenLabs'|'SteamOS') pkgs=$(dpkg -l | grep -c ^i) ;;
		'Slackware') pkgs=$(ls -1 /var/log/packages | wc -l) ;;
		'Gentoo'|'Sabayon'|'Funtoo'|'Chrome OS'|'Kogaion') pkgs=$(ls -d /var/db/pkg/*/* | wc -l) ;;
		'NixOS') pkgs=$(ls -d -1 /nix/store/*/ | wc -l) ;;
		'Fedora'|'Korora'|'BLAG'|'Chapeau'|'openSUSE'|'SUSE Linux Enterprise'|'Red Hat Enterprise Linux'|'Oracle Linux'|'CentOS'|'Mandriva'|'Mandrake'|'Mageia'|'Mer'|'SailfishOS'|'PCLinuxOS'|'Viperr'|'Qubes OS'|'Red Star OS') pkgs=$(rpm -qa | wc -l) ;;
		'Void') pkgs=$(xbps-query -l | wc -l) ;;
		'Evolve OS'|'Solus') pkgs=$(pisi list-installed | wc -l) ;;
		'CRUX') pkgs=$(pkginfo -i | wc -l) ;;
		'Lunar Linux') pkgs=$(lvu installed | wc -l) ;;
		'TinyCore') pkgs=$(tce-status -i | wc -l) ;;
		'Exherbo')
			xpkgs=$(ls -d -1 /var/db/paludis/repositories/cross-installed/*/data/* | wc -l)
			pkgs=$(ls -d -1 /var/db/paludis/repositories/installed/data/* | wc -l)
			pkgs=$((${pkgs} + ${xpkgs}))
		;;
		'Mac OS X')
			if [ -d "/usr/local/bin" ]; then
				loc_pkgs=$(ls -l /usr/local/bin/ | grep -v "\(../Cellar/\|brew\)" | wc -l)
				pkgs=$((${loc_pkgs} -1));
			fi

			if type -p port >/dev/null 2>&1; then
				port_pkgs=$(port installed 2>/dev/null | wc -l)
				pkgs=$((${pkgs} + (${port_pkgs} -1)))
			fi

			if type -p brew >/dev/null 2>&1; then
				brew_pkgs=$(brew list -1 2>/dev/null | wc -l)
				pkgs=$((${pkgs} + ${brew_pkgs}))
			fi
			if type -p pkgin >/dev/null 2>&1; then
				pkgsrc_pkgs=$(pkgin list 2>/dev/null | wc -l)
				pkgs=$((${pkgs} + ${pkgsrc_pkgs}))
			fi
		;;
		'DragonFlyBSD')
			pkgs=$(if TMPDIR=/dev/null ASSUME_ALWAYS_YES=1 PACKAGESITE=file:///nonexistent pkg info pkg >/dev/null 2>&1; then
				pkg info | wc -l | awk '{print $1}'; else pkg_info | wc -l | tr -d ' '; fi)
		;;
		'OpenBSD')
			pkgs=$(pkg_info | wc -l | awk '{sub(" ", "");print $1}')
		;;
		'FreeBSD')
			pkgs=$(if TMPDIR=/dev/null ASSUME_ALWAYS_YES=1 PACKAGESITE=file:///nonexistent pkg info pkg >/dev/null 2>&1; then
				pkg info | wc -l | awk '{print $1}'; else pkg_info | wc -l | awk '{sub(" ", "");print $1}'; fi)
		;;
		'NetBSD')
			pkgs=$(pkg_info | wc -l | tr -d ' ')
		;;
		'Cygwin')
			cygfix=2
			pkgs=$(($(cygcheck -cd | wc -l) - ${cygfix}))
			if [ -d "/cygdrive/c/ProgramData/chocolatey/lib" ]; then
				chocopkgs=$(( $(ls -1 /cygdrive/c/ProgramData/chocolatey/lib | wc -l) ))
				pkgs=$((${pkgs} + ${chocopkgs}))
			fi
		;;
		'Msys')
			pkgs=$(pacman -Qq | wc -l)
			if [ -d "/c/ProgramData/chocolatey/lib" ]; then
				chocopkgs=$(( $(ls -1 /c/ProgramData/chocolatey/lib | wc -l) ))
				pkgs=$((${pkgs} + ${chocopkgs}))
			fi
		;;
		'Haiku')
			haikualpharelease="no"
			if [ -d /boot/system/package-links ]; then
				pkgs=$(ls /boot/system/package-links | wc -l)
			elif type -p installoptionalpackage >/dev/null 2>&1; then
				haikualpharelease="yes"
				pkgs=$(installoptionalpackage -l | sed -n '3p' | wc -w)
			fi
		;;
	esac
	verboseOut "Finding current package count...found as '$pkgs'"
}




# CPU Detection - Begin
detectcpu () {
	REGEXP="-r"
	if [ "$distro" == "Mac OS X" ]; then
		cpu=$(machine)
		if [[ $cpu == "ppc750" ]]; then
			cpu="IBM PowerPC G3"
		elif [[ $cpu == "ppc7400" || $cpu == "ppc7450" ]]; then
			cpu="IBM PowerPC G4"
		elif [[ $cpu == "ppc970" ]]; then
			cpu="IBM PowerPC G5"
		else
			cpu=$(sysctl -n machdep.cpu.brand_string)
		fi
		REGEXP="-E"
	elif [ "$OSTYPE" == "gnu" ]; then
		# no /proc/cpuinfo on GNU/Hurd
		if [ "$(uname -m | grep 'i.86')" ]; then
			cpu="Unknown x86"
		else
			cpu="Unknown"
		fi
	elif [ "$distro" == "FreeBSD" ]; then
		cpu=$(dmesg | grep 'CPU:' | head -n 1 | sed -r 's/CPU: //' | sed -e 's/([^()]*)//g')
	elif [ "$distro" == "DragonFlyBSD" ]; then
		cpu=$(sysctl -n hw.model)
	elif [ "$distro" == "OpenBSD" ]; then
		cpu=$(sysctl -n hw.model | sed 's/@.*//')
	elif [ "$distro" == "Haiku" ]; then
		cpu=$(sysinfo -cpu | grep 'CPU #0' | cut -d'"' -f2 | awk 'BEGIN{FS=" @"; OFS="\n"} { print $1; exit }')
		cpu_mhz=$(sysinfo -cpu | grep 'running at' | awk 'BEGIN{FS="running at "} { print $2; exit }' | cut -d'M' -f1)
		if [ $(echo $cpu_mhz) -gt 999 ]; then
			cpu_ghz=$(awk '{print $1/1000}' <<< "${cpu_mhz}")
			cpufreq="${cpu_ghz}GHz"
		else
			cpufreq="${cpu_mhz}MHz"
		fi
	else
		cpu=$(awk 'BEGIN{FS=":"} /model name/ { print $2; exit }' /proc/cpuinfo | awk 'BEGIN{FS=" @"; OFS="\n"} { print $1; exit }')
		cpun=$(grep -c '^processor' /proc/cpuinfo)
		if [ -z "$cpu" ]; then
			cpu=$(awk 'BEGIN{FS=":"} /Hardware/ { print $2; exit }' /proc/cpuinfo)
		fi
		if [ -z "$cpu" ]; then
			cpu=$(awk 'BEGIN{FS=":"} /^cpu/ { gsub(/  +/," ",$2); print $2; exit}' /proc/cpuinfo | sed 's/, altivec supported//;s/^ //')
			if [[ $cpu =~ ^(PPC)*9.+ ]]; then
				model="IBM PowerPC G5 "
			elif [[ $cpu =~ 740/750 ]]; then
				model="IBM PowerPC G3 "
			elif [[ $cpu =~ ^74.+ ]]; then
				model="Motorola PowerPC G4 "
			elif [[ "$(cat /proc/cpuinfo)" =~ "BCM2708" ]]; then
				model="Broadcom BCM2835 ARM1176JZF-S"
			else
				arch=$(uname -m)
				if [ "$arch" = "s390x" ] || [ "$arch" = "s390" ]; then
					cpu=""
					args=$(grep 'machine' /proc/cpuinfo | sed 's/^.*://g; s/ //g; s/,/\n/g' | grep '^machine=.*')
					eval $args
					case "$machine" in
						# information taken from https://github.com/SUSE/s390-tools/blob/master/cputype
						2064) model="IBM eServer zSeries 900" ;;
						2066) model="IBM eServer zSeries 800" ;;
						2084) model="IBM eServer zSeries 990" ;;
						2086) model="IBM eServer zSeries 890" ;;
						2094) model="IBM System z9 Enterprise Class" ;;
						2096) model="IBM System z9 Business Class" ;;
						2097) model="IBM System z10 Enterprise Class" ;;
						2098) model="IBM System z10 Business Class" ;;
						2817) model="IBM zEnterprise 196" ;;
						2818) model="IBM zEnterprise 114" ;;
						2827) model="IBM zEnterprise EC12" ;;
						2828) model="IBM zEnterprise BC12" ;;
						2964) model="IBM z13" ;;
						*) model="IBM S/390 machine type $machine" ;;
					esac
				else
					model="Unkown"
				fi
			fi
			cpu="${model}${cpu}"
		fi
		loc="/sys/devices/system/cpu/cpu0/cpufreq"
		bl="${loc}/bios_limit"
		smf="${loc}/scaling_max_freq"
		if [ -f "$bl" ] && [ -r "$bl" ]; then
			cpu_mhz=$(awk '{print $1/1000}' "$bl")
		elif [ -f "$smf" ] && [ -r "$smf" ]; then
			cpu_mhz=$(awk '{print $1/1000}' "$smf")
		else
			cpu_mhz=$(awk -F':' '/cpu MHz/{ print int($2+.5) }' /proc/cpuinfo | head -n 1)
		fi
		if [ -n "$cpu_mhz" ]; then
			if [ $(echo $cpu_mhz | cut -d. -f1) -gt 999 ]; then
				cpu_ghz=$(awk '{print $1/1000}' <<< "${cpu_mhz}")
				cpufreq="${cpu_ghz}GHz"
			else
				cpufreq="${cpu_mhz}MHz"
			fi
		fi
	fi
	if [[ "${cpun}" -gt "1" ]]; then
		cpun="${cpun}x "
	else
		cpun=""
	fi
	if [ -z "$cpufreq" ]; then
		cpu="${cpun}${cpu}"
	else
		cpu="$cpu @ ${cpun}${cpufreq}"
	fi
	cpu=$(sed $REGEXP 's/\([tT][mM]\)|\([Rr]\)|[pP]rocessor//g' <<< "${cpu}" | xargs)
	verboseOut "Finding current CPU...found as '$cpu'"
}
# CPU Detection - End


# GPU Detection - Begin (EXPERIMENTAL!)
detectgpu () {
	if [[ "${distro}" == "FreeBSD" || "${distro}" == "DragonFlyBSD" ]]; then
		nvisettexist=$(which nvidia-settings)
		if [ -x "$nvisettexist" ]; then
			gpu="$(nvidia-settings -t -q gpus | grep \( | sed 's/.*(\(.*\))/\1/')"
		else
			gpu_info=$(pciconf -lv 2> /dev/null | grep -B 4 VGA)
			gpu_info=$(grep -E 'device.*=.*' <<< "${gpu_info}")
			gpu="${gpu_info##*device*= }"
			gpu="${gpu//\'}"
			# gpu=$(sed 's/.*device.*= //' <<< "${gpu_info}" | sed "s/'//g")
		fi
	elif [[ "${distro}" == "OpenBSD" ]]; then
		gpu=$(glxinfo | grep 'OpenGL renderer string' | sed 's/OpenGL renderer string: //')
	elif [[ "${distro}" == "Mac OS X" ]]; then
		gpu=$(system_profiler SPDisplaysDataType | awk -F': ' '/^\ *Chipset Model:/ {print $2}' | awk '{ printf "%s / ", $0 }' | sed -e 's/\/ $//g')
	elif [[ "${distro}" == "Cygwin" || "${distro}" == "Msys" ]]; then
		gpu=$(wmic path Win32_VideoController get caption | sed -n '2p')
	elif [[ "${distro}" == "Haiku" ]]; then
		gpu="$(listdev | grep -A2 -e 'device Display controller' | tail -n1 | sed 's/  device ....: //')"
	else
		if [[ -n "$(PATH="/opt/bin:$PATH" type -p nvidia-smi)" ]]; then
			gpu=$($(PATH="/opt/bin:$PATH" type -p nvidia-smi | cut -f1) -q | awk -F':' '/Product Name/ {gsub(/: /,":"); print $2}' | sed ':a;N;$!ba;s/\n/, /g')
		elif [[ -n "$(PATH="/usr/sbin:$PATH" type -p glxinfo)" && -z "${gpu}" ]]; then
			gpu_info=$($(PATH="/usr/sbin:$PATH" type -p glxinfo | cut -f1) 2>/dev/null)
			gpu=$(grep "OpenGL renderer string" <<< "${gpu_info}" | cut -d ':' -f2  | sed -n '1h;2,$H;${g;s/\n/,/g;p}')
			gpu="${gpu:1}"
			gpu_info=$(grep "OpenGL vendor string" <<< "${gpu_info}")
		elif [[ -n "$(PATH="/usr/sbin:$PATH" type -p lspci)" && -z "$gpu" ]]; then
			gpu_info=$($(PATH="/usr/bin:$PATH" type -p lspci | cut -f1) 2> /dev/null | grep VGA)
			gpu=$(grep -oE '\[.*\]' <<< "${gpu_info}" | sed 's/\[//;s/\]//' | sed -n '1h;2,$H;${g;s/\n/, /g;p}')
		fi
	fi

	if [ -n "$gpu" ];then
		if [ $(grep -i nvidia <<< "${gpu_info}" | wc -l) -gt 0 ];then
			gpu_info="NVidia "
		elif [ $(grep -i intel <<< "${gpu_info}" | wc -l) -gt 0 ];then
			gpu_info="Intel "
		elif [ $(grep -i amd <<< "${gpu_info}" | wc -l) -gt 0 ];then
			gpu_info="AMD "
		elif [[ $(grep -i ati <<< "${gpu_info}" | wc -l) -gt 0  || $(grep -i radeon <<< "${gpu_info}" | wc -l) -gt 0 ]]; then
			gpu_info="ATI "
		else
			gpu_info=$(cut -d ':' -f2 <<< "${gpu_info}")
			gpu_info="${gpu_info:1} "
		fi
		gpu="${gpu}"
	else
		gpu="Not Found"
	fi

	verboseOut "Finding current GPU...found as '$gpu'"
}
# GPU Detection - End


# Disk Usage Detection - Begin
detectdisk () {
	diskusage="Unknown"
	if type -p df >/dev/null 2>&1; then
		if [[ "${distro}" =~ (Free|Net|Open|DragonFly)BSD ]]; then
			totaldisk=$(df -h -c 2>/dev/null | tail -1)
		elif [[ "${distro}" == "Mac OS X" ]]; then
			totaldisk=$(df -H / 2>/dev/null | tail -1)
		else
			totaldisk=$(df -h -x aufs -x tmpfs --total 2>/dev/null | tail -1)
		fi
		disktotal=$(awk '{print $2}' <<< "${totaldisk}")
		diskused=$(awk '{print $3}' <<< "${totaldisk}")
		diskusedper=$(awk '{print $5}' <<< "${totaldisk}")
		diskusage="${diskused} / ${disktotal} (${diskusedper})"
		diskusage_verbose=$(sed 's/%/%%/' <<< $diskusage)
	fi
	verboseOut "Finding current disk usage...found as '$diskusage_verbose'"
}
# Disk Usage Detection - End


# Memory Detection - Begin
detectmem () {
	hw_mem=0
	free_mem=0
	human=1024
	if [ "$distro" == "Mac OS X" ]; then
		totalmem=$(echo "$(sysctl -n hw.memsize)"/${human}^2|bc)
		wiredmem=$(vm_stat | grep wired | awk '{ print $4 }' | sed 's/\.//')
		activemem=$(vm_stat | grep ' active' | awk '{ print $3 }' | sed 's/\.//')
		compressedmem=$(vm_stat | grep occupied | awk '{ print $5 }' | sed 's/\.//')
		if [[ ! -z "$compressedmem | tr -d" ]]; then
			compressedmem=0
		fi
		usedmem=$(((${wiredmem} + ${activemem} + ${compressedmem}) * 4 / $human))
	elif [[ "${distro}" == "Cygwin" || "${distro}" == "Msys" ]]; then
		total_mem=$(awk '/MemTotal/ { print $2 }' /proc/meminfo)
		totalmem=$((${total_mem}/$human))
		free_mem=$(awk '/MemFree/ { print $2 }' /proc/meminfo)
		used_mem=$((${total_mem} - ${free_mem}))
		usedmem=$((${used_mem} / $human))
	elif [[ "$distro" == "FreeBSD"  || "$distro" == "DragonFlyBSD" ]]; then
		phys_mem=$(sysctl -n hw.physmem)
		size_mem=$phys_mem
		size_chip=1
		guess_chip=`echo "$size_mem / 8 - 1" | bc`
		while [ $guess_chip != 0 ]; do
			guess_chip=`echo "$guess_chip / 2" | bc`
			size_chip=`echo "$size_chip * 2" | bc`
		done
		round_mem=`echo "( $size_mem / $size_chip + 1 ) * $size_chip " | bc`
		totalmem=$(($round_mem / ($human * $human) ))
		pagesize=$(sysctl -n hw.pagesize)
		inactive_count=$(sysctl -n vm.stats.vm.v_inactive_count)
		inactive_mem=$(($inactive_count * $pagesize))
		cache_count=$(sysctl -n vm.stats.vm.v_cache_count)
		cache_mem=$(($cache_count * $pagesize))
		free_count=$(sysctl -n vm.stats.vm.v_free_count)
		free_mem=$(($free_count * $pagesize))
		avail_mem=$(($inactive_mem + $cache_mem + $free_mem))
		used_mem=$(($round_mem - $avail_mem))
		usedmem=$(($used_mem / ($human * $human) ))
	elif [ "$distro" == "OpenBSD" ]; then
		totalmem=$(($(sysctl -n hw.physmem) / $human / $human))
		usedmem=$(($(vmstat | sed -n 3p | cut -d' ' -f5) / $human))
	elif [ "$distro" == "NetBSD" ]; then
		phys_mem=$(awk '/MemTotal/ { print $2 }' /proc/meminfo)
		totalmem=$((${phys_mem} / $human))
		if grep -q 'Cached' /proc/meminfo; then
			cache=$(awk '/Cached/ {print $2}' /proc/meminfo)
			usedmem=$((${cache} / $human))
		else
			free_mem=$(awk '/MemFree/ { print $2 }' /proc/meminfo)
			used_mem=$((${phys_mem} - ${free_mem}))
			usedmem=$((${used_mem} / $human))
		fi
	elif [ "$distro" == "Haiku" ]; then
		totalmem=$(( $(sysinfo -mem | head -n1 | cut -d'/' -f3 | tr -d ' ' | tr -d ')') / $human / $human ))
		usedmem=$(( $(sysinfo -mem | head -n1 | cut -d'/' -f2 | sed 's/max//; s/ //g') / $human / $human ))
	else
		mem_info=$(</proc/meminfo)
		mem_info=$(echo $(echo $(mem_info=${mem_info// /}; echo ${mem_info//kB/})))
		for m in $mem_info; do
			if [[ ${m//:*} = MemTotal ]]; then
				memtotal=${m//*:}
			fi

			if [[ ${m//:*} = MemFree ]]; then
				memfree=${m//*:}
			fi

			if [[ ${m//:*} = Buffers ]]; then
				membuffer=${m//*:}
			fi

			if [[ ${m//:*} = Cached ]]; then
				memcached=${m//*:}
			fi
		done

		usedmem="$(((($memtotal - $memfree) - $membuffer - $memcached) / $human))"
		totalmem="$(($memtotal / $human))"
	fi
	mem="${usedmem}MiB / ${totalmem}MiB"
	verboseOut "Finding current RAM usage...found as '$mem'"
}
# Memory Detection - End


# Shell Detection - Begin
detectshell_ver () {
	local version_data='' version='' get_version='--version'

	case $1 in
		# ksh sends version to stderr. Weeeeeeird.
		ksh)
			version_data="$( $1 $get_version 2>&1 )"
			;;
		*)
			version_data="$( $1 $get_version 2>/dev/null )"
			;;
	esac

	if [[ -n $version_data ]];then
		version=$(awk '
		BEGIN {
			IGNORECASE=1
		}
		/'$2'/ {
			gsub(/(,|v|V)/, "",$'$3')
			if ($2 ~ /[Bb][Aa][Ss][Hh]/) {
				gsub(/\(.*|-release|-version\)/,"",$4)
			}
			print $'$3'
			exit # quit after first match prints
		}' <<< "$version_data")
	fi
	echo "$version"
}
detectshell () {
	if [[ ! "${shell_type}" ]]; then
		if [[ "${distro}" == "Cygwin" || "${distro}" == "Msys" || "${distro}" == "Haiku" || "${distro}" == "Alpine Linux" || "${OSTYPE}" == "gnu" ]]; then
			shell_type=$(echo "$SHELL" | awk -F'/' '{print $NF}')
		elif [[ "${distro}" == "TinyCore" ]]; then
			if [[ "$(readlink "$SHELL")" == "busybox" ]]; then
				shell_type="BusyBox"
			else
				shell_type=$(echo "$SHELL" | awk -F'/' '{print $NF}')
			fi
		else
			if [[ "${OSTYPE}" == "linux-gnu" || "${OSTYPE}" == "linux" ]]; then
				shell_type=$(ps -p $PPID -o cmd --no-heading)
			elif [[ "${distro}" == "Mac OS X" || "${distro}" == "DragonFlyBSD" || "${distro}" == "FreeBSD" || "${distro}" == "OpenBSD" || "${distro}" == "NetBSD" ]]; then
				shell_type=$(ps -p $PPID -o command | tail -1)
			else
				shell_type=$(ps -p $(ps -p $PPID | awk '$1 !~ /PID/ {print $1}') | awk 'FNR>1 {print $1}')
			fi
			shell_type=${shell_type/-}
			shell_type=${shell_type//*\/}
		fi
	fi

	case $shell_type in
		bash)
			shell_version_data=$( detectshell_ver "$shell_type" "^GNU.bash,.version" "4" )
			;;
		BusyBox)
			shell_version_data=$( busybox | head -n1 | cut -d ' ' -f2 )
			;;
		csh)
			shell_version_data=$( detectshell_ver "$shell_type" "$shell_type" "3" )
			;;
		dash)
			shell_version_data=$( detectshell_ver "$shell_type" "$shell_type" "3" )
			;;
		ksh)
			shell_version_data=$( detectshell_ver "$shell_type" "version" "5" )
			;;
		tcsh)
			shell_version_data=$( detectshell_ver "$shell_type" "^tcsh" "2" )
			;;
		zsh)
			shell_version_data=$( detectshell_ver "$shell_type" "^zsh" "2" )
			;;
		fish)
			shell_version_data=$( fish --version | awk '{print $3}' )
			;;
	esac

	if [[ -n $shell_version_data ]];then
		shell_type="$shell_type $shell_version_data"
	fi

	myShell=${shell_type}
	verboseOut "Finding current shell...found as '$myShell'"
}
# Shell Detection - End


# Resolution Detection - Begin
detectres () {
	if [[ ${distro} != "Mac OS X" && ${distro} != "Cygwin" && "${distro}" != "Msys" && ${distro} != "Haiku" ]]; then
		if [[ -n ${DISPLAY} ]]; then
			if type -p xdpyinfo >/dev/null 2>&1; then
				if [[ "$distro" =~ "BSD" ]]; then
					xResolution=$(xdpyinfo | sed -n 's/.*dim.* \([0-9]*x[0-9]*\) .*/\1/pg' | tr '\n' ' ')
				else
					xResolution=$(xdpyinfo | sed -n 's/.*dim.* \([0-9]*x[0-9]*\) .*/\1/pg' | sed ':a;N;$!ba;s/\n/ /g')
				fi
			fi
		fi
	elif [[ ${distro} == "Mac OS X" ]]; then
		xResolution=$(system_profiler SPDisplaysDataType | awk '/Resolution:/ {print $2"x"$4" "}')
		if [[ "$(echo $xResolution | wc -l)" -ge 1 ]]; then
			xResolution=$(echo $xResolution | tr "\\n" "," | sed 's/\(.*\),/\1/')
		fi
	elif [[ "${distro}" == "Cygwin" || "${distro}" == "Msys" ]]; then
		xResolution=$(wmic path Win32_VideoController get CurrentHorizontalResolution,CurrentVerticalResolution | awk 'NR==2 {print $1"x"$2}')
	elif [[ "${distro}" == "Haiku" ]]; then
		width=$(screenmode | cut -d ' ' -f2)
		height=$(screenmode | cut -d ' ' -f3 | tr -d ',')
		xResolution="$(echo ${width}x${height})"
	else
		xResolution="No X Server"
	fi
	verboseOut "Finding current resolution(s)...found as '$xResolution'"
}
# Resolution Detection - End


# DE Detection - Begin
detectde () {
	DE="Not Present"
	if [[ ${distro} != "Mac OS X" && ${distro} != "Cygwin" && "${distro}" != "Msys" ]]; then
		if [[ -n ${DISPLAY} ]]; then
			if type -p xprop >/dev/null 2>&1;then
				xprop_root="$(xprop -root 2>/dev/null)"
				if [[ -n ${xprop_root} ]]; then
					DE=$(echo "${xprop_root}" | awk 'BEGIN {
						de = "Not Present"
					}
					{
						if ($1 ~ /^_DT_SAVE_MODE/) {
							de = $NF
							gsub(/\"/,"",de)
							de = toupper(de)
							exit
						}
						else if ($1 ~/^KDE_SESSION_VERSION/) {
							de = "KDE"$NF
							exit
						}
						else if ($1 ~ /^_MUFFIN/) {
							de = "Cinnamon"
							exit
						}
						else if ($1 ~ /^TDE_FULL_SESSION/) {
							de = "Trinity"
							exit
						}
						else if ($0 ~ /"xfce4"/) {
							de = "XFCE4"
							exit
						}
						else if ($0 ~ /"xfce5"/) {
							de = "XFCE5"
							exit
						}
					} END {
						print de
					}')
				fi
			fi

			if [[ ${DE} == "Not Present" ]]; then
				# Let's use xdg-open code for GNOME/Enlightment/KDE/LXDE/MATE/XFCE detection
				# http://bazaar.launchpad.net/~vcs-imports/xdg-utils/master/view/head:/scripts/xdg-utils-common.in#L251
				if [ -n "${XDG_CURRENT_DESKTOP}" ]; then
					case "${XDG_CURRENT_DESKTOP}" in
						ENLIGHTENMENT)
							DE=Enlightenment;
							;;
						GNOME)
							DE=GNOME;
							;;
						KDE)
							DE=KDE;
							;;
						LUMINA|Lumina)
							DE=Lumina;
							;;
						LXDE)
							DE=LXDE;
							;;
						MATE)
							DE=MATE;
							;;
						XFCE)
							DE=XFCE
							;;
						'X-Cinnamon')
							DE=Cinnamon
							;;
						Unity)
							DE=Unity
							;;
						LXQt)
							DE=LXQt
							;;
					esac
				fi

				if [ -n "$DE" ]; then
					# classic fallbacks
					if [ -n "$KDE_FULL_SESSION" ]; then DE=KDE;
					elif [ -n "$TDE_FULL_SESSION" ]; then DE=Trinity;
					elif [ -n "$GNOME_DESKTOP_SESSION_ID" ]; then DE=GNOME;
					elif [ -n "$MATE_DESKTOP_SESSION_ID" ]; then DE=MATE;
					elif `dbus-send --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.GetNameOwner string:org.gnome.SessionManager > /dev/null 2>&1` ; then DE=GNOME;
					elif xprop -root _DT_SAVE_MODE 2> /dev/null | grep ' = \"xfce4\"$' >/dev/null 2>&1; then DE=XFCE;
					elif xprop -root 2> /dev/null | grep -i '^xfce_desktop_window' >/dev/null 2>&1; then DE=XFCE
					elif echo $DESKTOP | grep -q '^Enlightenment'; then DE=Enlightenment;
					fi
				fi

				case "$DESKTOP_SESSION" in
					gnome|gnome-fallback|gnome-fallback-compiz )
						DE=GNOME
						;;
					deepin)
						DE=Deepin
						;;
				esac

				if [ -n "$DE" ]; then
					# fallback to checking $DESKTOP_SESSION
					case "$DESKTOP_SESSION" in
						gnome)
							DE=GNOME;
							;;
						LUMINA|Lumina)
							DE=Lumina;
							;;
						LXDE|Lubuntu)
							DE=LXDE;
							;;
						MATE)
							DE=MATE;
							;;
						xfce|xfce4|'Xfce Session')
							DE=XFCE;
							;;
						'budgie-desktop')
							DE=Budgie
							;;
						Cinnamon)
							DE=Cinnamon
							;;
						trinity)
							DE=Trinity
							;;
					esac
				fi

				if [ -n "$DE" ]; then
					# fallback to checking $GDMSESSION
					case "$GDMSESSION" in
						Lumina*|LUMINA*|lumina*)
							DE=Lumina
							;;
						MATE|mate)
							DE=MATE
							;;
					esac
				fi

				if [[ ${DE} == "GNOME" ]]; then
					if type -p xprop >/dev/null 2>&1; then
						if xprop -name "unity-launcher" >/dev/null 2>&1; then
							DE="Unity"
						elif xprop -name "launcher" >/dev/null 2>&1 &&
							xprop -name "panel" >/dev/null 2>&1; then

							DE="Unity"
						fi
					fi
				fi

				if [[ ${DE} == "KDE" ]]; then
					if [[ -n ${KDE_SESSION_VERSION} ]]; then
						if [[ ${KDE_SESSION_VERSION} == '5' ]]; then
							DE="KDE5"
						elif [[ ${KDE_SESSION_VERSION} == '4' ]]; then
							DE="KDE4"
						fi
					elif [[ "x${KDE_FULL_SESSION}" == "xtrue" ]]; then
						DE="KDE"
						DEver_data=$(kded --version 2>/dev/null)
						DEver=$(grep -si '^KDE:' <<< "$DEver_data" | awk '{print $2}')
					fi
				fi
			fi

			if [[ ${DE} != "Not Present" ]]; then
				if [[ ${DE} == "Cinnamon" ]]; then
					if type -p >/dev/null 2>&1; then
						DEver=$(cinnamon --version)
						DE="${DE} ${DEver//* }"
					fi
				elif [[ ${DE} == "GNOME" ]]; then
					if type -p gnome-session >/dev/null 2>&1; then
						DEver=$(gnome-session --version 2> /dev/null)
						DE="${DE} ${DEver//* }"
					elif type -p gnome-session-properties >/dev/null 2>&1; then
						DEver=$(gnome-session-properties --version 2> /dev/null)
						DE="${DE} ${DEver//* }"
					fi
				elif [[ ${DE} == "KDE4" || ${DE} == "KDE5" ]]; then
					if type -p kded${DE#KDE} >/dev/null 2>&1; then
						DEver=$(kded${DE#KDE} --version)
						if [[ $(( $(echo "$DEver" | wc -w) )) -eq 2 ]] && [[ "$(echo "$DEver" | cut -d ' ' -f1)" == "kded${DE#KDE}" ]]; then
							DEver=$(echo "$DEver" | cut -d ' ' -f2)
							DE="KDE ${DEver}"
						else
							for l in $(echo "${DEver// /_}"); do
								if [[ ${l//:*} == "KDE_Development_Platform" ]]; then
									DEver=${l//*:_}
									DE="KDE ${DEver//_*}"
								fi
							done
						fi
						if pgrep plasmashell >/dev/null 2>&1; then
							DEver=$(plasmashell --version | cut -d ' ' -f2)
							DE="$DE / Plasma $DEver"
						fi
					fi
				elif [[ ${DE} == "Lumina" ]]; then
					if type -p Lumina-DE.real >/dev/null 2>&1; then
						lumina="$(type -p Lumina-DE.real)"
					elif type -p Lumina-DE >/dev/null 2>&1; then
						lumina="$(type -p Lumina-DE)"
					fi
					if [ -n "$lumina" ]; then
						if grep -e '--version' "$lumina" >/dev/null; then
							DEver=$("$lumina" --version 2>&1 | tr -d \")
							DE="${DE} ${DEver}"
						fi
					fi
				elif [[ ${DE} == "MATE" ]]; then
					if type -p mate-session >/dev/null 2>&1; then
						DEver=$(mate-session --version)
						DE="${DE} ${DEver//* }"
					fi
				elif [[ ${DE} == "Unity" ]]; then
					if type -p unity >/dev/null 2>&1; then
						DEver=$(unity --version)
						DE="${DE} ${DEver//* }"
					fi
				elif [[ ${DE} == "Deepin" ]]; then
					if [[ -f /etc/deepin-version ]]; then
						DEver="$(awk -F '=' '/Version/ {print $2}' /etc/deepin-version)"
						DE="${DE} ${DEver//* }"
					fi
				elif [[ ${DE} == "Trinity" ]]; then
					if type -p tde-config >/dev/null 2>&1; then
						DEver="$(tde-config --version | awk -F ' ' '/TDE:/ {print $2}')"
						DE="${DE} ${DEver//* }"
					fi
				fi
			fi

			if [[ "${DE}" == "Not Present" ]]; then
				if pgrep -U ${UID} lxsession >/dev/null 2>&1; then
					DE="LXDE"
					if type -p lxpanel >/dev/null 2>&1; then
						DEver=$(lxpanel -v)
						DE="${DE} $DEver"
					fi
				elif pgrep -U ${UID} lxqt-session >/dev/null 2>&1; then
					DE="LXQt"
				elif pgrep -U ${UID} razor-session >/dev/null 2>&1; then
					DE="RazorQt"
				elif pgrep -U ${UID} dtsession >/dev/null 2>&1; then
					DE="CDE"
				fi
			fi
		fi
	elif [[ "${distro}" == "Mac OS X" ]]; then
		if ps -U ${USER} | grep [F]inder >/dev/null 2>&1; then
			DE="Aqua"
		fi
	elif [[ "${distro}" == "Cygwin" || "${distro}" == "Msys" ]]; then
		# https://msdn.microsoft.com/en-us/library/ms724832%28VS.85%29.aspx
		if [ "$(wmic os get version | grep -o '^\(6\|10\)')" ]; then
			DE='Aero'
		else
			DE='Luna'
		fi
	fi
	verboseOut "Finding desktop environment...found as '$DE'"
}
### DE Detection - End


# WM Detection - Begin
detectwm () {
	WM="Not Found"
	if [[ ${distro} != "Mac OS X" && ${distro} != "Cygwin" && "${distro}" != "Msys" ]]; then
		if [[ -n ${DISPLAY} ]]; then
			for each in "${wmnames[@]}"; do
				PID="$(pgrep -U ${UID} "^$each$")"
				if [ "$PID" ]; then
					case $each in
						'2bwm') WM="2bwm";;
						'9wm') WM="9wm";;
						'awesome') WM="Awesome";;
						'beryl') WM="Beryl";;
						'blackbox') WM="BlackBox";;
						'bspwm') WM="bspwm";;
						'budgie-wm') WM="BudgieWM";;
						'chromeos-wm') WM="chromeos-wm";;
						'cinnamon') WM="Muffin";;
						'compiz') WM="Compiz";;
						'deepin-wm') WM="deepin-wm";;
						'dminiwm') WM="dminiwm";;
						'dtwm') WM="dtwm";;
						'dwm') WM="dwm";;
						'e16') WM="E16";;
						'emerald') WM="Emerald";;
						'enlightenment') WM="E17";;
						'fluxbox') WM="FluxBox";;
						'flwm'|'flwm_topside') WM="FLWM";;
						'fvwm') WM="FVWM";;
						'herbstluftwm') WM="herbstluftwm";;
						'howm') WM="howm";;
						'i3') WM="i3";;
						'icewm') WM="IceWM";;
						'kwin') WM="KWin";;
						'metacity') WM="Metacity";;
						'monsterwm') WM="monsterwm";;
						'musca') WM="Musca";;
						'notion') WM="Notion";;
						'openbox') WM="OpenBox";;
						'pekwm') WM="PekWM";;
						'ratpoison') WM="Ratpoison";;
						'sawfish') WM="Sawfish";;
						'scrotwm') WM="ScrotWM";;
						'spectrwm') WM="SpectrWM";;
						'stumpwm') WM="StumpWM";;
						'subtle') WM="subtle";;
						'sway') WM="sway";;
						'swm') WM="swm";;
						'twin') WM="TWin";;
						'wmaker') WM="WindowMaker";;
						'wmfs') WM="WMFS";;
						'wmii') WM="wmii";;
						'xfwm4') WM="Xfwm4";;
						'xmonad.*') WM="XMonad";;
					esac
				fi

				if [[ ${WM} != "Not Found" ]]; then
					break 1
				fi
			done

			if [[ ${WM} == "Not Found" ]]; then
				if type -p xprop >/dev/null 2>&1; then
					WM=$(xprop -root _NET_SUPPORTING_WM_CHECK)
					if [[ "$WM" =~ 'not found' ]]; then
						WM="Not Found"
					elif [[ "$WM" =~ 'Not found' ]]; then
						WM="Not Found"
					elif [[ "$WM" =~ '[Ii]nvalid window id format' ]]; then
						WM="Not Found"
					elif [[ "$WM" =~ "no such" ]]; then
						WM="Not Found"
					else
						WM=${WM//* }
						WM=$(xprop -id ${WM} 8s _NET_WM_NAME)
						WM=$(echo $(WM=${WM//*= }; echo ${WM//\"}))
					fi
				fi
			else
				if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
					if [[ ${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -gt 1 ]] || [[ ${BASH_VERSINFO[0]} -gt 4 ]]; then
						WM=${WM,,}
					else
						WM="$(tr '[:upper:]' '[:lower:]' <<< ${WM})"
					fi
				else
					WM="$(tr '[:upper:]' '[:lower:]' <<< ${WM})"
				fi
				case ${WM} in
					*'gala'*) WM="Gala";;
					'2bwm') WM="2bwm";;
					'awesome') WM="Awesome";;
					'beryl') WM="Beryl";;
					'blackbox') WM="BlackBox";;
					'budgiewm') WM="BudgieWM";;
					'chromeos-wm') WM="chromeos-wm";;
					'cinnamon') WM="Cinnamon";;
					'compiz') WM="Compiz";;
					'deepin-wm') WM="Deepin WM";;
					'dminiwm') WM="dminiwm";;
					'dwm') WM="dwm";;
					'e16') WM="E16";;
					'echinus') WM="echinus";;
					'emerald') WM="Emerald";;
					'enlightenment') WM="E17";;
					'fluxbox') WM="FluxBox";;
					'flwm'|'flwm_topside') WM="FLWM";;
					'fvwm') WM="FVWM";;
					'gnome shell'*) WM="Mutter";;
					'herbstluftwm') WM="herbstluftwm";;
					'howm') WM="howm";;
					'i3') WM="i3";;
					'icewm') WM="IceWM";;
					'kwin') WM="KWin";;
					'metacity') WM="Metacity";;
					'monsterwm') WM="monsterwm";;
					'muffin') WM="Muffin";;
					'musca') WM="Musca";;
					'mutter'*) WM="Mutter";;
					'notion') WM="Notion";;
					'openbox') WM="OpenBox";;
					'pekwm') WM="PekWM";;
					'ratpoison') WM="Ratpoison";;
					'sawfish') WM="Sawfish";;
					'scrotwm') WM="ScrotWM";;
					'spectrwm') WM="SpectrWM";;
					'stumpwm') WM="StumpWM";;
					'subtle') WM="subtle";;
					'sway') WM="sway";;
					'swm') WM="swm";;
					'twin') WM="TWin";;
					'wmaker') WM="WindowMaker";;
					'wmfs') WM="WMFS";;
					'wmii') WM="wmii";;
					'xfwm4') WM="Xfwm4";;
					'xmonad') WM="XMonad";;
				esac
			fi
		fi
	elif [[ ${distro} == "Mac OS X" && "${WM}" == "Not Found" ]]; then
		if ps -U ${USER} | grep Finder >/dev/null 2>&1; then
			WM="Quartz Compositor"
		fi
	elif [[ "${distro}" == "Cygwin" || "${distro}" == "Msys" ]]; then
		bugn=$(tasklist | grep -o 'bugn' | tr -d '\r \n')
		wind=$(tasklist | grep -o 'Windawesome' | tr -d '\r \n')
		if [ "$bugn" = "bugn" ]; then WM="bug.n"
		elif [ "$wind" = "Windawesome" ]; then WM="Windawesome"
		else WM="DWM"; fi
	fi
	verboseOut "Finding window manager...found as '$WM'"
}
# WM Detection - End


# WM Theme Detection - BEGIN
detectwmtheme () {
	Win_theme="Not Found"
	case $WM in
		'2bwm') Win_theme="Not Applicable";;
		'9wm') Win_theme="Not Applicable";;
		'Awesome') if [ -f ${XDG_CONFIG_HOME:-${HOME}/.config}/awesome/rc.lua ]; then Win_theme="$(grep -e '^[^-].*\(theme\|beautiful\).*lua' ${XDG_CONFIG_HOME:-${HOME}/.config}/awesome/rc.lua | grep '[a-zA-Z0-9]\+/[a-zA-Z0-9]\+.lua' -o | cut -d'/' -f1 | head -n1)"; fi;;
		'BlackBox') if [ -f $HOME/.blackboxrc ]; then Win_theme="$(awk -F"/" '/styleFile/ {print $NF}' $HOME/.blackboxrc)"; fi;;
		'Beryl') Win_theme="Not Applicable";;
		'bspwm') Win_theme="Not Applicable";;
		'BudgieWM')
			Win_theme="$(gsettings get org.gnome.desktop.wm.preferences theme)"
			Win_theme="${Win_theme//\'}"
		;;
		'Cinnamon'|'Muffin')
			de_theme="$(gsettings get org.cinnamon.theme name)"
			de_theme=${de_theme//"'"}
			win_theme="$(gsettings get org.cinnamon.desktop.wm.preferences theme)"
			win_theme=${win_theme//"'"}
			Win_theme="${de_theme} (${win_theme})"
		;;
		'Compiz'|'Mutter'*|'GNOME Shell'|'Gala')
			if type -p gsettings >/dev/null 2>&1; then
				Win_theme="$(gsettings get org.gnome.shell.extensions.user-theme name 2>/dev/null)"
				if [[ -z "$Win_theme" ]]; then
					Win_theme="$(gsettings get org.gnome.desktop.wm.preferences theme)"
				fi
				Win_theme=${Win_theme//"'"}
			elif type -p gconftool-2 >/dev/null 2>&1; then
				Win_theme=$(gconftool-2 -g /apps/metacity/general/theme)
			fi
		;;
		'Deepin WM')
			if type -p gsettings >/dev/null 2>&1; then
				Win_theme="$(gsettings get com.deepin.wrap.gnome.desktop.wm.preferences theme)"
				Win_theme=${Win_theme//"'"}
			fi
		;;
		'dminiwm') Win_theme="Not Applicable";;
		'dwm') Win_theme="Not Applicable";;
		'E16') Win_theme="$(awk -F"= " '/theme.name/ {print $2}' $HOME/.e16/e_config--0.0.cfg)";;
		'E17'|'Enlightenment')
			if [ "$(which eet 2>/dev/null)" ]; then
				econfig="$(eet -d $HOME/.e/e/config/standard/e.cfg config | awk '/value \"file\" string.*.edj/{ print $4 }')"
				econfigend="${econfig##*/}"
				Win_theme=${econfigend%.*}
			fi
		;;
		#E17 doesn't store cfg files in text format so for now get the profile as opposed to theme. atyoung
		#TODO: Find a way to extract and read E17 .cfg files ( google seems to have nothing ). atyoung
		'E17') Win_theme=${E_CONF_PROFILE};;
		'echinus') Win_theme="Not Applicable";;
		'Emerald') if [ -f $HOME/.emerald/theme/theme.ini ]; then Win_theme="$(for a in /usr/share/emerald/themes/* $HOME/.emerald/themes/*; do cmp "$HOME/.emerald/theme/theme.ini" "$a/theme.ini" &>/dev/null && basename "$a"; done)"; fi;;
		'Finder') Win_theme="Not Applicable";;
		'FluxBox'|'Fluxbox') if [ -f $HOME/.fluxbox/init ]; then Win_theme="$(awk -F"/" '/styleFile/ {print $NF}' $HOME/.fluxbox/init)"; fi;;
		'FVWM') Win_theme="Not Applicable";;
		'howm') Win_theme="Not Applicable";;
		'i3') Win_theme="Not Applicable";;
		'IceWM') if [ -f $HOME/.icewm/theme ]; then Win_theme="$(awk -F"[\",/]" '!/#/ {print $2}' $HOME/.icewm/theme)"; fi;;
		'KWin'*)
			if [[ -z $KDE_CONFIG_DIR ]]; then
				if type -p kde5-config >/dev/null 2>&1; then
					KDE_CONFIG_DIR=$(kde5-config --localprefix)
				elif type -p kde4-config >/dev/null 2>&1; then
					KDE_CONFIG_DIR=$(kde4-config --localprefix)
				elif type -p kde-config >/dev/null 2>&1; then
					KDE_CONFIG_DIR=$(kde-config --localprefix)
				fi
			fi

			if [[ -n $KDE_CONFIG_DIR ]]; then
				Win_theme="Not Applicable"
				KDE_CONFIG_DIR=${KDE_CONFIG_DIR%/}
				if [[ -f $KDE_CONFIG_DIR/share/config/kwinrc ]]; then
					Win_theme="$(awk '/PluginLib=kwin3_/{gsub(/PluginLib=kwin3_/,"",$0); print $0; exit}' $KDE_CONFIG_DIR/share/config/kwinrc)"
					if [[ -z "$Win_theme" ]]; then Win_theme="Not Applicable"; fi
				fi
				if [[ "$Win_theme" == "Not Applicable" ]]; then
					if [[ -f $KDE_CONFIG_DIR/share/config/kdebugrc ]]; then
						Win_theme="$(awk '/(decoration)/ {gsub(/\[/,"",$1); print $1; exit}' $KDE_CONFIG_DIR/share/config/kdebugrc)"
						if [[ -z "$Win_theme" ]]; then Win_theme="Not Applicable"; fi
					fi
				fi
				if [[ "$Win_theme" == "Not Applicable" ]]; then
					if [[ -f $KDE_CONFIG_DIR/share/config/kdeglobals ]]; then
						Win_theme="$(awk '/\[General\]/ {flag=1;next} /^$/{flag=0} flag {print}' $KDE_CONFIG_DIR/share/config/kdeglobals | grep -oP 'Name=\K.*')"
						if [[ -z "$Win_theme" ]]; then Win_theme="Not Applicable"; fi
					fi
				fi

				if [[ "$Win_theme" != "Not Applicable" ]]; then
					if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
						if [[ ${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -gt 1 ]] || [[ ${BASH_VERSINFO[0]} -gt 4 ]]; then
							Win_theme="${Win_theme^}"
						else
							Win_theme="$(tr '[:lower:]' '[:upper:]' <<< ${Win_theme:0:1})${Win_theme:1}"
						fi
					else
						Win_theme="$(tr '[:lower:]' '[:upper:]' <<< ${Win_theme:0:1})${Win_theme:1}"
					fi
				fi
			fi
		;;
		'Marco')
			Win_theme="$(gsettings get org.mate.Marco.general theme)"
			Win_theme=${Win_theme//"'"}
		;;
		'Metacity') if [ "`gconftool-2 -g /apps/metacity/general/theme`" ]; then Win_theme="$(gconftool-2 -g /apps/metacity/general/theme)"; fi ;;
		'monsterwm') Win_theme="Not Applicable";;
		'Musca') Win_theme="Not Applicable";;
		'Notion') Win_theme="Not Applicable";;
		'OpenBox'|'Openbox')
			if [ -f ${XDG_CONFIG_HOME:-${HOME}/.config}/openbox/rc.xml ]; then
				Win_theme="$(awk -F"[<,>]" '/<theme/ { getline; print $3 }' ${XDG_CONFIG_HOME:-${HOME}/.config}/openbox/rc.xml)";
			elif [[ -f ${XDG_CONFIG_HOME:-${HOME}/.config}/openbox/lxde-rc.xml && $DE == "LXDE" ]]; then
				Win_theme="$(awk -F"[<,>]" '/<theme/ { getline; print $3 }' ${XDG_CONFIG_HOME:-${HOME}/.config}/openbox/lxde-rc.xml)";
			fi
		;;
		'PekWM') if [ -f $HOME/.pekwm/config ]; then Win_theme="$(awk -F"/" '/Theme/ {gsub(/\"/,""); print $NF}' $HOME/.pekwm/config)"; fi;;
		'Ratpoison') Win_theme="Not Applicable";;
		'Sawfish') Win_theme="$(awk -F")" '/\(quote default-frame-style/{print $2}' $HOME/.sawfish/custom | sed 's/ (quote //')";;
		'ScrotWM') Win_theme="Not Applicable";;
		'SpectrWM') Win_theme="Not Applicable";;
		'swm') Win_theme="Not Applicable";;
		'subtle') Win_theme="Not Applicable";;
		'TWin')
			if [[ -z $TDE_CONFIG_DIR ]]; then
				if type -p tde-config >/dev/null 2>&1; then
					TDE_CONFIG_DIR=$(tde-config --localprefix)
				fi
			fi
			if [[ -n $TDE_CONFIG_DIR ]]; then
				TDE_CONFIG_DIR=${TDE_CONFIG_DIR%/}
				if [[ -f $TDE_CONFIG_DIR/share/config/kcmthememanagerrc ]]; then
					Win_theme=$(awk '/CurrentTheme=/ {gsub(/CurrentTheme=/,"",$0); print $0; exit}' $TDE_CONFIG_DIR/share/config/kcmthememanagerrc)
				fi
				if [[ -z $Win_theme ]]; then
					Win_theme="Not Applicable"
				fi
			fi
		;;
		'WindowMaker') Win_theme="Not Applicable";;
		'WMFS') Win_theme="Not Applicable";;
		'wmii') Win_theme="Not Applicable";;
		'Xfwm4') if [ -f ${XDG_CONFIG_HOME:-${HOME}/.config}/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml ]; then Win_theme="$(xfconf-query -c xfwm4 -p /general/theme)"; fi;;
		'XMonad') Win_theme="Not Applicable";;
	esac
	if [[ "${distro}" == "Mac OS X" ]]; then
		themeNumber="$(defaults read NSGlobalDomain AppleAquaColorVariant 2>/dev/null)"
		if [ "${themeNumber}" == "1" ] || [ "${themeNumber}x" == "x" ]; then
			Win_theme="Blue"
		else
			Win_theme="Graphite"
		fi
	elif [[ "${distro}" == "Cygwin" || "${distro}" == "Msys" ]]; then
		if [[ "${distro}" == "Msys" ]]; then
			themeFile="$(reg query 'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes' //v 'CurrentTheme')"
		else
			themeFile="$(reg query 'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes' /v 'CurrentTheme')"
		fi
		Win_theme=$(echo $themeFile| awk -F"\\" '{print $NF}' | sed 's|\.theme$||')
	fi

	verboseOut "Finding window manager theme...found as '$Win_theme'"
}
# WM Theme Detection - END

# GTK Theme\Icon\Font Detection - BEGIN
detectgtk () {
	gtk2Theme="Not Found"
	gtk3Theme="Not Found"
	gtkIcons="Not Found"
	gtkFont="Not Found"
	# Font detection (OS X)
	if [[ ${distro} == "Mac OS X" ]]; then
		gtk2Theme="Not Applicable"
		gtk3Theme="Not Applicable"
		gtkIcons="Not Applicable"
		if ps -U ${USER} | grep [F]inder >/dev/null 2>&1; then
			if [ -f ~/Library/Preferences/com.googlecode.iterm2.plist ]; then
				# iTerm2

				iterm2_theme_uuid=$(defaults read com.googlecode.iTerm2 "Default Bookmark Guid")

				OLD_IFS=$IFS
				IFS=$'\n'
				iterm2_theme_info=($(defaults read com.googlecode.iTerm2 "New Bookmarks" | grep -e Guid -e "Normal Font"))
				IFS=$OLD_IFS

				for i in $(seq 0 $((${#iterm2_theme_info[*]}/2-1))); do
					found_uuid=$(str1=${iterm2_theme_info[$i*2]};echo ${str1:16:${#str1}-16-2})
					if [[ $found_uuid == $iterm2_theme_uuid ]]; then
						gtkFont=$(str2=${iterm2_theme_info[$i*2+1]};echo ${str2:25:${#str2}-25-2})
						break
					fi
				done
			else
				# Terminal.app

				termapp_theme_name=$(defaults read com.apple.Terminal "Default Window Settings")

				OLD_IFS=$IFS
				IFS=$'\n'
				termapp_theme_info=($(defaults read com.apple.Terminal "Window Settings" | grep -e "name = " -e "Font = "))
				IFS=$OLD_IFS

				for i in $(seq 0 $((${#termapp_theme_info[*]}/2-1))); do
					found_name=$(str1=${termapp_theme_info[$i*2+1]};echo ${str1:15:${#str1}-15-1})
					if [[ $found_name == $termapp_theme_name ]]; then
						gtkFont=$(str2=${termapp_theme_info[$i*2]};echo ${str2:288:${#str2}-288})
						gtkFont=$(echo ${gtkFont%%[dD]2*;} | xxd -r -p)
						break
					fi
				done
			fi
		fi
	else
		case $DE in
			'KDE'*) # Desktop Environment found as "KDE"
				if type - p kde4-config >/dev/null 2>&1; then
					KDE_CONFIG_DIR=$(kde4-config --localprefix)
					if [[ -d ${KDE_CONFIG_DIR} ]]; then
						if [[ -f "${KDE_CONFIG_DIR}/share/config/kdeglobals" ]]; then
							KDE_CONFIG_FILE="${KDE_CONFIG_DIR}/share/config/kdeglobals"
						fi
					fi
				elif type -p kde5-config >/dev/null 2>&1; then
					KDE_CONFIG_DIR=$(kde5-config --localprefix)
					if [[ -d ${KDE_CONFIG_DIR} ]]; then
						if [[ -f "${KDE_CONFIG_DIR}/share/config/kdeglobals" ]]; then
							KDE_CONFIG_FILE="${KDE_CONFIG_DIR}/share/config/kdeglobals"
						fi
					fi
				elif type -p kde-config >/dev/null 2>&1; then
					KDE_CONFIG_DIR=$(kde-config --localprefix)
					if [[ -d ${KDE_CONFIG_DIR} ]]; then
						if [[ -f "${KDE_CONFIG_DIR}/share/config/kdeglobals" ]]; then
							KDE_CONFIG_FILE="${KDE_CONFIG_DIR}/share/config/kdeglobals"
						fi
					fi
				fi

				if [[ -n ${KDE_CONFIG_FILE} ]]; then
					if grep -q "widgetStyle=" "${KDE_CONFIG_FILE}"; then
						gtk2Theme=$(awk -F"=" '/widgetStyle=/ {print $2}' "${KDE_CONFIG_FILE}")
					elif grep -q "colorScheme=" "${KDE_CONFIG_FILE}"; then
						gtk2Theme=$(awk -F"=" '/colorScheme=/ {print $2}' "${KDE_CONFIG_FILE}")
					fi

					if grep -q "Theme=" "${KDE_CONFIG_FILE}"; then
						gtkIcons=$(awk -F"=" '/Theme=/ {print $2}' "${KDE_CONFIG_FILE}")
					fi

					if grep -q "Font=" "${KDE_CONFIG_FILE}"; then
						gtkFont=$(awk -F"=" '/font=/ {print $2}' "${KDE_CONFIG_FILE}")
					fi
				fi

				if [[ -f $HOME/.gtkrc-2.0 ]]; then
					gtk2Theme=$(grep '^gtk-theme-name' $HOME/.gtkrc-2.0 | awk -F'=' '{print $2}')
					gtk2Theme=${gtk2Theme//\"/}
					gtkIcons=$(grep '^gtk-icon-theme-name' $HOME/.gtkrc-2.0 | awk -F'=' '{print $2}')
					gtkIcons=${gtkIcons//\"/}
					gtkFont=$(grep 'font_name' $HOME/.gtkrc-2.0 | awk -F'=' '{print $2}')
					gtkFont=${gtkFont//\"/}
				fi

				if [[ -f $HOME/.config/gtk-3.0/settings.ini ]]; then
					gtk3Theme=$(grep '^gtk-theme-name=' $HOME/.config/gtk-3.0/settings.ini | awk -F'=' '{print $2}')
				fi
			;;
			'Cinnamon'*) # Desktop Environment found as "Cinnamon"
				if type -p gsettings >/dev/null 2>&1; then
					gtk3Theme=$(gsettings get org.cinnamon.desktop.interface gtk-theme)
					gtk3Theme=${gtk3Theme//"'"}
					gtk2Theme=${gtk3Theme}

					gtkIcons=$(gsettings get org.cinnamon.desktop.interface icon-theme)
					gtkIcons=${gtkIcons//"'"}
					gtkFont=$(gsettings get org.cinnamon.desktop.interface font-name)
					gtkFont=${gtkFont//"'"}
					if [ "$background_detect" == "1" ]; then gtkBackground=$(gsettings get org.gnome.desktop.background picture-uri); fi
				fi
			;;
			'GNOME'*|'Unity'*|'Budgie') # Desktop Environment found as "GNOME"
				if type -p gsettings >/dev/null 2>&1; then
					gtk3Theme=$(gsettings get org.gnome.desktop.interface gtk-theme)
					gtk3Theme=${gtk3Theme//"'"}
					gtk2Theme=${gtk3Theme}
					gtkIcons=$(gsettings get org.gnome.desktop.interface icon-theme)
					gtkIcons=${gtkIcons//"'"}
					gtkFont=$(gsettings get org.gnome.desktop.interface font-name)
					gtkFont=${gtkFont//"'"}
					if [ "$background_detect" == "1" ]; then gtkBackground=$(gsettings get org.gnome.desktop.background picture-uri); fi
				elif type -p gconftool-2 >/dev/null 2>&1; then
					gtk2Theme=$(gconftool-2 -g /desktop/gnome/interface/gtk_theme)
					gtkIcons=$(gconftool-2 -g /desktop/gnome/interface/icon_theme)
					gtkFont=$(gconftool-2 -g /desktop/gnome/interface/font_name)
					if [ "$background_detect" == "1" ]; then
						gtkBackgroundFull=$(gconftool-2 -g /desktop/gnome/background/picture_filename)
						gtkBackground=$(echo "$gtkBackgroundFull" | awk -F"/" '{print $NF}')
					fi
				fi
			;;
			'MATE'*) # MATE desktop environment
				#if type -p gsettings >/dev/null 2&>1; then
				gtk3Theme=$(gsettings get org.mate.interface gtk-theme)
				# gtk3Theme=${gtk3Theme//"'"}
				gtk2Theme=${gtk3Theme}
				gtkIcons=$(gsettings get org.mate.interface icon-theme)
				gtkIcons=${gtkIcons//"'"}
				gtkFont=$(gsettings get org.mate.interface font-name)
				gtkFont=${gtkFont//"'"}
				#fi
			;;
			'XFCE'*) # Desktop Environment found as "XFCE"
				if type -p xfconf-query >/dev/null 2>&1; then
					gtk2Theme=$(xfconf-query -c xsettings -p /Net/ThemeName)
				fi

				if type -p xfconf-query >/dev/null 2>&1; then
					gtkIcons=$(xfconf-query -c xsettings -p /Net/IconThemeName)
				fi

				if type -p xfconf-query >/dev/null 2>&1; then
					gtkFont=$(xfconf-query -c xsettings -p /Gtk/FontName)
				fi
			;;
			'LXDE'*)
				config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
				if [ -f "$config_home/lxde/config" ]; then
					lxdeconf="/lxde/config"
				elif [ "$distro" == "Trisquel" ] || [ "$distro" == "FreeBSD" ]; then
					lxdeconf=""
				elif [ -f "$config_home/lxsession/Lubuntu/desktop.conf" ]; then
					lxdeconf="/lxsession/Lubuntu/desktop.conf"
				else
					lxdeconf="/lxsession/LXDE/desktop.conf"
				fi

				if grep -q "sNet\/ThemeName" "${config_home}${lxdeconf}" 2>/dev/null; then
					gtk2Theme=$(awk -F'=' '/sNet\/ThemeName/ {print $2}' ${config_home}${lxdeconf})
				fi

				if grep -q IconThemeName "${config_home}${lxdeconf}" 2>/dev/null; then
					gtkIcons=$(awk -F'=' '/sNet\/IconThemeName/ {print $2}' ${config_home}${lxdeconf})
				fi

				if grep -q FontName "${config_home}${lxdeconf}" 2>/dev/null; then
					gtkFont=$(awk -F'=' '/sGtk\/FontName/ {print $2}' ${config_home}${lxdeconf})
 				fi
			;;

			# /home/me/.config/rox.sourceforge.net/ROX-Session/Settings.xml

			*)	# Lightweight or No DE Found
				if [ -f "$HOME/.gtkrc-2.0" ]; then
					if grep -q gtk-theme $HOME/.gtkrc-2.0; then
						gtk2Theme=$(awk -F'"' '/^gtk-theme/ {print $2}' $HOME/.gtkrc-2.0)
					fi

					if grep -q icon-theme $HOME/.gtkrc-2.0; then
						gtkIcons=$(awk -F'"' '/^gtk-icon-theme/ {print $2}' $HOME/.gtkrc-2.0)
					fi

					if grep -q font $HOME/.gtkrc-2.0; then
						gtkFont=$(awk -F'"' '/^gtk-font-name/ {print $2}' $HOME/.gtkrc-2.0)
					fi
				fi
				# $HOME/.gtkrc.mine theme detect only
				if [[ -f "$HOME/.gtkrc.mine" ]]; then
					minegtkrc="$HOME/.gtkrc.mine"
				elif [[ -f "$HOME/.gtkrc-2.0.mine" ]]; then
					minegtkrc="$HOME/.gtkrc-2.0.mine"
				fi
				if [ -f "$minegtkrc" ]; then
					if grep -q "^include" "$minegtkrc"; then
						gtk2Theme=$(grep '^include.*gtkrc' "$minegtkrc" | awk -F "/" '{ print $5 }')
					fi
					if grep -q "^gtk-icon-theme-name" "$minegtkrc"; then
						gtkIcons=$(grep '^gtk-icon-theme-name' "$minegtkrc" | awk -F '"' '{print $2}')
					fi
				fi
				# /etc/gtk-2.0/gtkrc compatability
				if [[ -f /etc/gtk-2.0/gtkrc && ! -f "$HOME/.gtkrc-2.0" && ! -f "$HOME/.gtkrc.mine" && ! -f "$HOME/.gtkrc-2.0.mine" ]]; then
					if grep -q gtk-theme-name /etc/gtk-2.0/gtkrc; then
						gtk2Theme=$(awk -F'"' '/^gtk-theme-name/ {print $2}' /etc/gtk-2.0/gtkrc)
					fi
					if grep -q gtk-fallback-theme-name /etc/gtk-2.0/gtkrc  && ! [ "x$gtk2Theme" = "x" ]; then
						gtk2Theme=$(awk -F'"' '/^gtk-fallback-theme-name/ {print $2}' /etc/gtk-2.0/gtkrc)
					fi

					if grep -q icon-theme /etc/gtk-2.0/gtkrc; then
						gtkIcons=$(awk -F'"' '/^icon-theme/ {print $2}' /etc/gtk-2.0/gtkrc)
					fi
					if  grep -q gtk-fallback-icon-theme /etc/gtk-2.0/gtkrc  && ! [ "x$gtkIcons" = "x" ]; then
						gtkIcons=$(awk -F'"' '/^gtk-fallback-icon-theme/ {print $2}' /etc/gtk-2.0/gtkrc)
					fi

					if grep -q font /etc/gtk-2.0/gtkrc; then
						gtkFont=$(awk -F'"' '/^gtk-font-name/ {print $2}' /etc/gtk-2.0/gtkrc)
					fi
				fi

				# EXPERIMENTAL gtk3 Theme detection
				if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
					if grep -q gtk-theme-name $HOME/.config/gtk-3.0/settings.ini; then
						gtk3Theme=$(awk -F'=' '/^gtk-theme-name/ {print $2}' $HOME/.config/gtk-3.0/settings.ini)
					fi
				fi

				# Proper gtk3 Theme detection
				#if type -p gsettings >/dev/null 2>&1; then
				#	gtk3Theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null)
				#	gtk3Theme=${gtk3Theme//"'"}
				#fi

				# ROX-Filer icon detect only
				if [ -a "${XDG_CONFIG_HOME:-${HOME}/.config}/rox.sourceforge.net/ROX-Filer/Options" ]; then
					gtkIcons=$(awk -F'[>,<]' '/icon_theme/ {print $3}' ${XDG_CONFIG_HOME:-${HOME}/.config}/rox.sourceforge.net/ROX-Filer/Options)
				fi

				# E17 detection
				if [ $E_ICON_THEME ]; then
					gtkIcons=${E_ICON_THEME}
					gtk2Theme="Not available."
					gtkFont="Not available."
				fi

				# Background Detection (feh, nitrogen)
				if [ "$background_detect" == "1" ]; then
					if [ -a $HOME/.fehbg ]; then
						gtkBackgroundFull=$(awk -F"'" '/feh --bg/{print $2}' $HOME/.fehbg 2>/dev/null)
						gtkBackground=$(echo "$gtkBackgroundFull" | awk -F"/" '{print $NF}')
					elif [ -a ${XDG_CONFIG_HOME:-${HOME}/.config}/nitrogen/bg-saved.cfg ]; then
						gtkBackground=$(awk -F"/" '/file=/ {print $NF}' ${XDG_CONFIG_HOME:-${HOME}/.config}/nitrogen/bg-saved.cfg)
					fi
				fi

				if [[ "$distro" == "Cygwin" || "$distro" == "Msys" ]]; then
					if [ "$gtkFont" == "Not Found" ]; then
						if [ -f "$HOME/.minttyrc" ]; then
							gtkFont="$(grep '^Font=.*' "$HOME/.minttyrc" | grep -o '[0-9A-z ]*$')"
						fi
					fi
				fi
			;;
		esac
	fi
	verboseOut "Finding GTK2 theme...found as '$gtk2Theme'"
	verboseOut "Finding GTK3 theme...found as '$gtk3Theme'"
	verboseOut "Finding icon theme...found as '$gtkIcons'"
	verboseOut "Finding user font...found as '$gtkFont'"
	[[ $gtkBackground ]] && verboseOut "Finding background...found as '$gtkBackground'"
}
# GTK Theme\Icon\Font Detection - END

# Android-specific detections
detectdroid () {
	distro_ver=$(getprop ro.build.version.release)

	hostname=$(getprop net.hostname)

	_device=$(getprop ro.product.device)
	_model=$(getprop ro.product.model)
	device="${_model} (${_device})"

	if [[ $(getprop ro.build.host) == "cyanogenmod" ]]; then
		rom=$(getprop ro.cm.version)
	else
		rom=$(getprop ro.build.display.id)
	fi

	baseband=$(getprop ro.baseband)

	cpu=$(grep '^Processor' /proc/cpuinfo)
	cpu=$(echo "$cpu" | sed 's/Processor.*: //')
}


#######################
# End Detection Phase
#######################

takeShot () {
	if [[ -z $screenCommand ]]; then
		shotfiles[1]=${shotfile}
		if [ "$distro" == "Mac OS X" ]; then
			displays="$(system_profiler SPDisplaysDataType | grep 'Resolution:' | wc -l | tr -d ' ')"
			for (( i=2; i<=$displays; i++))
			do
				shotfiles[$i]="$(echo ${shotfile} | sed "s/\(.*\)\./\1_${i}./")"
			done
			printf "Taking shot in 3.. "; sleep 1; printf "2.. "; sleep 1; printf "1.. "; sleep 1; printf "0.\n"; screencapture -x ${shotfiles[@]} &> /dev/null
		else
			if type -p scrot >/dev/null 2>&1; then
				scrot -cd3 "${shotfile}"
			else
				errorOut "Cannot take screenshot! \`scrot' not in \$PATH"
			fi
		fi
		if [ -f "${shotfile}" ]; then
			verboseOut "Screenshot saved at '${shotfiles[@]}'"
			if [[ "${upload}" == "1" ]]; then
				if type -p curl >/dev/null 2>&1; then
					printf "${bold}==>${c0}  Uploading your screenshot now..."
					case "${uploadLoc}" in
						'teknik')
							baseurl='https://u.teknik.io'
							uploadurl='https://api.teknik.io/upload/post'
							ret=$(curl -sf -F file="@${shotfiles[@]}" ${uploadurl})
							desturl="${ret##*url\":\"}"
							desturl="${desturl%%\"*}"
							desturl="${desturl//\\}"
						;;
						'mediacrush')
							baseurl='https://mediacru.sh'
							uploadurl='https://mediacru.sh/api/upload/file'
							ret=$(curl -sf -F file="@${shotfiles[@]};type=image/png" ${uploadurl})
							filehash=$(echo "${ret}" | grep "hash" | cut -d '"' -f4)
							desturl="${baseurl}/${filehash}"
						;;
						'imgur')
							baseurl='http://imgur.com'
							uploadurl='http://imgur.com/upload'
							ret=$(curl -sf -F file="@${shotfiles[@]}" ${uploadurl})
							filehash="${ret##*hash\":\"}"
							filehash="${filehash%%\"*}"
							desturl="${baseurl}/${filehash}"
						;;
						'hmp')
							baseurl='http://i.hmp.me/m'
							uploadurl='http://hmp.me/ap/?uf=1'
							ret=$(curl -sf -F a="@${shotfiles[@]};type=image/png" ${uploadurl})
							desturl="${ret##*img_path\":\"}"
							desturl="${desturl%%\"*}"
							desturl="${desturl//\\}"
						;;
						'local-example')
							baseurl="http://www.example.com"
							serveraddr="www.example.com"
							scptimeout="20"
							serverdir="/path/to/directory"
							scp -qo ConnectTimeout="${scptimeout}" "${shotfiles[@]}" "${serveraddr}:${serverdir}"
							desturl="${baseurl}/${shotfile}"
						;;
					esac
					printf "your screenshot can be viewed at ${desturl}\n"
				else
					errorOut "Cannot upload screenshot! \`curl' not in \$PATH"
				fi
			fi
		else
			if type -p scrot >/dev/null 2>&1; then
				errorOut "ERROR: Problem saving screenshot to ${shotfiles[@]}"
			fi
		fi
	else
		$screenCommand
	fi
}



asciiText () {
# Distro logos and ASCII outputs
	if [[ "$asc_distro" ]]; then myascii="${asc_distro}"
	elif [[ "$art" ]]; then myascii="custom"
	elif [[ "$fake_distro" ]]; then myascii="${fake_distro}"
	else myascii="${distro}"; fi
	case ${myascii} in
		"custom") source "$art" ;;

		"Alpine Linux")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light blue') # Light
				c2=$(getColor 'blue') # Dark
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}        ................          %s"
"${c1}       ∴::::::::::::::::∴         %s"
"${c1}      ∴::::::::::::::::::∴        %s"
"${c1}     ∴::::::::::::::::::::∴       %s"
"${c1}    ∴:::::::. :::::':::::::∴      %s"
"${c1}   ∴:::::::.   ;::; ::::::::∴     %s"
"${c1}  ∴::::::;      ∵     :::::::∴    %s"
"${c1} ∴:::::.     .         .::::::∴   %s"
"${c1} ::::::     :::.    .    ::::::   %s"
"${c1} ∵::::     ::::::.  ::.   ::::∵   %s"
"${c1}  ∵:..   .:;::::::: :::.  :::∵    %s"
"${c1}   ∵::::::::::::::::::::::::∵     %s"
"${c1}    ∵::::::::::::::::::::::∵      %s"
"${c1}     ∵::::::::::::::::::::∵       %s"
"${c1}      ::::::::::::::::::::        %s"
"${c1}       ∵::::::::::::::::∵         %s")
		;;

		"Arch Linux - Old")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light blue') # Light Blue
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c1              __                     %s"
"$c1          _=(SDGJT=_                 %s"
"$c1        _GTDJHGGFCVS)                %s"
"$c1       ,GTDJGGDTDFBGX0               %s"
"$c1      JDJDIJHRORVFSBSVL$c2-=+=,_        %s"
"$c1     IJFDUFHJNXIXCDXDSV,$c2  \"DEBL      %s"
"$c1    [LKDSDJTDU=OUSCSBFLD.$c2   '?ZWX,   %s"
"$c1   ,LMDSDSWH'     \`DCBOSI$c2     DRDS], %s"
"$c1   SDDFDFH'         !YEWD,$c2   )HDROD  %s"
"$c1  !KMDOCG            &GSU|$c2\_GFHRGO\'  %s"
"$c1  HKLSGP'$c2           __$c1\TKM0$c2\GHRBV)'  %s"
"$c1 JSNRVW'$c2       __+MNAEC$c1\IOI,$c2\BN'     %s"
"$c1 HELK['$c2    __,=OFFXCBGHC$c1\FD)         %s"
"$c1 ?KGHE $c2\_-#DASDFLSV='$c1    'EF         %s"
"$c1 'EHTI                    !H         %s"
"$c1  \`0F'                    '!         %s"
"                                     %s"
"                                     %s")
		;;

		"Arch Linux")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light cyan') # Light
				c2=$(getColor 'cyan') # Dark
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="1"
			fulloutput=(
"${c1}                   -\`"
"${c1}                  .o+\`                %s"
"${c1}                 \`ooo/                %s"
"${c1}                \`+oooo:               %s"
"${c1}               \`+oooooo:              %s"
"${c1}               -+oooooo+:             %s"
"${c1}             \`/:-:++oooo+:            %s"
"${c1}            \`/++++/+++++++:           %s"
"${c1}           \`/++++++++++++++:          %s"
"${c1}          \`/+++o"${c2}"oooooooo"${c1}"oooo/\`        %s"
"${c2}         "${c1}"./"${c2}"ooosssso++osssssso"${c1}"+\`       %s"
"${c2}        .oossssso-\`\`\`\`/ossssss+\`      %s"
"${c2}       -osssssso.      :ssssssso.     %s"
"${c2}      :osssssss/        osssso+++.    %s"
"${c2}     /ossssssss/        +ssssooo/-    %s"
"${c2}   \`/ossssso+/:-        -:/+osssso+-  %s"
"${c2}  \`+sso+:-\`                 \`.-/+oso: %s"
"${c2} \`++:.                           \`-/+/%s"
"${c2} .\`                                 \`/%s")
		;;

		"Mint")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light green') # Bold Green
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"                                      %s"
"$c2 MMMMMMMMMMMMMMMMMMMMMMMMMmds+.       %s"
"$c2 MMm----::-://////////////oymNMd+\`    %s"
"$c2 MMd      "$c1"/++                "$c2"-sNMd:   %s"
"$c2 MMNso/\`  "$c1"dMM    \`.::-. .-::.\` "$c2".hMN:  %s"
"$c2 ddddMMh  "$c1"dMM   :hNMNMNhNMNMNh: "$c2"\`NMm  %s"
"$c2     NMm  "$c1"dMM  .NMN/-+MMM+-/NMN\` "$c2"dMM  %s"
"$c2     NMm  "$c1"dMM  -MMm  \`MMM   dMM. "$c2"dMM  %s"
"$c2     NMm  "$c1"dMM  -MMm  \`MMM   dMM. "$c2"dMM  %s"
"$c2     NMm  "$c1"dMM  .mmd  \`mmm   yMM. "$c2"dMM  %s"
"$c2     NMm  "$c1"dMM\`  ..\`   ...   ydm. "$c2"dMM  %s"
"$c2     hMM- "$c1"+MMd/-------...-:sdds  "$c2"dMM  %s"
"$c2     -NMm- "$c1":hNMNNNmdddddddddy/\`  "$c2"dMM  %s"
"$c2      -dMNs-"$c1"\`\`-::::-------.\`\`    "$c2"dMM  %s"
"$c2       \`/dMNmy+/:-------------:/yMMM  %s"
"$c2          ./ydNMMMMMMMMMMMMMMMMMMMMM  %s"
"$c2             \.MMMMMMMMMMMMMMMMMMM    %s"
"                                      %s")
		;;

		"LMDE")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light green') # Bold Green
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}          \`.-::---..           %s"
"${c2}       .:++++ooooosssoo:.      %s"
"${c2}     .+o++::.      \`.:oos+.    %s"
"${c2}    :oo:.\`             -+oo"${c1}":   %s"
"${c2}  "${c1}"\`"${c2}"+o/\`    ."${c1}"::::::"${c2}"-.    .++-"${c1}"\`  %s"
"${c2} "${c1}"\`"${c2}"/s/    .yyyyyyyyyyo:   +o-"${c1}"\`  %s"
"${c2} "${c1}"\`"${c2}"so     .ss       ohyo\` :s-"${c1}":  %s"
"${c2} "${c1}"\`"${c2}"s/     .ss  h  m  myy/ /s\`"${c1}"\`  %s"
"${c2} \`s:     \`oo  s  m  Myy+-o:\`   %s"
"${c2} \`oo      :+sdoohyoydyso/.     %s"
"${c2}  :o.      .:////////++:       %s"
"${c2}  \`/++        "${c1}"-:::::-          %s"
"${c2}   "${c1}"\`"${c2}"++-                        %s"
"${c2}    "${c1}"\`"${c2}"/+-                       %s"
"${c2}      "${c1}"."${c2}"+/.                     %s"
"${c2}        "${c1}"."${c2}":+-.                  %s"
"${c2}           \`--.\`\`              %s"
"                               %s")
		;;

		"Ubuntu")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light red') # Light Red
				c3=$(getColor 'yellow') # Bold Yellow
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; c3="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c2                          ./+o+-      %s"
"$c1                  yyyyy- $c2-yyyyyy+     %s"
"$c1               $c1://+//////$c2-yyyyyyo     %s"
"$c3           .++ $c1.:/++++++/-$c2.+sss/\`     %s"
"$c3         .:++o:  $c1/++++++++/:--:/-     %s"
"$c3        o:+o+:++.$c1\`..\`\`\`.-/oo+++++/    %s"
"$c3       .:+o:+o/.$c1          \`+sssoo+/   %s"
"$c1  .++/+:$c3+oo+o:\`$c1             /sssooo.  %s"
"$c1 /+++//+:$c3\`oo+o$c1               /::--:.  %s"
"$c1 \+/+o+++$c3\`o++o$c2               ++////.  %s"
"$c1  .++.o+$c3++oo+:\`$c2             /dddhhh.  %s"
"$c3       .+.o+oo:.$c2          \`oddhhhh+   %s"
"$c3        \+.++o+o\`$c2\`-\`\`\`\`.:ohdhhhhh+    %s"
"$c3         \`:o+++ $c2\`ohhhhhhhhyo++os:     %s"
"$c3           .o:$c2\`.syhhhhhhh/$c3.oo++o\`     %s"
"$c2               /osyyyyyyo$c3++ooo+++/    %s"
"$c2                   \`\`\`\`\` $c3+oo+++o\:    %s"
"$c3                          \`oo++.      %s")
		;;

		"KDE neon")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light green') # Bold Green
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c1              \`..---+/---..\`               %s"
"$c1          \`---.\`\`   \`\`   \`.---.\`           %s"
"$c1       .--.\`        \`\`        \`-:-.        %s"
"$c1     \`:/:     \`.----//----.\`     :/-       %s"
"$c1    .:.    \`---\`          \`--.\`    .:\`     %s"
"$c1   .:\`   \`--\`                .:-    \`:.    %s"
"$c1  \`/    \`:.      \`.-::-.\`      -:\`   \`/\`   %s"
"$c1  /.    /.     \`:++++++++:\`     .:    .:   %s"
"$c1 \`/    .:     \`+++++++++++/      /\`   \`+\`  %s"
"$c1 /+\`   --     .++++++++++++\`     :.   .+:  %s"
"$c1 \`/    .:     \`+++++++++++/      /\`   \`+\`  %s"
"$c1  /\`    /.     \`:++++++++:\`     .:    .:   %s"
"$c1  ./    \`:.      \`.:::-.\`      -:\`   \`/\`   %s"
"$c1   .:\`   \`--\`                .:-    \`:.    %s"
"$c1    .:.    \`---\`          \`--.\`    .:\`     %s"
"$c1     \`:/:     \`.----//----.\`     :/-       %s"
"$c1       .-:.\`        \`\`        \`-:-.        %s"
"$c1          \`---.\`\`   \`\`   \`.---.\`           %s"
"$c1              \`..---+/---..\`               %s")
		;;

		"Debian")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light red') # Light Red
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"  $c1       _,met\$\$\$\$\$gg.          %s"
"  $c1    ,g\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$P.       %s"
"  $c1  ,g\$\$P\"\"       \"\"\"Y\$\$.\".     %s"
"  $c1 ,\$\$P'              \`\$\$\$.     %s"
"  $c1',\$\$P       ,ggs.     \`\$\$b:   %s"
"  $c1\`d\$\$'     ,\$P\"\'   $c2.$c1    \$\$\$    %s"
"  $c1 \$\$P      d\$\'     $c2,$c1    \$\$P    %s"
"  $c1 \$\$:      \$\$.   $c2-$c1    ,d\$\$'    %s"
"  $c1 \$\$\;      Y\$b._   _,d\$P'     %s"
"  $c1 Y\$\$.    $c2\`.$c1\`\"Y\$\$\$\$P\"'         %s"
"  $c1 \`\$\$b      $c2\"-.__              %s"
"  $c1  \`Y\$\$                        %s"
"  $c1   \`Y\$\$.                      %s"
"  $c1     \`\$\$b.                    %s"
"  $c1       \`Y\$\$b.                 %s"
"  $c1          \`\"Y\$b._             %s"
"  $c1              \`\"\"\"\"           %s"
"                                %s")
		;;

		"Devuan")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light purple') # Light purple
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c1                                    %s"
"$c1     ..,,;;;::;,..                  %s"
"$c1             \`':ddd;:,.             %s"
"$c1                   \`'dPPd:,.        %s"
"$c1                       \`:b\$\$b\`.     %s"
"$c1                          'P\$\$\$d\`   %s"
"$c1                           .\$\$\$\$\$\`  %s"
"$c1                           ;\$\$\$\$\$P  %s"
"$c1                        .:P\$\$\$\$\$\$\`  %s"
"$c1                    .,:b\$\$\$\$\$\$\$;'   %s"
"$c1               .,:dP\$\$\$\$\$\$\$\$b:'     %s"
"$c1        .,:;db\$\$\$\$\$\$\$\$\$\$Pd'\`        %s"
"$c1   ,db\$\$\$\$\$\$\$\$\$\$\$\$\$\$b:'\`            %s"
"$c1  :\$\$\$\$\$\$\$\$\$\$\$\$b:'\`                 %s"
"$c1   \`\$\$\$\$\$bd:''\`                     %s"
"$c1     \`'''\`                          %s"
"                                    %s")
		;;

		"Raspbian")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light green') # Light Green
				c2=$(getColor 'light red') # Light Red
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
" $c1   .',;:cc;,'.    .,;::c:,,.   %s"
"   $c1,ooolcloooo:  'oooooccloo:   %s"
"   $c1.looooc;;:ol  :oc;;:ooooo'   %s"
"     $c1;oooooo:      ,ooooooc.    %s"
"       $c1.,:;'.       .;:;'.      %s"
"       $c2.... ..'''''. ....       %s"
"     $c2.''.   ..'''''.  ..''.     %s"
"     $c2..  .....    .....  ..     %s"
"    $c2.  .'''''''  .''''''.  .    %s"
"  $c2.'' .''''''''  .'''''''. ''.  %s"
"  $c2'''  '''''''    .''''''  '''  %s"
"  $c2.'    ........... ...    .'.  %s"
"    $c2....    ''''''''.   .''.    %s"
"    $c2'''''.  ''''''''. .'''''    %s"
"     $c2'''''.  .'''''. .'''''.    %s"
"      $c2..''.     .    .''..      %s"
"            $c2.'''''''            %s"
"             $c2......       %s")
		;;

		"CrunchBang")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"                                      %s"
"$c2         "$c1"███"$c2"        "$c1"███"$c2"          "$c1"███"$c2"  %s"
"$c2         "$c1"███"$c2"        "$c1"███"$c2"          "$c1"███"$c2"  %s"
"$c2         "$c1"███"$c2"        "$c1"███"$c2"          "$c1"███"$c2"  %s"
"$c2         "$c1"███"$c2"        "$c1"███"$c2"          "$c1"███"$c2"  %s"
"$c2  "$c1"████████████████████████████"$c2"   "$c1"███"$c2"  %s"
"$c2  "$c1"████████████████████████████"$c2"   "$c1"███"$c2"  %s"
"$c2         "$c1"███"$c2"        "$c1"███"$c2"          "$c1"███"$c2"  %s"
"$c2         "$c1"███"$c2"        "$c1"███"$c2"          "$c1"███"$c2"  %s"
"$c2         "$c1"███"$c2"        "$c1"███"$c2"          "$c1"███"$c2"  %s"
"$c2         "$c1"███"$c2"        "$c1"███"$c2"          "$c1"███"$c2"  %s"
"$c2  "$c1"████████████████████████████"$c2"   "$c1"███"$c2"  %s"
"$c2  "$c1"████████████████████████████"$c2"   "$c1"███"$c2"  %s"
"$c2         "$c1"███"$c2"        "$c1"███"$c2"               %s"
"$c2         "$c1"███"$c2"        "$c1"███"$c2"               %s"
"$c2         "$c1"███"$c2"        "$c1"███"$c2"          "$c1"███"$c2"  %s"
"$c2         "$c1"███"$c2"        "$c1"███"$c2"          "$c1"███"$c2"  %s"
"$c2                                      %s")
		;;

		"CRUX")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light cyan')
				c2=$(getColor 'yellow')
				c3=$(getColor 'white')
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="1"
			fulloutput=(""
"${c1}          odddd            %s"
"${c1}       oddxkkkxxdoo        %s"
"${c1}      ddcoddxxxdoool       %s"
"${c1}      xdclodod  olol       %s"
"${c1}      xoc  xdd  olol       %s"
"${c1}      xdc  ${c2}k00${c1}Okdlol       %s"
"${c1}      xxd${c2}kOKKKOkd${c1}ldd       %s"
"${c1}      xdco${c2}xOkdlo${c1}dldd       %s"
"${c1}      ddc:cl${c2}lll${c1}oooodo      %s"
"${c1}    odxxdd${c3}xkO000kx${c1}ooxdo    %s"
"${c1}   oxdd${c3}x0NMMMMMMWW0od${c1}kkxo  %s"
"${c1}  oooxd${c3}0WMMMMMMMMMW0o${c1}dxkx  %s"
"${c1} docldkXW${c3}MMMMMMMWWN${c1}Odolco  %s"
"${c1} xx${c2}dx${c1}kxxOKN${c3}WMMWN${c1}0xdoxo::c  %s"
"${c2} xOkkO${c1}0oo${c3}odOW${c2}WW${c1}XkdodOxc:l  %s"
"${c2} dkkkxkkk${c3}OKX${c2}NNNX0Oxx${c1}xc:cd  %s"
"${c2}  odxxdx${c3}xllod${c2}ddooxx${c1}dc:ldo  %s"
"${c2}    lodd${c1}dolccc${c2}ccox${c1}xoloo"
"")
		;;

		"Chrome OS")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'green') # Green
				c2=$(getColor 'light red') # Light Red
				c3=$(getColor 'yellow') # Bold Yellow
				c4=$(getColor 'light blue') # Light Blue
				c5=$(getColor 'white') # White
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; c3="${my_lcolor}"; c4="${my_lcolor}"; c5="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c2             .,:loool:,.              %s"
"$c2         .,coooooooooooooc,.          %s"
"$c2      .,lllllllllllllllllllll,.       %s"
"$c2     ;ccccccccccccccccccccccccc;      %s"
"$c1   '${c2}ccccccccccccccccccccccccccccc.    %s"
"$c1  ,oo${c2}c::::::::okO${c5}000${c3}0OOkkkkkkkkkkk:   %s"
"$c1 .ooool${c2};;;;:x${c5}K0${c4}kxxxxxk${c5}0X${c3}K0000000000.  %s"
"$c1 :oooool${c2};,;O${c5}K${c4}ddddddddddd${c5}KX${c3}000000000d  %s"
"$c1 lllllool${c2};l${c5}N${c4}dllllllllllld${c5}N${c3}K000000000  %s"
"$c1 lllllllll${c2}o${c5}M${c4}dccccccccccco${c5}W${c3}K000000000  %s"
"$c1 ;cllllllllX${c5}X${c4}c:::::::::c${c5}0X${c3}000000000d  %s"
"$c1 .ccccllllllO${c5}Nk${c4}c;,,,;cx${c5}KK${c3}0000000000.  %s"
"$c1  .cccccclllllxOO${c5}OOO${c1}Okx${c3}O0000000000;   %s"
"$c1   .:ccccccccllllllllo${c3}O0000000OOO,    %s"
"$c1     ,:ccccccccclllcd${c3}0000OOOOOOl.     %s"
"$c1       '::ccccccccc${c3}dOOOOOOOkx:.       %s"
"$c1         ..,::cccc${c3}xOOOkkko;.          %s"
"$c1             ..,:${c3}dOkxl:.              %s")
		;;

		"Gentoo")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light purple') # Light Purple
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c2         -/oyddmdhs+:.               %s"
"$c2     -o"$c1"dNMMMMMMMMNNmhy+"$c2"-\`            %s"
"$c2   -y"$c1"NMMMMMMMMMMMNNNmmdhy"$c2"+-          %s"
"$c2 \`o"$c1"mMMMMMMMMMMMMNmdmmmmddhhy"$c2"/\`       %s"
"$c2 om"$c1"MMMMMMMMMMMN"$c2"hhyyyo"$c1"hmdddhhhd"$c2"o\`     %s"
"$c2.y"$c1"dMMMMMMMMMMd"$c2"hs++so/s"$c1"mdddhhhhdm"$c2"+\`   %s"
"$c2 oy"$c1"hdmNMMMMMMMN"$c2"dyooy"$c1"dmddddhhhhyhN"$c2"d.  %s"
"$c2  :o"$c1"yhhdNNMMMMMMMNNNmmdddhhhhhyym"$c2"Mh  %s"
"$c2    .:"$c1"+sydNMMMMMNNNmmmdddhhhhhhmM"$c2"my  %s"
"$c2       /m"$c1"MMMMMMNNNmmmdddhhhhhmMNh"$c2"s:  %s"
"$c2    \`o"$c1"NMMMMMMMNNNmmmddddhhdmMNhs"$c2"+\`   %s"
"$c2  \`s"$c1"NMMMMMMMMNNNmmmdddddmNMmhs"$c2"/.     %s"
"$c2 /N"$c1"MMMMMMMMNNNNmmmdddmNMNdso"$c2":\`       %s"
"$c2+M"$c1"MMMMMMNNNNNmmmmdmNMNdso"$c2"/-          %s"
"$c2yM"$c1"MNNNNNNNmmmmmNNMmhs+/"$c2"-\`              %s"
"$c2/h"$c1"MMNNNNNNNNMNdhs++/"$c2"-\`               %s"
"$c2\`/"$c1"ohdmmddhys+++/:"$c2".\`                  %s"
"$c2  \`-//////:--.                       %s")
		;;

		"Funtoo")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light purple') # Light Purple
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"                                                    %s"
"                                                    %s"
"                                                    %s"
"                                                    %s"
"${c1}     _______               ____                     %s"
"${c1}    /MMMMMMM/             /MMMM| _____  _____       %s"
"${c1} __/M${c2}.MMM.${c1}M/_____________|M${c2}.M${c1}MM|/MMMMM\/MMMMM\      %s"
"${c1}|MMMM${c2}MM'${c1}MMMMMMMMMMMMMMMMMMM${c2}MM${c1}MMMM${c2}.MMMM..MMMM.${c1}MM\    %s"
"${c1}|MM${c2}MMMMMMM${c1}/m${c2}MMMMMMMMMMMMMMMMMMMMMM${c1}MMMM${c2}MM${c1}MMMM${c2}MM${c1}MM|   %s"
"${c1}|MMMM${c2}MM${c1}MMM${c2}MM${c1}MM${c2}MM${c1}MM${c2}MM${c1}MMMMM${c2}\MMM${c1}MMM${c2}MM${c1}MMMM${c2}MM${c1}MMMM${c2}MM${c1}MM|   %s"
"${c1}  |MM${c2}MM${c1}MMM${c2}MM${c1}MM${c2}MM${c1}MM${c2}MM${c1}MM${c2}MM${c1}MM${c2}MMM${c1}MMMM${c2}'MMMM''MMMM'${c1}MM/    %s"
"${c1}  |MM${c2}MM${c1}MMM${c2}MM${c1}MM${c2}MM${c1}MM${c2}MM${c1}MM${c2}MM${c1}MM${c2}MMM${c1}MMM\MMMMM/\MMMMM/      %s"
"${c1}  |MM${c2}MM${c1}MMM${c2}MM${c1}MMMMMM${c2}MM${c1}MM${c2}MM${c1}MM${c2}MMMMM'${c1}M|                  %s"
"${c1}  |MM${c2}MM${c1}MMM${c2}MMMMMMMMMMMMMMMMM MM'${c1}M/                   %s"
"${c1}  |MMMMMMMMMMMMMMMMMMMMMMMMMMMM/                    %s"
"                                                    %s"
"                                                    %s"
"                                                    %s")
		;;

		"Kogaion")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light blue') # Light Blue
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}                  ;;      ,;             %s"
"${c1}                 ;;;     ,;;             %s"
"${c1}               ,;;;;     ;;;;            %s"
"${c1}            ,;;;;;;;;    ;;;;            %s"
"${c1}           ;;;;;;;;;;;   ;;;;;           %s"
"${c1}          ,;;;;;;;;;;;;  ';;;;;,         %s"
"${c1}          ;;;;;;;;;;;;;;, ';;;;;;;       %s"
"${c1}          ;;;;;;;;;;;;;;;;;, ';;;;;      %s"
"${c1}      ;    ';;;;;;;;;;;;;;;;;;, ;;;      %s"
"${c1}      ;;;,  ';;;;;;;;;;;;;;;;;;;,;;      %s"
"${c1}      ;;;;;,  ';;;;;;;;;;;;;;;;;;,       %s"
"${c1}      ;;;;;;;;,  ';;;;;;;;;;;;;;;;,      %s"
"${c1}      ;;;;;;;;;;;;, ';;;;;;;;;;;;;;      %s"
"${c1}      ';;;;;;;;;;;;; ';;;;;;;;;;;;;      %s"
"${c1}       ';;;;;;;;;;;;;, ';;;;;;;;;;;      %s"
"${c1}        ';;;;;;;;;;;;;  ;;;;;;;;;;       %s"
"${c1}          ';;;;;;;;;;;; ;;;;;;;;         %s"
"${c1}              ';;;;;;;; ;;;;;;           %s"
"${c1}                 ';;;;; ;;;;             %s"
"${c1}                   ';;; ;;               ")
		;;

		"Fedora")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light blue') # Light Blue
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c2           /:-------------:\         %s"
"$c2        :-------------------::       %s"
"$c2      :-----------"$c1"/shhOHbmp"$c2"---:\\     %s"
"$c2    /-----------"$c1"omMMMNNNMMD  "$c2"---:    %s"
"$c2   :-----------"$c1"sMMMMNMNMP"$c2".    ---:   %s"
"$c2  :-----------"$c1":MMMdP"$c2"-------    ---\  %s"
"$c2 ,------------"$c1":MMMd"$c2"--------    ---:  %s"
"$c2 :------------"$c1":MMMd"$c2"-------    .---:  %s"
"$c2 :----    "$c1"oNMMMMMMMMMNho"$c2"     .----:  %s"
"$c2 :--     ."$c1"+shhhMMMmhhy++"$c2"   .------/  %s"
"$c2 :-    -------"$c1":MMMd"$c2"--------------:   %s"
"$c2 :-   --------"$c1"/MMMd"$c2"-------------;    %s"
"$c2 :-    ------"$c1"/hMMMy"$c2"------------:     %s"
"$c2 :--"$c1" :dMNdhhdNMMNo"$c2"------------;      %s"
"$c2 :---"$c1":sdNMMMMNds:"$c2"------------:       %s"
"$c2 :------"$c1":://:"$c2"-------------::         %s"
"$c2 :---------------------://           %s"
"                                     %s")
		;;

		"Chapeau")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light green') # Light Green
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c2               .-/-.               %s"
"$c2             ////////.             %s"
"$c2           ////////"$c1"y+"$c2"//.           %s"
"$c2         ////////"$c1"mMN"$c2"/////.         %s"
"$c2       ////////"$c1"mMN+"$c2"////////.       %s"
"$c2     ////////////////////////.     %s"
"$c2   /////////+"$c1"shhddhyo"$c2"+////////.    %s"
"$c2  ////////"$c1"ymMNmdhhdmNNdo"$c2"///////.   %s"
"$c2 ///////+"$c1"mMms"$c2"////////"$c1"hNMh"$c2"///////.  %s"
"$c2 ///////"$c1"NMm+"$c2"//////////"$c1"sMMh"$c2"///////  %s"
"$c2 //////"$c1"oMMNmmmmmmmmmmmmMMm"$c2"///////  %s"
"$c2 //////"$c1"+MMmssssssssssssss+"$c2"///////  %s"
"$c2 \`//////"$c1"yMMy"$c2"////////////////////   %s"
"$c2  \`//////"$c1"smMNhso++oydNm"$c2"////////    %s"
"$c2   \`///////"$c1"ohmNMMMNNdy+"$c2"///////     %s"
"$c2     \`//////////"$c1"++"$c2"//////////       %s"
"$c2        \`////////////////.         %s"
"$c2            -////////-            %s"
"                                  %s")
		;;

		"Korora")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white')
				c2=$(getColor 'light blue')
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c1                 ____________   %s"
"$c1              _add55555555554"$c2":  %s"
"$c1            _w?'"$c2"\`\`\`\`\`\`\`\`\`\`'"$c1")k"$c2":  %s"
"$c1           _Z'"$c2"\`"$c1"            ]k"$c2":  %s"
"$c1           m("$c2"\`"$c1"             )k"$c2":  %s"
"$c1      _.ss"$c2"\`"$c1"m["$c2"\`"$c1",            ]e"$c2":  %s"
"$c1    .uY\"^\`"$c2"\`"$c1"Xc"$c2"\`"$c1"?Ss.         d("$c2"\`  %s"
"$c1   jF'"$c2"\`"$c1"    \`@.  "$c2"\`"$c1"Sc      .jr"$c2"\`   %s"
"$c1  jr"$c2"\`"$c1"       \`?n_ "$c2"\`"$c1"$;   _a2\""$c2"\`    %s"
"$c1 .m"$c2":"$c1"          \`~M"$c2"\`"$c1"1k"$c2"\`"$c1"5?!\`"$c2"\`      %s"
"$c1 :#"$c2":"$c1"             "$c2"\`"$c1")e"$c2"\`\`\`         %s"
"$c1 :m"$c2":"$c1"             ,#'"$c2"\`           %s"
"$c1 :#"$c2":"$c1"           .s2'"$c2"\`            %s"
"$c1 :m,________.aa7^"$c2"\`              %s"
"$c1 :#baaaaaaas!J'"$c2"\`                %s"
"$c2  \`\`\`\`\`\`\`\`\`\`\`                   %s")
		;;

		"gNewSense")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light blue') # Light Blue
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c1                      ..,,,,..                      %s"
"$c1                .oocchhhhhhhhhhccoo.                %s"
"$c1         .ochhlllllllc hhhhhh ollllllhhco.          %s"
"$c1     ochlllllllllll hhhllllllhhh lllllllllllhco     %s"
"$c1  .cllllllllllllll hlllllo  +hllh llllllllllllllc.  %s"
"$c1 ollllllllllhco\'\'  hlllllo  +hllh  \`\`ochllllllllllo %s"
"$c1 hllllllllc\'       hllllllllllllh       \`cllllllllh %s"
"$c1 ollllllh          +llllllllllll+          hllllllo %s"
"$c1  \`cllllh.           ohllllllho           .hllllc\'  %s"
"$c1     ochllc.            ++++            .cllhco     %s"
"$c1        \`+occooo+.                .+ooocco+\'        %s"
"$c1               \`+oo++++      ++++oo+\'               %s"
"$c1                                                    %s")
		;;

		"BLAG")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light purple')
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c1              d                     %s"
"$c1             ,MK:                   %s"
"$c1             xMMMX:                 %s"
"$c1            .NMMMMMX;               %s"
"$c1            lMMMMMMMM0clodkO0KXWW:  %s"
"$c1            KMMMMMMMMMMMMMMMMMMX'   %s"
"$c1       .;d0NMMMMMMMMMMMMMMMMMMK.    %s"
"$c1  .;dONMMMMMMMMMMMMMMMMMMMMMMx      %s"
"$c1 'dKMMMMMMMMMMMMMMMMMMMMMMMMl       %s"
"$c1    .:xKWMMMMMMMMMMMMMMMMMMM0.      %s"
"$c1        .:xNMMMMMMMMMMMMMMMMMK.     %s"
"$c1           lMMMMMMMMMMMMMMMMMMK.    %s"
"$c1           ,MMMMMMMMWkOXWMMMMMM0    %s"
"$c1           .NMMMMMNd.     \`':ldko   %s"
"$c1            OMMMK:                  %s"
"$c1            oWk,                    %s"
"$c1            ;:                      %s")
		;;

		"FreeBSD")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # white
				c2=$(getColor 'light red') # Light Red
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"                                     %s"
"   "$c1"\`\`\`                        "$c2"\`      %s"
"  "$c1"\` \`.....---..."$c2"....--.\`\`\`   -/      %s"
"  "$c1"+o   .--\`         "$c2"/y:\`      +.     %s"
"  "$c1" yo\`:.            "$c2":o      \`+-      %s"
"    "$c1"y/               "$c2"-/\`   -o/       %s"
"   "$c1".-                  "$c2"::/sy+:.      %s"
"   "$c1"/                     "$c2"\`--  /      %s"
"  "$c1"\`:                          "$c2":\`     %s"
"  "$c1"\`:                          "$c2":\`     %s"
"   "$c1"/                          "$c2"/      %s"
"   "$c1".-                        "$c2"-.      %s"
"    "$c1"--                      "$c2"-.       %s"
"     "$c1"\`:\`                  "$c2"\`:\`        %s"
"       "$c2".--             \`--.          %s"
"         "$c2" .---.....----.             %s"
"                                     %s"
"                                     %s")
		;;

		"FreeBSD - Old")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # white
				c2=$(getColor 'light red') # Light Red
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c2              ,        ,          %s"
"$c2             /(        )\`         %s"
"$c2             \ \___   / |         %s"
"$c2             /- "$c1"_$c2  \`-/  '         %s"
"$c2            ($c1/\/ \ $c2\   /\\         %s"
"$c1            / /   |$c2 \`    \\        %s"
"$c1            O O   )$c2 /    |        %s"
"$c1            \`-^--'\`$c2<     '        %s"
"$c2           (_.)  _  )   /         %s"
"$c2            \`.___/\`    /          %s"
"$c2              \`-----' /           %s"
"$c1 <----.     "$c2"__/ __   \\            %s"
"$c1 <----|===="$c2"O}}}$c1==$c2} \} \/$c1====      %s"
"$c1 <----'    $c2\`--' \`.__,' \\          %s"
"$c2              |        |          %s"
"$c2               \       /       /\\ %s"
"$c2          ______( (_  / \______/  %s"
"$c2        ,'  ,-----'   |           %s"
"$c2        \`--{__________)"
"")
		;;

		"OpenBSD")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'yellow') # Light Yellow
				c2=$(getColor 'brown') # Bold Yellow
				c3=$(getColor 'light cyan') # Light Cyan
				c4=$(getColor 'light red') # Light Red
				c5=$(getColor 'dark grey')
			fi
			if [ -n "${my_lcolor}" ]; then c1="$my_lcolor"; c2="${my_color}"; fi
			startline="3"
			fulloutput=(
"                                       "$c3" _      "
"                                       "$c3"(_)      "
""$c1"              |    .                            "
""$c1"          .   |L  /|   .         "$c3" _     %s"
""$c1"      _ . |\ _| \--+._/| .       "$c3"(_)    %s"
""$c1"     / ||\| Y J  )   / |/| ./           %s"
""$c1"    J  |)'( |        \` F\`.'/       "$c3" _   %s"
""$c1"  -<|  F         __     .-<        "$c3"(_)  %s"
""$c1"    | /       .-'"$c3". "$c1"\`.  /"$c3"-. "$c1"L___         %s"
""$c1"    J \      <    "$c3"\ "$c1" | | "$c5"O"$c3"\\\\"$c1"|.-' "$c3" _      %s"
""$c1"  _J \  .-    \\\\"$c3"/ "$c5"O "$c3"| "$c1"| \  |"$c1"F    "$c3"(_)     %s"
""$c1" '-F  -<_.     \   .-'  \`-' L__         %s"
""$c1"__J  _   _.     >-'  "$c2")"$c4"._.   "$c1"|-'         %s         "
""$c1" \`-|.'   /_.          "$c4"\_|  "$c1" F           %s     "
""$c1"  /.-   .                _.<            %s"
""$c1" /'    /.'             .'  \`\           %s"
""$c1"  /L  /'   |/      _.-'-\               %s "
""$c1" /'J       ___.---'\|                   %s"
""$c1"   |\  .--' V  | \`. \`                   %s "
""$c1"   |/\`. \`-.     \`._)                    %s"
""$c1"      / .-.\                            %s"
""$c1"      \ (  \`\                           "
""$c1"       \`.\                                  ")
		;;

		"DragonFlyBSD")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light red') # Red
				c2=$(getColor 'white') # White
				c3=$(getColor 'yellow') #
				c4=$(getColor 'light red')
			fi
			startline="0"
			fulloutput=(
"                     "$c1" |                    %s"
"                    "$c1" .-.                   %s"
"                   "$c3" ()"$c1"I"$c3"()                  %s"
"              "$c1" \"==.__:-:__.==\"             %s"
"              "$c1"\"==.__/~|~\__.==\"            %s"
"              "$c1"\"==._(  Y  )_.==\"            %s"
"   "$c2".-'~~\"\"~=--...,__"$c1"\/|\/"$c2"__,...--=~\"\"~~'-. %s"
"  "$c2"(               ..="$c1"\\\\="$c1"/"$c2"=..               )%s"
"   "$c2"\`'-.        ,.-\"\`;"$c1"/=\\\\"$c2" ;\"-.,_        .-'\`%s"
"      "$c2" \`~\"-=-~\` .-~\` "$c1"|=|"$c2" \`~-. \`~-=-\"~\`     %s"
"       "$c2"     .-~\`    /"$c1"|=|"$c2"\    \`~-.          %s"
"       "$c2"  .~\`       / "$c1"|=|"$c2" \       \`~.       %s"
" "$c2"    .-~\`        .'  "$c1"|=|"$c2"  \\\\\`.        \`~-.  %s"
" "$c2"  (\`     _,.-=\"\`  "$c1"  |=|"$c2"    \`\"=-.,_     \`) %s"
" "$c2"   \`~\"~\"\`        "$c1"   |=|"$c2"           \`\"~\"~\`  %s"
"                   "$c1"  /=\                   %s"
"                   "$c1"  \=/                   %s"
"                   "$c1"   ^                    %s")
		;;

		"NetBSD")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'orange') # Orange
				c2=$(getColor 'white') # White
			fi
			startline="0"
			fulloutput=(
"                                  "$c1"__,gnnnOCCCCCOObaau,_     %s"
"   "$c2"_._                    "$c1"__,gnnCCCCCCCCOPF\"''              %s"
"  "$c2"(N\\\\\\\\"$c1"XCbngg,._____.,gnnndCCCCCCCCCCCCF\"___,,,,___          %s"
"   "$c2"\\\\N\\\\\\\\"$c1"XCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCOOOOPYvv.     %s"
"    "$c2"\\\\N\\\\\\\\"$c1"XCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCPF\"''               %s"
"     "$c2"\\\\N\\\\\\\\"$c1"XCCCCCCCCCCCCCCCCCCCCCCCCCOF\"'                     %s"
"      "$c2"\\\\N\\\\\\\\"$c1"XCCCCCCCCCCCCCCCCCCCCOF\"'                         %s"
"       "$c2"\\\\N\\\\\\\\"$c1"XCCCCCCCCCCCCCCCPF\"'                             %s"
"        "$c2"\\\\N\\\\\\\\"$c1"\"PCOCCCOCCFP\"\"                                  %s"
"         "$c2"\\\\N\                                                %s"
"          "$c2"\\\\N\                                               %s"
"           "$c2"\\\\N\                                              %s"
"            "$c2"\\\\NN\                                            %s"
"             "$c2"\\\\NN\                                           %s"
"              "$c2"\\\\NNA.                                         %s"
"               "$c2"\\\\NNA,                                        %s"
"                "$c2"\\\\NNN,                                       %s"
"                 "$c2"\\\\NNN\                                      %s"
"                  "$c2"\\\\NNN\ "
"                   "$c2"\\\\NNNA")
		;;

		"Mandriva"|"Mandrake")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light blue') # Light Blue
				c2=$(getColor 'yellow') # Bold Yellow
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"                                         %s"
"$c2                         \`\`              %s"
"$c2                        \`-.              %s"
"$c1       \`               $c2.---              %s"
"$c1     -/               $c2-::--\`             %s"
"$c1   \`++    $c2\`----...\`\`\`-:::::.             %s"
"$c1  \`os.      $c2.::::::::::::::-\`\`\`     \`  \` %s"
"$c1  +s+         $c2.::::::::::::::::---...--\` %s"
"$c1 -ss:          $c2\`-::::::::::::::::-.\`\`.\`\` %s"
"$c1 /ss-           $c2.::::::::::::-.\`\`   \`    %s"
"$c1 +ss:          $c2.::::::::::::-            %s"
"$c1 /sso         $c2.::::::-::::::-            %s"
"$c1 .sss/       $c2-:::-.\`   .:::::            %s"
"$c1  /sss+.    $c2..\`$c1  \`--\`    $c2.:::            %s"
"$c1   -ossso+/:://+/-\`        $c2.:\`           %s"
"$c1     -/+ooo+/-.              $c2\`           %s"
"                                         %s"
"                                         %s")
		;;

		"openSUSE"|"SUSE Linux Enterprise")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light green') # Bold Green
				c2=$c0$bold
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c2             .;ldkO0000Okdl;.               %s"
"$c2         .;d00xl:^''''''^:ok00d;.           %s"
"$c2       .d00l'                'o00d.         %s"
"$c2     .d0Kd'"$c1"  Okxol:;,.          "$c2":O0d.       %s"
"$c2    .OK"$c1"KKK0kOKKKKKKKKKKOxo:,      "$c2"lKO.      %s"
"$c2   ,0K"$c1"KKKKKKKKKKKKKKK0P^"$c2",,,"$c1"^dx:"$c2"    ;00,     %s"
"$c2  .OK"$c1"KKKKKKKKKKKKKKKk'"$c2".oOPPb."$c1"'0k."$c2"   cKO.    %s"
"$c2  :KK"$c1"KKKKKKKKKKKKKKK: "$c2"kKx..dd "$c1"lKd"$c2"   'OK:    %s"
"$c2  dKK"$c1"KKKKKKKKKOx0KKKd "$c2"^0KKKO' "$c1"kKKc"$c2"   dKd    %s"
"$c2  dKK"$c1"KKKKKKKKKK;.;oOKx,.."$c2"^"$c1"..;kKKK0."$c2"  dKd    %s"
"$c2  :KK"$c1"KKKKKKKKKK0o;...^cdxxOK0O/^^'  "$c2".0K:    %s"
"$c2   kKK"$c1"KKKKKKKKKKKKK0x;,,......,;od  "$c2"lKk     %s"
"$c2   '0K"$c1"KKKKKKKKKKKKKKKKKKKK00KKOo^  "$c2"c00'     %s"
"$c2    'kK"$c1"KKOxddxkOO00000Okxoc;''   "$c2".dKk'      %s"
"$c2      l0Ko.                    .c00l'       %s"
"$c2       'l0Kk:.              .;xK0l'         %s"
"$c2          'lkK0xl:;,,,,;:ldO0kl'            %s"
"$c2              '^:ldxkkkkxdl:^'              %s")
		;;

		"Slackware")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light blue') # Light Blue
				c2=$(getColor 'white') # Bold White
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="1"
			fulloutput=(
"$c1                   :::::::"
"$c1             :::::::::::::::::::              %s"
"$c1          :::::::::::::::::::::::::           %s"
"$c1        ::::::::"${c2}"cllcccccllllllll"${c1}"::::::        %s"
"$c1     :::::::::"${c2}"lc               dc"${c1}":::::::      %s"
"$c1    ::::::::"${c2}"cl   clllccllll    oc"${c1}":::::::::    %s"
"$c1   :::::::::"${c2}"o   lc"${c1}"::::::::"${c2}"co   oc"${c1}"::::::::::   %s"
"$c1  ::::::::::"${c2}"o    cccclc"${c1}":::::"${c2}"clcc"${c1}"::::::::::::  %s"
"$c1  :::::::::::"${c2}"lc        cclccclc"${c1}":::::::::::::  %s"
"$c1 ::::::::::::::"${c2}"lcclcc          lc"${c1}":::::::::::: %s"
"$c1 ::::::::::"${c2}"cclcc"${c1}":::::"${c2}"lccclc     oc"${c1}"::::::::::: %s"
"$c1 ::::::::::"${c2}"o    l"${c1}"::::::::::"${c2}"l    lc"${c1}"::::::::::: %s"
"$c1  :::::"${c2}"cll"${c1}":"${c2}"o     clcllcccll     o"${c1}":::::::::::  %s"
"$c1  :::::"${c2}"occ"${c1}":"${c2}"o                  clc"${c1}":::::::::::  %s"
"$c1   ::::"${c2}"ocl"${c1}":"${c2}"ccslclccclclccclclc"${c1}":::::::::::::   %s"
"$c1    :::"${c2}"oclcccccccccccccllllllllllllll"${c1}":::::    %s"
"$c1     ::"${c2}"lcc1lcccccccccccccccccccccccco"${c1}"::::     %s"
"$c1       ::::::::::::::::::::::::::::::::       %s"
"$c1         ::::::::::::::::::::::::::::         %s"
"$c1            ::::::::::::::::::::::"
"$c1                 ::::::::::::")
		;;

		"Red Hat Enterprise Linux")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light red') # Light Red
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"                                          %s"
"$c2              \`.-..........\`              %s"
"$c2             \`////////::.\`-/.             %s"
"$c2             -: ....-////////.            %s"
"$c2             //:-::///////////\`           %s"
"$c2      \`--::: \`-://////////////:           %s"
"$c2      //////-    \`\`.-:///////// .\`        %s"
"$c2      \`://////:-.\`    :///////::///:\`     %s"
"$c2        .-/////////:---/////////////:     %s"
"$c2           .-://////////////////////.     %s"
"$c1          yMN+\`.-$c2::///////////////-\`      %s"
"$c1       .-\`:NMMNMs\`  \`..-------..\`         %s"
"$c1        MN+/mMMMMMhoooyysshsss            %s"
"$c1 MMM    MMMMMMMMMMMMMMyyddMMM+            %s"
"$c1  MMMM   MMMMMMMMMMMMMNdyNMMh\`     hyhMMM %s"
"$c1   MMMMMMMMMMMMMMMMyoNNNMMM+.   MMMMMMMM  %s"
"$c1    MMNMMMNNMMMMMNM+ mhsMNyyyyMNMMMMsMM   %s"
"                                          %s")
		;;

		"Frugalware")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light blue') # Light Blue
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="3"
			fulloutput=(
"${c2}          \`++/::-.\`"
"${c2}         /o+++++++++/::-.\`"
"${c2}        \`o+++++++++++++++o++/::-.\`"
"${c2}        /+++++++++++++++++++++++oo++/:-.\`\`        %s"
"${c2}       .o+ooooooooooooooooooosssssssso++oo++/:-\`  %s"
"${c2}       ++osoooooooooooosssssssssssssyyo+++++++o:  %s"
"${c2}      -o+ssoooooooooooosssssssssssssyyo+++++++s\`  %s"
"${c2}      o++ssoooooo++++++++++++++sssyyyyo++++++o:   %s"
"${c2}     :o++ssoooooo"${c1}"/-------------"${c2}"+syyyyyo+++++oo    %s"
"${c2}    \`o+++ssoooooo"${c1}"/-----"${c2}"+++++ooosyyyyyyo++++os:    %s"
"${c2}    /o+++ssoooooo"${c1}"/-----"${c2}"ooooooosyyyyyyyo+oooss     %s"
"${c2}   .o++++ssooooos"${c1}"/------------"${c2}"syyyyyyhsosssy-     %s"
"${c2}   ++++++ssooooss"${c1}"/-----"${c2}"+++++ooyyhhhhhdssssso      %s"
"${c2}  -s+++++syssssss"${c1}"/-----"${c2}"yyhhhhhhhhhhhddssssy.      %s"
"${c2}  sooooooyhyyyyyh"${c1}"/-----"${c2}"hhhhhhhhhhhddddyssy+       %s"
"${c2} :yooooooyhyyyhhhyyyyyyhhhhhhhhhhdddddyssy\`       %s"
"${c2} yoooooooyhyyhhhhhhhhhhhhhhhhhhhddddddysy/        %s"
"${c2}-ysooooooydhhhhhhhhhhhddddddddddddddddssy         %s"
"${c2} .-:/+osssyyyysyyyyyyyyyyyyyyyyyyyyyyssy:         %s"
"${c2}       \`\`.-/+oosysssssssssssssssssssssss          %s"
"${c2}               \`\`.:/+osyysssssssssssssh.          %s"
"${c2}                        \`-:/+osyyssssyo"
"${c2}                                .-:+++\`")
		;;

		"Peppermint")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light red') # Light Red
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c2}             8ZZZZZZ"${c1}"MMMMM              %s"
"${c2}          .ZZZZZZZZZ"${c1}"MMMMMMM.           %s"
"${c1}        MM"${c2}"ZZZZZZZZZ"${c1}"MMMMMMM"${c2}"ZZZZ         %s"
"${c1}      MMMMM"${c2}"ZZZZZZZZ"${c1}"MMMMM"${c2}"ZZZZZZZM       %s"
"${c1}     MMMMMMM"${c2}"ZZZZZZZ"${c1}"MMMM"${c2}"ZZZZZZZZZ.      %s"
"${c1}    MMMMMMMMM"${c2}"ZZZZZZ"${c1}"MMM"${c2}"ZZZZZZZZZZZI     %s"
"${c1}   MMMMMMMMMMM"${c2}"ZZZZZZ"${c1}"MM"${c2}"ZZZZZZZZZZ"${c1}"MMM    %s"
"${c2}   .ZZZ"${c1}"MMMMMMMMMM"${c2}"IZZ"${c1}"MM"${c2}"ZZZZZ"${c1}"MMMMMMMMM   %s"
"${c2}   ZZZZZZZ"${c1}"MMMMMMMM"${c2}"ZZ"${c1}"M"${c2}"ZZZZ"${c1}"MMMMMMMMMMM   %s"
"${c2}   ZZZZZZZZZZZZZZZZ"${c1}"M"${c2}"Z"${c1}"MMMMMMMMMMMMMMM   %s"
"${c2}   .ZZZZZZZZZZZZZ"${c1}"MMM"${c2}"Z"${c1}"M"${c2}"ZZZZZZZZZZ"${c1}"MMMM   %s"
"${c2}   .ZZZZZZZZZZZ"${c1}"MMM"${c2}"7ZZ"${c1}"MM"${c2}"ZZZZZZZZZZ7"${c1}"M    %s"
"${c2}    ZZZZZZZZZ"${c1}"MMMM"${c2}"ZZZZ"${c1}"MMMM"${c2}"ZZZZZZZ77     %s"
"${c1}     MMMMMMMMMMMM"${c2}"ZZZZZ"${c1}"MMMM"${c2}"ZZZZZ77      %s"
"${c1}      MMMMMMMMMM"${c2}"7ZZZZZZ"${c1}"MMMMM"${c2}"ZZ77       %s"
"${c1}       .MMMMMMM"${c2}"ZZZZZZZZ"${c1}"MMMMM"${c2}"Z7Z        %s"
"${c1}         MMMMM"${c2}"ZZZZZZZZZ"${c1}"MMMMMMM         %s"
"${c2}           NZZZZZZZZZZZ"${c1}"MMMMM           %s"
"${c2}              ZZZZZZZZZ"${c1}"MM")
		;;

		"Solus")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'dark grey') # Light Gray
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}               e         e     %s"
"${c1}             eee       ee      %s"
"${c1}            eeee     eee       %s"
"${c2}        wwwwwwwww"${c1}"eeeeee        %s"
"${c2}     wwwwwwwwwwwwwww"${c1}"eee        %s"
"${c2}   wwwwwwwwwwwwwwwwwww"${c1}"eeeeeeee %s"
"${c2}  wwwww     "${c1}"eeeee"${c2}"wwwwww"${c1}"eeee    %s"
"${c2} www          "${c1}"eeee"${c2}"wwwwww"${c1}"e      %s"
"${c2} ww             "${c1}"ee"${c2}"wwwwww       %s"
"${c2} w                 wwwww       %s"
"${c2}                   wwwww       %s"
"${c2}                  wwwww        %s"
"${c2}                 wwwww         %s"
"${c2}                wwww           %s"
"${c2}               wwww            %s"
"${c2}             wwww              %s"
"${c2}           www                 %s"
"${c2}         ww                    %s")
		;;

		"Mageia")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
			 	c2=$(getColor 'light cyan') # Light Cyan
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c2               .°°.              %s"
"$c2                °°   .°°.        %s"
"$c2                .°°°. °°         %s"
"$c2                .   .            %s"
"$c2                 °°° .°°°.       %s"
"$c2             .°°°.   '___'       %s"
"$c1            .${c2}'___'     $c1   .      %s"
"$c1          :dkxc;'.  ..,cxkd;     %s"
"$c1        .dkk. kkkkkkkkkk .kkd.   %s"
"$c1       .dkk.  ';cloolc;.  .kkd   %s"
"$c1       ckk.                .kk;  %s"
"$c1       xO:                  cOd  %s"
"$c1       xO:                  lOd  %s"
"$c1       lOO.                .OO:  %s"
"$c1       .k00.              .00x   %s"
"$c1        .k00;            ;00O.   %s"
"$c1         .lO0Kc;,,,,,,;c0KOc.    %s"
"$c1            ;d00KKKKKK00d;       %s"
"$c1               .,KKKK,.            ")
		;;

		"Parabola GNU/Linux-libre")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light purple') # Light Purple
				c2=$(getColor 'white') # White
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"                                 %s"
"${c1}              eeeeeeeee          %s"
"${c1}          eeeeeeeeeeeeeee        %s"
"${c1}       eeeeee"${c2}"//////////"${c1}"eeeee     %s"
"${c1}     eeeee"${c2}"///////////////"${c1}"eeeee   %s"
"${c1}   eeeee"${c2}"///           ////"${c1}"eeee   %s"
"${c1}  eeee"${c2}"//              ///"${c1}"eeeee   %s"
"${c1} eee                 "${c2}"///"${c1}"eeeee    %s"
"${c1}ee                  "${c2}"//"${c1}"eeeeee     %s"
"${c1}e                  "${c2}"/"${c1}"eeeeeee      %s"
"${c1}                  eeeeeee        %s"
"${c1}                 eeeeee          %s"
"${c1}                eeeeee           %s"
"${c1}               eeeee             %s"
"${c1}              eeee               %s"
"${c1}            eee                  %s"
"${c1}           ee                    %s"
"${c1}          e                      %s")
		;;

		"Viperr")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'dark grey') # Dark Gray
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}    wwzapd         dlzazw      %s"
"${c1}   an"${c2}"#"${c1}"zncmqzepweeirzpas"${c2}"#"${c1}"xz     %s"
"${c1} apez"${c2}"##"${c1}"qzdkawweemvmzdm"${c2}"##"${c1}"dcmv   %s"
"${c1}zwepd"${c2}"####"${c1}"qzdweewksza"${c2}"####"${c1}"ezqpa  %s"
"${c1}ezqpdkapeifjeeazezqpdkazdkwqz  %s"
"${c1} ezqpdksz"${c2}"##"${c1}"wepuizp"${c2}"##"${c1}"wzeiapdk   %s"
"${c1}  zqpakdpa"${c2}"#"${c1}"azwewep"${c2}"#"${c1}"zqpdkqze    %s"
"${c1}    apqxalqpewenwazqmzazq      %s"
"${c1}     mn"${c2}"##"${c1}"=="${c2}"#######"${c1}"=="${c2}"##"${c1}"qp       %s"
"${c1}      qw"${c2}"##"${c1}"="${c2}"#######"${c1}"="${c2}"##"${c1}"zl        %s"
"${c1}      z0"${c2}"######"${c1}"="${c2}"######"${c1}"0a        %s"
"${c1}       qp"${c2}"#####"${c1}"="${c2}"#####"${c1}"mq         %s"
"${c1}       az"${c2}"####"${c1}"==="${c2}"####"${c1}"mn         %s"
"${c1}        ap"${c2}"#########"${c1}"qz          %s"
"${c1}         9qlzskwdewz           %s"
"${c1}          zqwpakaiw            %s"
"${c1}            qoqpe              %s"
"                               %s")
		;;

		"LinuxDeepin")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light green') # Bold Green
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}  eeeeeeeeeeeeeeeeeeeeeeeeeeee   %s"
"${c1} eee  eeeeeee          eeeeeeee  %s"
"${c1}ee   eeeeeeeee      eeeeeeeee ee %s"
"${c1}e   eeeeeeeee     eeeeeeeee    e %s"
"${c1}e   eeeeeee    eeeeeeeeee      e %s"
"${c1}e   eeeeee    eeeee            e %s"
"${c1}e    eeeee    eee  eee         e %s"
"${c1}e     eeeee   ee eeeeee        e %s"
"${c1}e      eeeee   eee   eee       e %s"
"${c1}e       eeeeeeeeee  eeee       e %s"
"${c1}e         eeeee    eeee        e %s"
"${c1}e               eeeeee         e %s"
"${c1}e            eeeeeee           e %s"
"${c1}e eee     eeeeeeee             e %s"
"${c1}eeeeeeeeeeeeeeee               e %s"
"${c1}eeeeeeeeeeeee                 ee %s"
"${c1} eeeeeeeeeee                eee  %s"
"${c1}  eeeeeeeeeeeeeeeeeeeeeeeeeeee   %s"
"                                 %s")
		;;

		"Deepin")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'cyan') # Bold Green
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}              ............               %s"
"${c1}          .';;;;;.       .,;,.           %s"
"${c1}       .,;;;;;;;.       ';;;;;;;.        %s"
"${c1}     .;::::::::'     .,::;;,''''',.      %s"
"${c1}    ,'.::::::::    .;;'.          ';     %s"
"${c1}   ;'  'cccccc,   ,' :: '..        .:    %s"
"${c1}  ,,    :ccccc.  ;: .c, '' :.       ,;   %s"
"${c1} .l.     cllll' ., .lc  :; .l'       l.  %s"
"${c1} .c       :lllc  ;cl:  .l' .ll.      :'  %s"
"${c1} .l        'looc. .   ,o:  'oo'      c,  %s"
"${c1} .o.         .:ool::coc'  .ooo'      o.  %s"
"${c1}  ::            .....   .;dddo      ;c   %s"
"${c1}   l:...            .';lddddo.     ,o    %s"
"${c1}    lxxxxxdoolllodxxxxxxxxxc      :l     %s"
"${c1}     ,dxxxxxxxxxxxxxxxxxxl.     'o,      %s"
"${c1}       ,dkkkkkkkkkkkkko;.    .;o;        %s"
"${c1}         .;okkkkkdl;.    .,cl:.          %s"
"${c1}             .,:cccccccc:,.  %s")
		;;

		"Chakra")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light blue') # Light Blue
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}      _ _ _        \"kkkkkkkk.         %s"
"${c1}    ,kkkkkkkk.,    \'kkkkkkkkk,        %s"
"${c1}    ,kkkkkkkkkkkk., \'kkkkkkkkk.       %s"
"${c1}   ,kkkkkkkkkkkkkkkk,\'kkkkkkkk,       %s"
"${c1}  ,kkkkkkkkkkkkkkkkkkk\'kkkkkkk.       %s"
"${c1}   \"\'\'\"\'\'\',;::,,\"\'\'kkk\'\'kkkkk;   __   %s"
"${c1}       ,kkkkkkkkkk, \"k\'\'kkkkk\' ,kkkk  %s"
"${c1}     ,kkkkkkk\' ., \' .: \'kkkk\',kkkkkk  %s"
"${c1}   ,kkkkkkkk\'.k\'   ,  ,kkkk;kkkkkkkkk %s"
"${c1}  ,kkkkkkkk\';kk \'k  \"\'k\',kkkkkkkkkkkk %s"
"${c1} .kkkkkkkkk.kkkk.\'kkkkkkkkkkkkkkkkkk\' %s"
"${c1} ;kkkkkkkk\'\'kkkkkk;\'kkkkkkkkkkkkk\'\'   %s"
"${c1} \'kkkkkkk; \'kkkkkkkk.,\"\"\'\'\"\'\'\"\"       %s"
"${c1}   \'\'kkkk;  \'kkkkkkkkkk.,             %s"
"${c1}      \';\'    \'kkkkkkkkkkkk.,          %s"
"${c1}              ';kkkkkkkkkk\'           %s"
"${c1}                ';kkkkkk\'             %s"
"${c1}                   \"\'\'\"               %s")
		;;

		"Fuduntu")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'dark grey') # Dark Gray
				c2=$(getColor 'yellow') # Bold Yellow
				c3=$(getColor 'light red') # Light Red
				c4=$(getColor 'white') # White
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="1"
			fulloutput=(
"${c1}       \`dwoapfjsod\`"${c2}"           \`dwoapfjsod\`"
"${c1}    \`xdwdsfasdfjaapz\`"${c2}"       \`dwdsfasdfjaapzx\`    %s"
"${c1}  \`wadladfladlafsozmm\`"${c2}"     \`wadladfladlafsozmm\`  %s"
"${c1} \`aodowpwafjwodisosoaas\`"${c2}" \`odowpwafjwodisosoaaso\` %s"
"${c1} \`adowofaowiefawodpmmxs\`"${c2}" \`dowofaowiefawodpmmxso\` %s"
"${c1} \`asdjafoweiafdoafojffw\`"${c2}" \`sdjafoweiafdoafojffwq\` %s"
"${c1}  \`dasdfjalsdfjasdlfjdd\`"${c2}" \`asdfjalsdfjasdlfjdda\`  %s"
"${c1}   \`dddwdsfasdfjaapzxaw\`"${c2}" \`ddwdsfasdfjaapzxawo\`   %s"
"${c1}     \`dddwoapfjsowzocmw\`"${c2}" \`ddwoapfjsowzocmwp\`     %s"
"${c1}       \`ddasowjfowiejao\`"${c2}" \`dasowjfowiejaow\`       %s"
"                                                 %s"
"${c3}       \`ddasowjfowiejao\`"${c4}" \`dasowjfowiejaow\`       %s"
"${c3}     \`dddwoapfjsowzocmw\`"${c4}" \`ddwoapfjsowzocmwp\`     %s"
"${c3}   \`dddwdsfasdfjaapzxaw\`"${c4}" \`ddwdsfasdfjaapzxawo\`   %s"
"${c3}  \`dasdfjalsdfjasdlfjdd\`"${c4}" \`asdfjalsdfjasdlfjdda\`  %s"
"${c3} \`asdjafoweiafdoafojffw\`"${c4}" \`sdjafoweiafdoafojffwq\` %s"
"${c3} \`adowofaowiefawodpmmxs\`"${c4}" \`dowofaowiefawodpmmxso\` %s"
"${c3} \`aodowpwafjwodisosoaas\`"${c4}" \`odowpwafjwodisosoaaso\` %s"
"${c3}   \`wadladfladlafsozmm\`"${c4}"     \`wadladfladlafsozmm\` %s"
"${c3}     \`dwdsfasdfjaapzx\`"${c4}"       \`dwdsfasdfjaapzx\`"
"${c3}        \`woapfjsod\`"${c4}"             \`woapfjsod\`")
		;;

		"Mac OS X")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'green') # Green
				c2=$(getColor 'brown') # Yellow
				c3=$(getColor 'light red') # Orange
				c4=$(getColor 'red') # Red
				c5=$(getColor 'purple') # Purple
				c6=$(getColor 'blue') # Blue
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; c3="${my_lcolor}"; c4="${my_lcolor}"; c5="${my_lcolor}"; c6="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"\n${c1}                 -/+:.         %s"
"${c1}                :++++.         %s"
"${c1}               /+++/.          %s"
"${c1}       .:-::- .+/:-\`\`.::-      %s"
"${c1}    .:/++++++/::::/++++++/:\`   %s"
"${c2}  .:///////////////////////:\`  %s"
"${c2}  ////////////////////////\`    %s"
"${c3} -+++++++++++++++++++++++\`     %s"
"${c3} /++++++++++++++++++++++/      %s"
"${c4} /sssssssssssssssssssssss.     %s"
"${c4} :ssssssssssssssssssssssss-    %s"
"${c5}  osssssssssssssssssssssssso/\` %s"
"${c5}  \`syyyyyyyyyyyyyyyyyyyyyyyy+\` %s"
"${c6}   \`ossssssssssssssssssssss/   %s"
"${c6}     :ooooooooooooooooooo+.    %s"
"${c6}      \`:+oo+/:-..-:/+o+/-      %s\n")
		;;

		"Mac OS X - Classic")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'blue') # Blue
				c2=$(getColor 'light blue') # Light blue
				c3=$(getColor 'light grey') # Gray
				c4=$(getColor 'dark grey') # Dark Ggray
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c3}\n                        ..             %s"
"${c3}                       dWc             %s"
"${c3}                     ,X0'              %s"
"${c1}  ;;;;;;;;;;;;;;;;;;${c3}0Mk${c2}::::::::::::::: %s"
"${c1}  ;;;;;;;;;;;;;;;;;${c3}KWo${c2}:::::::::::::::: %s"
"${c1}  ;;;;;;;;;${c4}NN${c1};;;;;${c3}KWo${c2}:::::${c3}NN${c2}:::::::::: %s"
"${c1}  ;;;;;;;;;${c4}NN${c1};;;;${c3}0Md${c2}::::::${c3}NN${c2}:::::::::: %s"
"${c1}  ;;;;;;;;;${c4}NN${c1};;;${c3}xW0${c2}:::::::${c3}NN${c2}:::::::::: %s"
"${c1}  ;;;;;;;;;;;;;;${c3}KMc${c2}::::::::::::::::::: %s"
"${c1}  ;;;;;;;;;;;;;${c3}lWX${c2}:::::::::::::::::::: %s"
"${c1}  ;;;;;;;;;;;;;${c3}xWWXXXXNN7${c2}::::::::::::: %s"
"${c1}  ;;;;;;;;;;;;;;;;;;;;${c3}WK${c2}:::::::::::::: %s"
"${c1}  ;;;;;${c4}TKX0ko.${c1};;;;;;;${c3}kMx${c2}:::${c3}.cOKNF${c2}::::: %s"
"${c1}  ;;;;;;;;${c4}\`kO0KKKKKKK${c3}NMNXK0OP*${c2}:::::::: %s"
"${c1}  ;;;;;;;;;;;;;;;;;;;${c3}kMx${c2}:::::::::::::: %s"
"${c1}  ;;;;;;;;;;;;;;;;;;;;${c3}WX${c2}:::::::::::::: %s"
"${c3}                      lMc              %s"
"${c3}                       kN.             %s"
"${c3}                        o'             %s\n")
		;;

		"Windows"|"Cygwin"|"Msys")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light red') # Red
				c2=$(getColor 'light green') # Green
				c3=$(getColor 'light blue') # Blue
				c4=$(getColor 'yellow') # Yellow
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; c3="${my_lcolor}"; c4="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}        ,.=:!!t3Z3z.,                %s"
"${c1}       :tt:::tt333EE3                %s"
"${c1}       Et:::ztt33EEEL${c2} @Ee.,      .., %s"
"${c1}      ;tt:::tt333EE7${c2} ;EEEEEEttttt33# %s"
"${c1}     :Et:::zt333EEQ.${c2} \$EEEEEttttt33QL %s"
"${c1}     it::::tt333EEF${c2} @EEEEEEttttt33F  %s"
"${c1}    ;3=*^\`\`\`\"*4EEV${c2} :EEEEEEttttt33@.  %s"
"${c3}    ,.=::::!t=., ${c1}\`${c2} @EEEEEEtttz33QF   %s"
"${c3}   ;::::::::zt33)${c2}   \"4EEEtttji3P*    %s"
"${c3}  :t::::::::tt33.${c4}:Z3z..${c2}  \`\`${c4} ,..g.    %s"
"${c3}  i::::::::zt33F${c4} AEEEtttt::::ztF     %s"
"${c3} ;:::::::::t33V${c4} ;EEEttttt::::t3      %s"
"${c3} E::::::::zt33L${c4} @EEEtttt::::z3F      %s"
"${c3}{3=*^\`\`\`\"*4E3)${c4} ;EEEtttt:::::tZ\`      %s"
"${c3}             \`${c4} :EEEEtttt::::z7       %s"
"${c4}                 \"VEzjt:;;z>*\`       %s")
		;;

		"Windows - Modern")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light blue') # Blue
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}                                  .., %s"
"${c1}                      ....,,:;+ccllll %s"
"${c1}        ...,,+:;  cllllllllllllllllll %s"
"${c1}  ,cclllllllllll  lllllllllllllllllll %s"
"${c1}  llllllllllllll  lllllllllllllllllll %s"
"${c1}  llllllllllllll  lllllllllllllllllll %s"
"${c1}  llllllllllllll  lllllllllllllllllll %s"
"${c1}  llllllllllllll  lllllllllllllllllll %s"
"${c1}  llllllllllllll  lllllllllllllllllll %s"
"${c1}                                      %s"
"${c1}  llllllllllllll  lllllllllllllllllll %s"
"${c1}  llllllllllllll  lllllllllllllllllll %s"
"${c1}  llllllllllllll  lllllllllllllllllll %s"
"${c1}  llllllllllllll  lllllllllllllllllll %s"
"${c1}  llllllllllllll  lllllllllllllllllll %s"
"${c1}  \`'ccllllllllll  lllllllllllllllllll %s"
"${c1}         \`'\"\"*::  :ccllllllllllllllll %s"
"${c1}                        \`\`\`\`''\"*::cll %s"
"${c1}                                   \`\` %s")
		;;

		"Haiku")
			if [[ "$no_color" != "1" ]]; then
				if [ "$haikualpharelease" == "yes" ]; then
					c1=$(getColor 'black_haiku') # Black
					c2=$(getColor 'light grey') # Light Gray
				else
					c1=$(getColor 'black') # Black
					c2=${c1}
				fi
				c3=$(getColor 'green') # Green
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; c3="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}          :dc'                      %s"
"${c1}       'l:;'${c2},${c1}'ck.    .;dc:.         %s"
"${c1}       co    ${c2}..${c1}k.  .;;   ':o.       %s"
"${c1}       co    ${c2}..${c1}k. ol      ${c2}.${c1}0.       %s"
"${c1}       co    ${c2}..${c1}k. oc     ${c2}..${c1}0.       %s"
"${c1}       co    ${c2}..${c1}k. oc     ${c2}..${c1}0.       %s"
"${c1}.Ol,.  co ${c2}...''${c1}Oc;kkodxOdddOoc,.    %s"
"${c1} ';lxxlxOdxkxk0kd${c3}oooll${c1}dl${c3}ccc:${c1}clxd;   %s"
"${c1}     ..${c3}oOolllllccccccc:::::${c1}od;      %s"
"${c1}       cx:ooc${c3}:::::::;${c1}cooolcX.       %s"
"${c1}       cd${c2}.${c1}''cloxdoollc' ${c2}...${c1}0.       %s"
"${c1}       cd${c2}......${c1}k;${c2}.${c1}xl${c2}....  .${c1}0.       %s"
"${c1}       .::c${c2};..${c1}cx;${c2}.${c1}xo${c2}..... .${c1}0.       %s"
"${c1}          '::c'${c2}...${c1}do${c2}..... .${c1}K,       %s"
"${c1}                  cd,.${c2}....:${c1}O,${c2}...... %s"
"${c1}                    ':clod:'${c2}......  %s"
"${c1}                        ${c2}.           %s")
		;;

		"Trisquel")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light blue') # Light Blue
				c2=$(getColor 'light cyan') # Blue
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}                          ▄▄▄▄▄▄      %s"
"${c1}                       ▄█████████▄    %s"
"${c1}       ▄▄▄▄▄▄         ████▀   ▀████   %s"
"${c1}    ▄██████████▄     ████▀   ▄▄ ▀███  %s"
"${c1}  ▄███▀▀   ▀▀████     ███▄   ▄█   ███ %s"
"${c1} ▄███   ▄▄▄   ████▄    ▀██████   ▄███ %s"
"${c1} ███   █▀▀██▄  █████▄     ▀▀   ▄████  %s"
"${c1} ▀███      ███  ███████▄▄  ▄▄██████   %s"
"${c1}  ▀███▄   ▄███  █████████████${c2}████▀    %s"
"${c1}   ▀█████████    ███████${c2}███▀▀▀        %s"
"${c1}     ▀▀███▀▀     ██${c2}████▀▀             %s"
"${c2}                ██████▀   ▄▄▄▄        %s"
"${c2}               █████▀   ████████      %s"
"${c2}               █████   ███▀  ▀███     %s"
"${c2}                ████▄   ██▄▄▄  ███    %s"
"${c2}                 █████▄   ▀▀  ▄██     %s"
"${c2}                   ██████▄▄▄████      %s"
"${c2}                      ▀▀█████▀▀       %s")
		;;

		"Manjaro")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light green') # Green
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1} ██████████████████  ████████    %s"
"${c1} ██████████████████  ████████    %s"
"${c1} ██████████████████  ████████    %s"
"${c1} ██████████████████  ████████    %s"
"${c1} ████████            ████████    %s"
"${c1} ████████  ████████  ████████    %s"
"${c1} ████████  ████████  ████████    %s"
"${c1}           ████████  ████████    %s"
"${c1} ████████  ████████  ████████    %s"
"${c1} ████████  ████████  ████████    %s"
"${c1} ████████  ████████  ████████    %s"
"${c1} ████████  ████████  ████████    %s"
"${c1} ████████  ████████  ████████    %s"
"${c1} ████████  ████████  ████████    %s"
"${c1} ████████  ████████  ████████    %s"
"${c1} ████████  ████████  ████████    %s"
"${c1} ████████  ████████  ████████    %s"
"                                 %s")
		;;

		"Netrunner")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light blue') # Blue
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1} nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn  %s"
"${c1} nnnnnnnnnnnnnn            nnnnnnnnnnnnnn  %s"
"${c1} nnnnnnnnnn     nnnnnnnnnn     nnnnnnnnnn  %s"
"${c1} nnnnnnn   nnnnnnnnnnnnnnnnnnnn   nnnnnnn  %s"
"${c1} nnnn   nnnnnnnnnnnnnnnnnnnnnnnnnn   nnnn  %s"
"${c1} nnn  nnnnnnnnnnnnnnnnnnnnnnnnnnnnnn  nnn  %s"
"${c1} nn  nnnnnnnnnnnnnnnnnnnnnn  nnnnnnnn  nn  %s"
"${c1} n  nnnnnnnnnnnnnnnnn       nnnnnnnnnn  n  %s"
"${c1} n nnnnnnnnnnn              nnnnnnnnnnn n  %s"
"${c1} n nnnnnn                  nnnnnnnnnnnn n  %s"
"${c1} n nnnnnnnnnnn             nnnnnnnnnnnn n  %s"
"${c1} n nnnnnnnnnnnnn           nnnnnnnnnnnn n  %s"
"${c1} n nnnnnnnnnnnnnnnn       nnnnnnnnnnnnn n  %s"
"${c1} n nnnnnnnnnnnnnnnnn      nnnnnnnnnnnnn n  %s"
"${c1} n nnnnnnnnnnnnnnnnnn    nnnnnnnnnnnn   n  %s"
"${c1} nn  nnnnnnnnnnnnnnnnn   nnnnnnnnnnnn  nn  %s"
"${c1} nnn   nnnnnnnnnnnnnnn  nnnnnnnnnnn   nnn  %s"
"${c1} nnnnn   nnnnnnnnnnnnnn nnnnnnnnn   nnnnn  %s"
"${c1} nnnnnnn   nnnnnnnnnnnnnnnnnnnn   nnnnnnn  %s"
"${c1} nnnnnnnnnn     nnnnnnnnnn     nnnnnnnnnn  %s"
"${c1} nnnnnnnnnnnnnn            nnnnnnnnnnnnnn  %s"
"${c1} nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn  %s"
"                                 %s")
		;;

			"Logos")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'green') # Green
				c2=$(getColor 'white') # White
			fi
			startline="0"
			fulloutput=(
"$c1    ..:.:.               $c2%s"
"$c1   ..:.:.:.:.            $c2%s"
"$c1  ..:.:.:.:.:.:.         $c2%s"
"$c1 ..:.:.:.:.:.:.:.:.      $c2%s"
"$c1   .:.::;.::::..:.:.:.   $c2%s"
"$c1      .:.:.::.::.::.;;/  $c2%s"
"$c1         .:.::.::://///  $c2%s"
"$c1            ..;;///////  $c2%s"
"$c1            ///////////  $c2%s"
"$c1         //////////////  $c2%s"
"$c1      /////////////////  $c2%s"
"$c1   ///////////////////   $c2%s"
"$c1 //////////////////      $c2%s"
"$c1  //////////////         $c2%s"
"$c1   //////////            $c2%s"
"$c1    //////               $c2%s"
"$c1     //                  $c2%s")
		;;

			"Manjaro-tree")
			if [[ "$no_color" != "1" ]]; then
				c1="\e[1;32m" # Green
				c2="\e[1;33m" # Yellow
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}                         ###     %s"
"${c1}     ###             ####        %s"
"${c1}        ###       ####           %s"
"${c1}         ##### #####             %s"
"${c1}      #################          %s"
"${c1}    ###     #####    ####        %s"
"${c1}   ##        ${c2}OOO       ${c1}###       %s"
"${c1}  #          ${c2}WW         ${c1}##       %s"
"${c1}            ${c2}WW            ${c1}#      %s"
"${c2}            WW                   %s"
"${c2}            WW                   %s"
"${c2}           WW                    %s"
"${c2}           WW                    %s"
"${c2}           WW                    %s"
"${c2}          WW                     %s"
"${c2}          WW                     %s"
"${c2}          WW                     %s"
"                                 %s")
		;;

		"elementary OS"|"elementary os")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"                                    %s"
"${c1}         eeeeeeeeeeeeeeeee          %s"
"${c1}      eeeeeeeeeeeeeeeeeeeeeee       %s"
"${c1}    eeeee  eeeeeeeeeeee   eeeee     %s"
"${c1}  eeee   eeeee       eee     eeee   %s"
"${c1} eeee   eeee          eee     eeee  %s"
"${c1}eee    eee            eee       eee %s"
"${c1}eee   eee            eee        eee %s"
"${c1}ee    eee           eeee       eeee %s"
"${c1}ee    eee         eeeee      eeeeee %s"
"${c1}ee    eee       eeeee      eeeee ee %s"
"${c1}eee   eeee   eeeeee      eeeee  eee %s"
"${c1}eee    eeeeeeeeee     eeeeee    eee %s"
"${c1} eeeeeeeeeeeeeeeeeeeeeeee    eeeee  %s"
"${c1}  eeeeeeee eeeeeeeeeeee      eeee   %s"
"${c1}    eeeee                 eeeee     %s"
"${c1}      eeeeeee         eeeeeee       %s"
"${c1}         eeeeeeeeeeeeeeeee          %s")
	;;

		"Android")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light green') # Bold Green
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="2"
			fulloutput=(
"${c2}       ╲ ▁▂▂▂▁ ╱"
"${c2}       ▄███████▄ "
"${c2}      ▄██${c1} ${c2}███${c1} ${c2}██▄       %s"
"${c2}     ▄███████████▄      %s"
"${c2}  ▄█ ▄▄▄▄▄▄▄▄▄▄▄▄▄ █▄   %s"
"${c2}  ██ █████████████ ██   %s"
"${c2}  ██ █████████████ ██   %s"
"${c2}  ██ █████████████ ██   %s"
"${c2}  ██ █████████████ ██   %s"
"${c2}     █████████████      %s"
"${c2}      ███████████       %s"
"${c2}       ██     ██"
"${c2}       ██     ██")
		;;

		"Scientific Linux")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light blue')
				c2=$(getColor 'light red')
				c3=$(getColor 'white')
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="1"
			fulloutput=(
"${c1}                  =/;;/-"
"${c1}                 +:    //                   %s"
"${c1}                /;      /;                  %s"
"${c1}               -X        H.                 %s"
"${c1} .//;;;:;;-,   X=        :+   .-;:=;:;#;.   %s"
"${c1} M-       ,=;;;#:,      ,:#;;:=,       ,@   %s"
"${c1} :#           :#.=/++++/=.$=           #=   %s"
"${c1}  ,#;         #/:+/;,,/++:+/         ;+.    %s"
"${c1}    ,+/.    ,;@+,        ,#H;,    ,/+,      %s"
"${c1}       ;+;;/= @.  ${c2}.H${c3}#${c2}#X   ${c1}-X :///+;         %s"
"${c1}       ;+=;;;.@,  ${c3}.X${c2}M${c3}@$.  ${c1}=X.//;=#/.        %s"
"${c1}    ,;:      :@#=        =\$H:     .+#-      %s"
"${c1}  ,#=         #;-///==///-//         =#,    %s"
"${c1} ;+           :#-;;;:;;;;-X-           +:   %s"
"${c1} @-      .-;;;;M-        =M/;;;-.      -X   %s"
"${c1}  :;;::;;-.    #-        :+    ,-;;-;:==    %s"
"${c1}               ,X        H.                 %s"
"${c1}                ;/      #=                  %s"
"${c1}                 //    +;                   %s"
"${c1}                  '////'")
		;;

		"BackTrack Linux")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light red') # Light Red
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="1"
			fulloutput=(
"${c1}.............."
"${c1}            ..,;:ccc,.                          %s"
"${c1}          ......''';lxO.                        %s"
"${c1}.....''''..........,:ld;                        %s"
"${c1}           .';;;:::;,,.x,                       %s"
"${c1}      ..'''.            0Xxoc:,.  ...           %s"
"${c1}  ....                ,ONkc;,;cokOdc',.         %s"
"${c1} .                   OMo           ':"${c2}"dd"${c1}"o.       %s"
"${c1}                    dMc               :OO;      %s"
"${c1}                    0M.                 .:o.    %s"
"${c1}                    ;Wd                         %s"
"${c1}                     ;XO,                       %s"
"${c1}                       ,d0Odlc;,..              %s"
"${c1}                           ..',;:cdOOd::,.      %s"
"${c1}                                    .:d;.':;.   %s"
"${c1}                                       'd,  .'  %s"
"${c1}                                         ;l   ..%s"
"${c1}                                          .o    %s"
"${c1}                                            c   %s"
"${c1}                                            .'"
"${c1}                                             .")
		;;

		"Kali Linux")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light blue') # White
				c2=$(getColor 'black') # Light Red
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="1"
			fulloutput=(
"${c1}.............."
"${c1}            ..,;:ccc,.                          %s"
"${c1}          ......''';lxO.                        %s"
"${c1}.....''''..........,:ld;                        %s"
"${c1}           .';;;:::;,,.x,                       %s"
"${c1}      ..'''.            0Xxoc:,.  ...           %s"
"${c1}  ....                ,ONkc;,;cokOdc',.         %s"
"${c1} .                   OMo           ':"${c2}"dd"${c1}"o.       %s"
"${c1}                    dMc               :OO;      %s"
"${c1}                    0M.                 .:o.    %s"
"${c1}                    ;Wd                         %s"
"${c1}                     ;XO,                       %s"
"${c1}                       ,d0Odlc;,..              %s"
"${c1}                           ..',;:cdOOd::,.      %s"
"${c1}                                    .:d;.':;.   %s"
"${c1}                                       'd,  .'  %s"
"${c1}                                         ;l   ..%s"
"${c1}                                          .o    %s"
"${c1}                                            c   %s"
"${c1}                                            .'"
"${c1}                                             .")
		;;

		"Sabayon")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'white') # White
				c2=$(getColor 'light blue') # Blue
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c2}            ...........               %s"
"${c2}         ..             ..            %s"
"${c2}      ..                   ..         %s"
"${c2}    ..           ${c1}o           ${c2}..       %s"
"${c2}  ..            ${c1}:W'            ${c2}..     %s"
"${c2} ..             ${c1}.d.             ${c2}..    %s"
"${c2}:.             ${c1}.KNO              ${c2}.:   %s"
"${c2}:.             ${c1}cNNN.             ${c2}.:   %s"
"${c2}:              ${c1}dXXX,              ${c2}:   %s"
"${c2}:   ${c1}.          dXXX,       .cd,   ${c2}:   %s"
"${c2}:   ${c1}'kc ..     dKKK.    ,ll;:'    ${c2}:   %s"
"${c2}:     ${c1}.xkkxc;..dkkkc',cxkkl       ${c2}:   %s"
"${c2}:.     ${c1}.,cdddddddddddddo:.       ${c2}.:   %s"
"${c2} ..         ${c1}:lllllll:           ${c2}..    %s"
"${c2}   ..         ${c1}',,,,,          ${c2}..      %s"
"${c2}     ..                     ..        %s"
"${c2}        ..               ..           %s"
"${c2}          ...............             %s")
		;;

		"KaOS")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light blue')
				c2=$(getColor 'light grey')
				c3=$(getColor 'red')
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}                     ..            %s"
"${c1}  .....         ..OSSAAAAAAA..     %s"
"${c1} .KKKKSS.     .SSAAAAAAAAAAA.      %s"
"${c1}.KKKKKSO.    .SAAAAAAAAAA...       %s"
"${c1}KKKKKKS.   .OAAAAAAAA.             %s"
"${c1}KKKKKKS.  .OAAAAAA.                %s"
"${c1}KKKKKKS. .SSAA..                   %s"
"${c1}.KKKKKS..OAAAAAAAAAAAA........     %s"
"${c1} DKKKKO.=AA=========A===AASSSO..   %s"
"${c1}  AKKKS.==========AASSSSAAAAAASS.  %s"
"${c1}  .=KKO..========ASS.....SSSSASSSS.%s"
"${c1}    .KK.       .ASS..O.. =SSSSAOSS:%s"
"${c1}     .OK.      .ASSSSSSSO...=A.SSA.%s"
"${c1}       .K      ..SSSASSSS.. ..SSA. %s"
"${c1}                 .SSS.AAKAKSSKA.   %s"
"${c1}                    .SSS....S..    %s")
		;;

		"CentOS")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'yellow') # White
				c2=$(getColor 'light green') # White
				c3=$(getColor 'light blue') # White
				c4=$(getColor 'light purple') # White
				c5=$(getColor 'white') # White
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}                   ..                   %s"
"${c1}                 .PLTJ.                 %s"
"${c1}                <><><><>                %s"
"       ${c2}KKSSV' 4KKK ${c1}LJ${c4} KKKL.'VSSKK       %s"
"       ${c2}KKV' 4KKKKK ${c1}LJ${c4} KKKKAL 'VKK       %s"
"       ${c2}V' ' 'VKKKK ${c1}LJ${c4} KKKKV' ' 'V       %s"
"       ${c2}.4MA.' 'VKK ${c1}LJ${c4} KKV' '.4Mb.       %s"
"${c4}     . ${c2}KKKKKA.' 'V ${c1}LJ${c4} V' '.4KKKKK ${c3}.     %s"
"${c4}   .4D ${c2}KKKKKKKA.'' ${c1}LJ${c4} ''.4KKKKKKK ${c3}FA.   %s"
"${c4}  <QDD ++++++++++++  ${c3}++++++++++++ GFD>  %s"
"${c4}   'VD ${c3}KKKKKKKK'.. ${c2}LJ ${c1}..'KKKKKKKK ${c3}FV    %s"
"${c4}     ' ${c3}VKKKKK'. .4 ${c2}LJ ${c1}K. .'KKKKKV ${c3}'     %s"
"       ${c3} 'VK'. .4KK ${c2}LJ ${c1}KKA. .'KV'        %s"
"       ${c3}A. . .4KKKK ${c2}LJ ${c1}KKKKA. . .4       %s"
"       ${c3}KKA. 'KKKKK ${c2}LJ ${c1}KKKKK' .4KK       %s"
"       ${c3}KKSSA. VKKK ${c2}LJ ${c1}KKKV .4SSKK       %s"
"${c2}                <><><><>                 %s"
"${c2}                 'MKKM'                  %s"
"${c2}                   ''")
		;;

		"Jiyuu Linux")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light blue') # Light Blue
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}+++++++++++++++++++++++.       %s"
"${c1}ss:-......-+so/:----.os-       %s"
"${c1}ss        +s/        os-       %s"
"${c1}ss       :s+         os-       %s"
"${c1}ss       os.         os-       %s"
"${c1}ss      .so          os-       %s"
"${c1}ss      :s+          os-       %s"
"${c1}ss      /s/          os-       %s"
"${c1}ss      /s:          os-       %s"
"${c1}ss      +s-          os-       %s"
"${c1}ss-.....os:..........os-       %s"
"${c1}++++++++os+++++++++oooo.       %s"
"${c1}        os.     ./oo/.         %s"
"${c1}        os.   ./oo:            %s"
"${c1}        os. ./oo:              %s"
"${c1}        os oo+-                %s"
"${c1}        os+-                   %s"
"${c1}        /.                     %s")
		;;

		"Antergos")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'blue') # Light Blue
				c2=$(getColor 'light blue') # Light Blue
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="1"
			fulloutput=(
"${c1}               \`.-/::/-\`\`"
"${c1}            .-/osssssssso/.              %s"
"${c1}           :osyysssssssyyys+-            %s"
"${c1}        \`.+yyyysssssssssyyyyy+.          %s"
"${c1}       \`/syyyyyssssssssssyyyyys-\`        %s"
"${c1}      \`/yhyyyyysss${c2}++${c1}ssosyyyyhhy/\`        %s"
"${c1}     .ohhhyyyys${c2}o++/+o${c1}so${c2}+${c1}syy${c2}+${c1}shhhho.      %s"
"${c1}    .shhhhys${c2}oo++//+${c1}sss${c2}+++${c1}yyy${c2}+s${c1}hhhhs.     %s"
"${c1}   -yhhhhs${c2}+++++++o${c1}ssso${c2}+++${c1}yyy${c2}s+o${c1}hhddy:    %s"
"${c1}  -yddhhy${c2}o+++++o${c1}syyss${c2}++++${c1}yyy${c2}yooy${c1}hdddy-   %s"
"${c1} .yddddhs${c2}o++o${c1}syyyyys${c2}+++++${c1}yyhh${c2}sos${c1}hddddy\`  %s"
"${c1}\`odddddhyosyhyyyyyy${c2}++++++${c1}yhhhyosddddddo  %s"
"${c1}.dmdddddhhhhhhhyyyo${c2}+++++${c1}shhhhhohddddmmh. %s"
"${c1}ddmmdddddhhhhhhhso${c2}++++++${c1}yhhhhhhdddddmmdy %s"
"${c1}dmmmdddddddhhhyso${c2}++++++${c1}shhhhhddddddmmmmh %s"
"${c1}-dmmmdddddddhhys${c2}o++++o${c1}shhhhdddddddmmmmd- %s"
"${c1} .smmmmddddddddhhhhhhhhhdddddddddmmmms. %s"
"${c1}   \`+ydmmmdddddddddddddddddddmmmmdy/.     %s"
"${c1}      \`.:+ooyyddddddddddddyyso+:.\`")
		;;

		"Void")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'green')       # Dark Green
				c2=$(getColor 'light green') # Light Green
				c3=$(getColor 'dark grey')   # Black
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; c3="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c2}                 __.;=====;.__                 %s"
"${c2}             _.=+==++=++=+=+===;.              %s"
"${c2}              -=+++=+===+=+=+++++=_            %s"
"${c1}         .     "${c2}"-=:\`\`     \`--==+=++==.          %s"
"${c1}        _vi,    "${c2}"\`            --+=++++:         %s"
"${c1}       .uvnvi.       "${c2}"_._       -==+==+.        %s"
"${c1}      .vvnvnI\`    "${c2}".;==|==;.     :|=||=|.       %s"
"${c3} +QmQQm"${c1}"pvvnv; "${c3}"_yYsyQQWUUQQQm #QmQ#"${c2}":"${c3}"QQQWUV\$QQmL %s"
"${c3}  -QQWQW"${c1}"pvvo"${c3}"wZ?.wQQQE"${c2}"==<"${c3}"QWWQ/QWQW.QQWW"${c2}"(: "${c3}"jQWQE %s"
"${c3}   -\$QQQQmmU'  jQQQ@"${c2}"+=<"${c3}"QWQQ)mQQQ.mQQQC"${c2}"+;${c3}jWQQ@' %s"
"${c3}    -\$WQ8Y"${c1}"nI:   ${c3}QWQQwgQQWV"${c2}"\`"${c3}"mWQQ.jQWQQgyyWW@!   %s"
"${c1}      -1vvnvv.     "${c2}"\`~+++\`        ++|+++        %s"
"${c1}       +vnvnnv,                 "${c2}"\`-|===         %s"
"${c1}        +vnvnvns.           .      "${c2}":=-         %s"
"${c1}         -Invnvvnsi..___..=sv=.     "${c2}"\`          %s"
"${c1}           +Invnvnvnnnnnnnnvvnn;.              %s"
"${c1}             ~|Invnvnvvnvvvnnv}+\`              %s"
"${c1}                -~\"|{*l}*|\"\"~                  %s")
		;;

		"NixOS")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'blue')
				c2=$(getColor 'light blue')
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}          ::::.    ${c2}':::::     ::::'          %s"
"${c1}          ':::::    ${c2}':::::.  ::::'           %s"
"${c1}            :::::     ${c2}'::::.:::::            %s"
"${c1}      .......:::::..... ${c2}::::::::             %s"
"${c1}     ::::::::::::::::::. ${c2}::::::    ${c1}::::.     %s"
"${c1}    ::::::::::::::::::::: ${c2}:::::.  ${c1}.::::'     %s"
"${c2}           .....           ::::' ${c1}:::::'      %s"
"${c2}          :::::            '::' ${c1}:::::'       %s"
"${c2} ........:::::               ' ${c1}:::::::::::.  %s"
"${c2}:::::::::::::                 ${c1}:::::::::::::  %s"
"${c2} ::::::::::: ${c1}..              ${c1}:::::           %s"
"${c2}     .::::: ${c1}.:::            ${c1}:::::            %s"
"${c2}    .:::::  ${c1}:::::          ${c1}'''''    ${c2}.....    %s"
"${c2}    :::::   ${c1}':::::.  ${c2}......:::::::::::::'    %s"
"${c2}     :::     ${c1}::::::. ${c2}':::::::::::::::::'     %s"
"${c1}            .:::::::: ${c2}'::::::::::            %s"
"${c1}           .::::''::::.     ${c2}'::::.           %s"
"${c1}          .::::'   ::::.     ${c2}'::::.          %s"
"${c1}         .::::      ::::      ${c2}'::::.         %s")
		;;

		"BunsenLabs")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'blue')
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="5"
			fulloutput=(
"${c1}            HC]"
"${c1}          H]]]]"
"${c1}        H]]]]]]4"
"${c1}      @C]]]]]]]]*"
"${c1}     @]]]]]]]]]]xd"
"${c1}    @]]]]]]]]]]]]]d      %s"
"${c1}   0]]]]]]]]]]]]]]]]     %s"
"${c1}   kx]]]]]]x]]x]]]]]%%    %s"
"${c1}  #x]]]]]]]]]]]]]x]]]d   %s"
"${c1}  #]]]]]]qW  x]]x]]]]]4  %s"
"${c1}  k]x]]xg     %%x]]]]]]%%  %s"
"${c1}  Wx]]]W       x]]]]]]]  %s"
"${c1}  #]]]4         xx]]x]]  %s"
"${c1}   px]           ]]]]]x  %s"
"${c1}   Wx]           x]]x]]  %s"
"${c1}    &x           x]]]]   %s"
"${c1}     m           x]]]]   %s"
"${c1}                 x]x]    %s"
"${c1}                 x]]]    %s"
"${c1}                ]]]]"
"${c1}                x]x"
"${c1}               x]q"
"${c1}               ]g"
"${c1}              q")
		;;

		"SteamOS")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'grey') # Gray
				c2=$(getColor 'purple') # Dark Purple
				c3=$(getColor 'light purple') # Light Purple
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; c3="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c2}               .,,,,.                %s"
"${c2}         .,'onNMMMMMNNnn',.          %s"
"${c2}      .'oNM${c3}ANK${c2}MMMMMMMMMMMNNn'.       %s"
"${c3}    .'ANMMMMMMMXK${c2}NNWWWPFFWNNMNn.     %s"
"${c3}   ;NNMMMMMMMMMMNWW'' ${c2},.., ${c2}'WMMM,    %s"
"${c3}  ;NMMMMV+##+VNWWW' ${c3}.+;'':+, ${c3}'WM${c2}W,   %s"
"${c3} ,VNNWP+${c1}######${c3}+WW,  ${c1}+:    ${c3}:+, ${c3}+MMM,  %s"
"${c3} '${c1}+#############,   +.    ,+' ${c3}+NMMM  %s"
"${c1}   '*#########*'     '*,,*' ${c3}.+NMMMM. %s"
"${c1}      \`'*###*'          ,.,;###${c3}+WNM, %s"
"${c1}          .,;;,      .;##########${c3}+W  %s"
"${c1} ,',.         ';  ,+##############'  %s"
"${c1}  '###+. :,. .,; ,###############'   %s"
"${c1}   '####.. \`'' .,###############'    %s"
"${c1}     '#####+++################'      %s"
"${c1}       '*##################*'        %s"
"${c1}          ''*##########*''           %s"
"${c1}               ''''''                ")
		;;

		"SailfishOS")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'blue') # Blue
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}              .+eWWW            %s"
"${c1}          .+ee+++eee      e.    %s"
"${c1}       .ee++eeeeeeee    +e.     %s"
"${c1}     .e++ee++eeeeeee+eee+e+     %s"
"${c1}    ee.e+.ee+eee++eeeeee+       %s"
"${c1}   W.+e.e+.e++ee+eee            %s"
"${c1}  W.+e.W.ee.W++ee'              %s"
"${c1} +e.W W.e+.W.W+                 %s"
"${c1} W.e.+e.W W W.                  %s"
"${c1} e e e +e.W.W                   %s"
"${c1}       .W W W.                  %s"
"${c1}        W.+e.W.                 %s"
"${c1}         W++e.ee+.              %s"
"${c1}          ++ +ee++eeeee++.      %s"
"${c1}          '     '+++e   'ee.    %s"
"${c1}                           ee   %s"
"${c1}                            ee  %s"
"${c1}                             e  %s")
		;;

		"Qubes OS")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'cyan')
				c2=$(getColor 'blue')
				c3=$(getColor 'light blue')
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; c3="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c1      $c3                ####                     %s"
"$c1        $c3            ########                   %s"
"$c1          $c3        ############                 %s"
"$c1            $c3    #######  #######               %s"
"$c1              #$c3######      ######$c2#             %s"
"$c1            ####$c3###          ###$c2####           %s"
"$c1          ######        $c2        ######         %s"
"$c1          ######        $c2        ######         %s"
"$c1          ######        $c2        ######         %s"
"$c1          ######        $c2        ######         %s"
"$c1          ######        $c2        ######         %s"
"$c1            #######     $c2     #######           %s"
"$c1              #######   $c2   #########           %s"
"$c1                ####### $c2 ##############        %s"
"$c1                  ######$c2######  ######         %s"
"$c1                    ####$c2####     ###           %s"
"$c1                      ##$c2##                     %s"
"$c1                                                  %s")
		;;

		"PCLinuxOS")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'blue') # Blue
				c2=$(getColor 'light grey') # White
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"$c1                                                  %s"
"${c1}                                             <NNN>%s"
"${c1}                                           <NNY   %s"
"${c1}                 <ooooo>--.               ((      %s"
"${c1}               Aoooooooooooo>--.           \\\\\\     %s"
"${c1}              AooodNNNNNNNNNNNNNNNN>--.     ))    %s"
"${c1}          "${c2}"("${c1}"  AoodNNNNNNNNNNNNNNNNNNNNNNN>-///'    %s"
"${c1}          "${c2}"\\\\\\\\"${c1}"AodNNNNNNNNNNNNNNNNNNNNNNNNNNNY/      %s"
"${c1}           AodNNNNNNNNNNNNNNNNNNNNNNNNNNNNN       %s"
"${c1}          AdNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNA       %s"
"${c1}         ("${c2}"/)"${c1}"NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNA      %s"
"${c1}         "${c2}"//"${c1}"<NNNNNNNNNNNNNNNNNY'   YNNY YNNNN      %s"
"${c1} "${c2}",====#Y//"${c1}"   \`<NNNNNNNNNNNY       ANY     YNA     %s"
"${c1}               ANY<NNNNYYN       .NY        YN.   %s"
"${c1}             (NNY       NN      (NND       (NND   %s"
"${c1}                      (NNU                        %s"
"${c1}                                                         %s")
		;;

		"Exherbo")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'dark grey')  # Black
				c2=$(getColor 'light blue') # Blue
				c3=$(getColor 'light red')  # Beige
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; c3="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}  ,                                           %s"
"${c1}  OXo.                                        %s"
"${c1}  NXdX0:    .cok0KXNNXXK0ko:.                 %s"
"${c1}  KX  '0XdKMMK;.xMMMk, .0MMMMMXx;  ...        %s"
"${c1}  'NO..xWkMMx   kMMM    cMMMMMX,NMWOxOXd.     %s"
"${c1}    cNMk  NK    .oXM.   OMMMMO. 0MMNo  kW.    %s"
"${c1}    lMc   o:       .,   .oKNk;   ;NMMWlxW'    %s"
"${c1}   ;Mc    ..   .,,'    .0M${c2}g;${c1}WMN'dWMMMMMMO     %s"
"${c1}   XX        ,WMMMMW.  cM${c2}cfli${c1}WMKlo.   .kMk    %s"
"${c1}  .Mo        .WM${c2}GD${c1}MW.   XM${c2}WO0${c1}MMk        oMl   %s"
"${c1}  ,M:         ,XMMWx::,''oOK0x;          NM.  %s"
"${c1}  'Ml      ,kNKOxxxxxkkO0XXKOd:.         oMk  %s"
"${c1}   NK    .0Nxc${c3}:::::::::::::::${c1}fkKNk,      .MW  %s"
"${c1}   ,Mo  .NXc${c3}::${c1}qXWXb${c3}::::::::::${c1}oo${c3}::${c1}lNK.    .MW  %s"
"${c1}    ;Wo oMd${c3}:::${c1}oNMNP${c3}::::::::${c1}oWMMMx${c3}:${c1}c0M;   lMO  %s"
"${c1}     'NO;W0c${c3}:::::::::::::::${c1}dMMMMO${c3}::${c1}lMk  .WM'  %s"
"${c1}       xWONXdc${c3}::::::::::::::${c1}oOOo${c3}::${c1}lXN. ,WMd   %s"
"${c1}        'KWWNXXK0Okxxo,${c3}:::::::${c1},lkKNo  xMMO    %s"
"${c1}          :XMNxl,';:lodxkOO000Oxc. .oWMMo     %s"
"${c1}            'dXMMXkl;,.        .,o0MMNo'      %s"
"${c1}               ':d0XWMMMMWNNNNMMMNOl'         %s"
"${c1}                     ':okKXWNKkl'             %s")
		;;

		"Red Star OS")
			if [[ "$no_color" != "1" ]]; then
				c1=$(getColor 'light red')  # Red
			fi
			if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
			startline="0"
			fulloutput=(
"${c1}                      ..                     %s"
"${c1}                    .oK0l                    %s"
"${c1}                   :0KKKKd.                  %s"
"${c1}                 .xKO0KKKKd                  %s"
"${c1}                ,Od' .d0000l                 %s"
"${c1}               .c;.   .'''...           ..'. %s"
"${c1}  .,:cloddxxxkkkkOOOOkkkkkkkkxxxxxxxxxkkkx:  %s"
"${c1}  ;kOOOOOOOkxOkc'...',;;;;,,,'',;;:cllc:,.   %s"
"${c1}   .okkkkd,.lko  .......',;:cllc:;,,'''''.   %s"
"${c1}     .cdo. :xd' cd:.  ..';'',,,'',,;;;,'.    %s"
"${c1}        . .ddl.;doooc'..;oc;'..';::;,'.      %s"
"${c1}          coo;.oooolllllllcccc:'.  .         %s"
"${c1}         .ool''lllllccccccc:::::;.           %s"
"${c1}         ;lll. .':cccc:::::::;;;;'           %s"
"${c1}         :lcc:'',..';::::;;;;;;;,,.          %s"
"${c1}         :cccc::::;...';;;;;,,,,,,.          %s"
"${c1}         ,::::::;;;,'.  ..',,,,'''.          %s"
"${c1}          ........          ......           %s"
"${c1}                                             %s")
		;;

		*)
			if [ "$(echo "${kernel}" | grep 'Linux' )" ]; then
				if [[ "$no_color" != "1" ]]; then
					c1=$(getColor 'white') # White
					c2=$(getColor 'dark grey') # Light Gray
					c3=$(getColor 'yellow') # Light Yellow
				fi
				if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; c2="${my_lcolor}"; c3="${my_lcolor}"; fi
				startline="0"
				fulloutput=(
"                            %s"
"                            %s"
"                            %s"
"$c2         #####$c0              %s"
"$c2        #######             %s"
"$c2        ##"$c1"O$c2#"$c1"O$c2##             %s"
"$c2        #$c3#####$c2#             %s"
"$c2      ##$c1##$c3###$c1##$c2##           %s"
"$c2     #$c1##########$c2##          %s"
"$c2    #$c1############$c2##         %s"
"$c2    #$c1############$c2###        %s"
"$c3   ##$c2#$c1###########$c2##$c3#        %s"
"$c3 ######$c2#$c1#######$c2#$c3######      %s"
"$c3 #######$c2#$c1#####$c2#$c3#######      %s"
"$c3   #####$c2#######$c3#####        %s"
"                            %s"
"                            %s"
"                            %s")

			elif [[ "$(echo "${kernel}" | grep 'GNU' )" || "$(echo "${kernel}" | grep 'Hurd' )" || "${OSTYPE}" == "gnu" ]]; then
				startline="0"
				fulloutput=(
"    _-\`\`\`\`\`-,           ,- '- .      %s"
"   .'   .- - |          | - -.  \`.   %s"
"  /.'  /                     \`.   \\  %s"
" :/   :      _...   ..._      \`\`   : %s"
" ::   :     /._ .\`:'_.._\\.    ||   : %s"
" ::    \`._ ./  ,\`  :    \\ . _.''   . %s"
" \`:.      /   |  -.  \\-. \\\\\_      /  %s"
"   \\:._ _/  .'   .@)  \\@) \` \`\\ ,.'   %s"
"      _/,--'       .- .\\,-.\`--\`.     %s"
"        ,'/''     (( \\ \`  )          %s"
"         /'/'  \\    \`-'  (           %s"
"          '/''  \`._,-----'           %s"
"           ''/'    .,---'            %s"
"            ''/'      ;:             %s"
"              ''/''  ''/             %s"
"                ''/''/''             %s"
"                  '/'/'              %s"
"                   \`;                %s")
# Source: https://www.gnu.org/graphics/alternative-ascii.en.html
# Copyright (C) 2003, Vijay Kumar
# Permission is granted to copy, distribute and/or modify this image under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.

			else
				if [[ "$no_color" != "1" ]]; then
					c1=$(getColor 'light green') # Light Green
				fi
				if [ -n "${my_lcolor}" ]; then c1="${my_lcolor}"; fi
				startline="0"
				fulloutput=(
"                                            %s"
"                                            %s"
"$c1 UUU     UUU NNN      NNN IIIII XXX     XXXX%s"
"$c1 UUU     UUU NNNN     NNN  III    XX   xXX  %s"
"$c1 UUU     UUU NNNNN    NNN  III     XX xXX   %s"
"$c1 UUU     UUU NNN NN   NNN  III      XXXX    %s"
"$c1 UUU     UUU NNN  NN  NNN  III      xXX     %s"
"$c1 UUU     UUU NNN   NN NNN  III     xXXXX    %s"
"$c1 UUU     UUU NNN    NNNNN  III    xXX  XX   %s"
"$c1  UUUuuuUUU  NNN     NNNN  III   xXX    XX  %s"
"$c1    UUUUU    NNN      NNN IIIII xXXx    xXXx%s"
"                                            %s"
"                                            %s"
"                                            %s"
"                                            %s")
			fi
		;;
	esac


	# Truncate lines based on terminal width.
	if [ "$truncateSet" == "Yes" ]; then
		for ((i=0; i<${#fulloutput[@]}; i++)); do
			my_out=$(printf "${fulloutput[i]}$c0\n" "${out_array}")
			my_out_full=$(echo "$my_out" | cat -v)
			termWidth=$(tput cols)
			SHOPT_EXTGLOB_STATE=$(shopt -p extglob)
			read SHOPT_CMD SHOPT_STATE SHOPT_OPT <<< ${SHOPT_EXTGLOB_STATE}
			if [[ ${SHOPT_STATE} == "-u" ]]; then
				shopt -s extglob
			fi

			stringReal="${my_out_full//\^\[\[@([0-9]|[0-9];[0-9][0-9])m}"

			if [[ ${SHOPT_STATE} == "-u" ]]; then
				shopt -u extglob
			fi

			if [[ "${#stringReal}" -le "${termWidth}" ]]; then
				echo -e "${my_out}"$c0
			elif [[ "${#stringReal}" -gt "${termWidth}" ]]; then
				((NORMAL_CHAR_COUNT=0))
				for ((j=0; j<=${#my_out_full}; j++)); do
					if [[ "${my_out_full:${j}:3}" == '^[[' ]]; then
						if [[ "${my_out_full:${j}:5}" =~ ^\^\[\[[[:digit:]]m$ ]]; then
							if [[ ${j} -eq 0 ]]; then
								j=$((${j} + 5))
							else
								j=$((${j} + 4))
							fi
						elif [[ "${my_out_full:${j}:8}" =~ ^\^\[\[[[:digit:]]\;[[:digit:]][[:digit:]]m ]]; then
							if [[ ${j} -eq 0 ]]; then
								j=$((${j} + 8))
							else
								j=$((${j} + 7))
							fi
						fi
					else
						((NORMAL_CHAR_COUNT++))
						if [[ ${NORMAL_CHAR_COUNT} -ge ${termWidth} ]]; then
							echo -e "${my_out:0:$((${j} - 5))}"$c0
							break 1
						fi
					fi
				done
			fi

			if [[ "$i" -ge "$startline" ]]; then
				unset out_array[0]
				out_array=( "${out_array[@]}" )
			fi
		done

	elif [[ "$portraitSet" = "Yes" ]]; then
		for ((i=0; $i<${#fulloutput[*]}; i++)); do
			printf "${fulloutput[$i]}$c0\n"
		done

		printf "\n"

		for ((i=0; $i<${#fulloutput[*]}; i++)); do
			[[ -z "$out_array" ]] && continue
			printf "%s\n" "${out_array}"
			unset out_array[0]
			out_array=( "${out_array[@]}" )
		done

	elif [[ "$display_logo" == "Yes" ]]; then
		for ((i=0; i<${#fulloutput[*]}; i++)); do
			printf "${fulloutput[i]}$c0\n"
		done

	else
		#n=${#fulloutput[*]}
		for ((i=0; i<${#fulloutput[*]}; i++)); do
			# echo "${out_array[@]}"
			febreeze=$(awk 'BEGIN{srand();print int(rand()*(1000-1))+1 }')
			if [[ "${febreeze}" == "411" || "${febreeze}" == "188" || "${febreeze}" == "15" || "${febreeze}" == "166" || "${febreeze}" == "609" ]]; then
				f_size=${#fulloutput[*]}
				o_size=${#out_array[*]}
				f_max=$(( 32768 / f_size * f_size ))
				#o_max=$(( 32768 / o_size * o_size ))
				for ((a=f_size-1; a>0; a--)); do
					while (( (rand=$RANDOM) >= f_max )); do :; done
					rand=$(( rand % (a+1) ))
					tmp=${fulloutput[a]} fulloutput[a]=${fulloutput[rand]} fulloutput[rand]=$tmp
				done
				for ((b=o_size-1; b>0; b--)); do
					rand=$(( rand % (b+1) ))
					tmp=${out_array[b]} out_array[b]=${out_array[rand]} out_array[rand]=$tmp
				done
			fi
			printf "${fulloutput[i]}$c0\n" "${out_array}"
			if [[ "$i" -ge "$startline" ]]; then
				unset out_array[0]
				out_array=( "${out_array[@]}" )
			fi
		done
	fi
	# Done with ASCII output
}

infoDisplay () {
	textcolor="\033[0m"
	[[ "$my_hcolor" ]] && textcolor="${my_hcolor}"
	#TODO: Centralize colors and use them across the board so we only change them one place.
	myascii="${distro}"
	[[ "${asc_distro}" ]] && myascii="${asc_distro}"
	case ${myascii} in
		"Alpine Linux"|"Arch Linux - Old"|"Fedora"|"Korora"|"Chapeau"|"Mandriva"|"Mandrake"|"Chakra"|"ChromeOS"|"Sabayon"|"Slackware"|"Mac OS X"|"Trisquel"|"Kali Linux"|"Jiyuu Linux"|"Antergos"|"KaOS"|"Logos"|"gNewSense"|"Netrunner"|"NixOS"|"SailfishOS"|"Qubes OS"|"Kogaion"|"PCLinuxOS"|"Obarun") labelcolor=$(getColor 'light blue');;
		"Arch Linux"|"Frugalware"|"Mageia"|"Deepin"|"CRUX") labelcolor=$(getColor 'light cyan');;
		"Mint"|"LMDE"|"KDE neon"|"openSUSE"|"SUSE Linux Enterprise"|"LinuxDeepin"|"DragonflyBSD"|"Manjaro"|"Manjaro-tree"|"Android"|"Void") labelcolor=$(getColor 'light green');;
		"Ubuntu"|"FreeBSD"|"FreeBSD - Old"|"Debian"|"Raspbian"|"BSD"|"Red Hat Enterprise Linux"|"Oracle Linux"|"Peppermint"|"Cygwin"|"Msys"|"Fuduntu"|"Scientific Linux"|"DragonFlyBSD"|"BackTrack Linux"|"Red Star OS") labelcolor=$(getColor 'light red');;
		"CrunchBang"|"Solus"|"Viperr"|"elementary"*) labelcolor=$(getColor 'dark grey');;
		"Gentoo"|"Parabola GNU/Linux-libre"|"Funtoo"|"Funtoo-text"|"BLAG"|"SteamOS"|"Devuan") labelcolor=$(getColor 'light purple');;
		"Haiku") labelcolor=$(getColor 'green');;
		"NetBSD") labelcolor=$(getColor 'orange');;
		"CentOS"|*) labelcolor=$(getColor 'yellow');;
	esac
	[[ "$my_lcolor" ]] && labelcolor="${my_lcolor}"
	if [[ "$art" ]]; then source "$art"; fi
	if [[ "$no_color" == "1" ]]; then labelcolor=""; bold=""; c0=""; textcolor=""; fi
	# Some verbosity stuff
	[[ "$screenshot" == "1" ]] && verboseOut "Screenshot will be taken after info is displayed."
	[[ "$upload" == "1" ]] && verboseOut "Screenshot will be transferred/uploaded to specified location."
	#########################
	# Info Variable Setting #
	#########################
	if [[ "${distro}" == "Android" ]]; then
		myhostname=$(echo -e "${labelcolor} ${hostname}"); out_array=( "${out_array[@]}" "$myhostname" )
		mydistro=$(echo -e "$labelcolor OS:$textcolor $distro $distro_ver"); out_array=( "${out_array[@]}" "$mydistro" )
		mydevice=$(echo -e "$labelcolor Device:$textcolor $device"); out_array=( "${out_array[@]}" "$mydevice" )
		myrom=$(echo -e "$labelcolor ROM:$textcolor $rom"); out_array=( "${out_array[@]}" "$myrom" )
		mybaseband=$(echo -e "$labelcolor Baseband:$textcolor $baseband"); out_array=( "${out_array[@]}" "$mybaseband" )
		mykernel=$(echo -e "$labelcolor Kernel:$textcolor $kernel"); out_array=( "${out_array[@]}" "$mykernel" )
		myuptime=$(echo -e "$labelcolor Uptime:$textcolor $uptime"); out_array=( "${out_array[@]}" "$myuptime" )
		mycpu=$(echo -e "$labelcolor CPU:$textcolor $cpu"); out_array=( "${out_array[@]}" "$mycpu" )
		mygpu=$(echo -e "$labelcolor GPU:$textcolor $cpu"); out_array=( "${out_array[@]}" "$mygpu" )
		mymem=$(echo -e "$labelcolor RAM:$textcolor $mem"); out_array=( "${out_array[@]}" "$mymem" )
	else
		if [[ "${display[@]}" =~ "host" ]]; then myinfo=$(echo -e "${labelcolor} ${myUser}$textcolor${bold}@${c0}${labelcolor}${myHost}"); out_array=( "${out_array[@]}" "$myinfo" ); ((display_index++)); fi
		if [[ "${display[@]}" =~ "distro" ]]; then
			if [ "$distro" == "Mac OS X" ]; then
				sysArch=`str1=$(getconf LONG_BIT);echo ${str1}bit`
				prodVers=`prodVers=$(sw_vers|grep ProductVersion);echo ${prodVers:15}`
				buildVers=`buildVers=$(sw_vers|grep BuildVersion);echo ${buildVers:14}`
				if [ -n "$distro_more" ]; then mydistro=$(echo -e "$labelcolor OS:$textcolor $distro_more $sysArch")
				else mydistro=$(echo -e "$labelcolor OS:$textcolor $sysArch $distro $prodVers $buildVers"); fi
			elif [[ "$distro" == "Cygwin" || "$distro" == "Msys" ]]; then
				distro="$(wmic os get caption | sed 's/\r//g; s/[ \t]*$//g; 2!d')"
				if [[ "$(wmic os get version | grep -o '^10\.')" == "10." ]]; then
					distro="$distro (v$(wmic os get version | grep '^10\.' | tr -d ' '))"
				fi
				sysArch=$(wmic os get OSArchitecture | sed 's/\r//g; s/[ \t]*$//g; 2!d')
				mydistro=$(echo -e "$labelcolor OS:$textcolor $distro $sysArch")
			else
				if [ -n "$distro_more" ]; then mydistro=$(echo -e "$labelcolor OS:$textcolor $distro_more")
				else mydistro=$(echo -e "$labelcolor OS:$textcolor $distro $sysArch"); fi
			fi
			out_array=( "${out_array[@]}" "$mydistro$uow" )
			((display_index++))
		fi
		if [[ "${display[@]}" =~ "kernel" ]]; then mykernel=$(echo -e "$labelcolor Kernel:$textcolor $kernel"); out_array=( "${out_array[@]}" "$mykernel" ); ((display_index++)); fi
		if [[ "${display[@]}" =~ "uptime" ]]; then myuptime=$(echo -e "$labelcolor Uptime:$textcolor $uptime"); out_array=( "${out_array[@]}" "$myuptime" ); ((display_index++)); fi
		if [[ "${display[@]}" =~ "pkgs" ]]; then mypkgs=$(echo -e "$labelcolor Packages:$textcolor $pkgs"); out_array=( "${out_array[@]}" "$mypkgs" ); ((display_index++)); fi
		if [[ "${display[@]}" =~ "shell" ]]; then myshell=$(echo -e "$labelcolor Shell:$textcolor $myShell"); out_array=( "${out_array[@]}" "$myshell" ); ((display_index++)); fi
		if [[ -n "$DISPLAY" || "$distro" == "Mac OS X" ]]; then
			if [ -n "${xResolution}" ]; then
				if [[ "${display[@]}" =~ "res" ]]; then myres=$(echo -e "$labelcolor Resolution:${textcolor} $xResolution"); out_array=( "${out_array[@]}" "$myres" ); ((display_index++)); fi
			fi
			if [[ "${display[@]}" =~ "de" ]]; then
				if [[ "${DE}" != "Not Present" ]]; then
					myde=$(echo -e "$labelcolor DE:$textcolor $DE"); out_array=( "${out_array[@]}" "$myde" ); ((display_index++))
				fi
			fi
			if [[ "${display[@]}" =~ "wm" ]]; then mywm=$(echo -e "$labelcolor WM:$textcolor $WM"); out_array=( "${out_array[@]}" "$mywm" ); ((display_index++)); fi
			if [[ "${display[@]}" =~ "wmtheme" ]]; then
					if [[ "${Win_theme}" == "Not Applicable" || "${Win_theme}" == "Not Found" ]]; then
						:
					else
						mywmtheme=$(echo -e "$labelcolor WM Theme:$textcolor $Win_theme"); out_array=( "${out_array[@]}" "$mywmtheme" ); ((display_index++)); fi
					fi
			if [[ "${display[@]}" =~ "gtk" ]]; then
				if [ "$distro" == "Mac OS X" ]; then
					if [[ "$gtkFont" != "Not Applicable" && "$gtkFont" != "Not Found" ]]; then
						if [ -n "$gtkFont" ]; then
							myfont=$(echo -e "$labelcolor Font:$textcolor $gtkFont"); out_array=( "${out_array[@]}" "$myfont" ); ((display_index++))
						fi
					fi
				else
					if [[ "$gtk2Theme" != "Not Applicable" && "$gtk2Theme" != "Not Found" ]]; then
						if [ -n "$gtk2Theme" ]; then
							mygtk2="${gtk2Theme} [GTK2]"
						fi
					fi
					if [[ "$gtk3Theme" != "Not Applicable" && "$gtk3Theme" != "Not Found" ]]; then
						if [ -n "$mygtk2" ]; then
							mygtk3=", ${gtk3Theme} [GTK3]"
						else
							mygtk3="${gtk3Theme} [GTK3]"
						fi
					fi
					if [[ "$gtk_2line" == "yes" ]]; then
						mygtk2=$(echo -e "$labelcolor GTK2 Theme:$textcolor $gtk2Theme"); out_array=( "${out_array[@]}" "$mygtk2" ); ((display_index++))
						mygtk3=$(echo -e "$labelcolor GTK3 Theme:$textcolor $gtk3Theme"); out_array=( "${out_array[@]}" "$mygtk3" ); ((display_index++))
					else
						if [[ "$gtk2Theme" == "$gtk3Theme" ]]; then
							if [[ "$gtk2Theme" != "Not Applicable" && "$gtk2Theme" != "Not Found" ]]; then
								mygtk=$(echo -e "$labelcolor GTK Theme:$textcolor ${gtk2Theme} [GTK2/3]"); out_array=( "${out_array[@]}" "$mygtk" ); ((display_index++))
							fi
						else
							mygtk=$(echo -e "$labelcolor GTK Theme:$textcolor ${mygtk2}${mygtk3}"); out_array=( "${out_array[@]}" "$mygtk" ); ((display_index++))
						fi
					fi
					if [[ "$gtkIcons" != "Not Applicable" && "$gtkIcons" != "Not Found" ]]; then
						if [ -n "$gtkIcons" ]; then
							myicons=$(echo -e "$labelcolor Icon Theme:$textcolor $gtkIcons"); out_array=( "${out_array[@]}" "$myicons" ); ((display_index++))
						fi
					fi
					if [[ "$gtkFont" != "Not Applicable" && "$gtkFont" != "Not Found" ]]; then
						if [ -n "$gtkFont" ]; then
							myfont=$(echo -e "$labelcolor Font:$textcolor $gtkFont"); out_array=( "${out_array[@]}" "$myfont" ); ((display_index++))
						fi
					fi
					# [ "$gtkBackground" ] && mybg=$(echo -e "$labelcolor BG:$textcolor $gtkBackground"); out_array=( "${out_array[@]}" "$mybg" ); ((display_index++))
				fi
			fi
		elif [[ "$fake_distro" == "Cygwin" || "$fake_distro" == "Msys" || "$fake_distro" == "Windows - Modern" ]]; then
			if [[ "${display[@]}" =~ "res" && -n "$xResolution" ]]; then myres=$(echo -e "$labelcolor Resolution:${textcolor} $xResolution"); out_array=( "${out_array[@]}" "$myres" ); ((display_index++)); fi
			if [[ "${display[@]}" =~ "de" ]]; then
				if [[ "${DE}" != "Not Present" ]]; then
					myde=$(echo -e "$labelcolor DE:$textcolor $DE"); out_array=( "${out_array[@]}" "$myde" ); ((display_index++))
				fi
			fi
			if [[ "${display[@]}" =~ "wm" ]]; then mywm=$(echo -e "$labelcolor WM:$textcolor $WM"); out_array=( "${out_array[@]}" "$mywm" ); ((display_index++)); fi
			if [[ "${display[@]}" =~ "wmtheme" ]]; then
				if [[ "${Win_theme}" == "Not Applicable" || "${Win_theme}" == "Not Found" ]]; then
					:
				else
					mywmtheme=$(echo -e "$labelcolor WM Theme:$textcolor $Win_theme"); out_array=( "${out_array[@]}" "$mywmtheme" ); ((display_index++))
				fi
			fi
		elif [[ "$distro" == "Haiku" ]]; then
			if [ -n "${xResolution}" ]; then
				if [[ "${display[@]}" =~ "res" ]]; then myres=$(echo -e "$labelcolor Resolution:${textcolor} $xResolution"); out_array=( "${out_array[@]}" "$myres" ); ((display_index++)); fi
			fi
		fi
		[[ "${fake_distro}" != "Cygwin" && "${fake_distro}" != "Msys" && "${fake_distro}" != "Windows - Modern" ]] && if [[ "${display[@]}" =~ "disk" ]]; then mydisk=$(echo -e "$labelcolor Disk:$textcolor $diskusage"); out_array=( "${out_array[@]}" "$mydisk" ); ((display_index++)); fi
		if [[ "${display[@]}" =~ "cpu" ]]; then mycpu=$(echo -e "$labelcolor CPU:$textcolor $cpu"); out_array=( "${out_array[@]}" "$mycpu" ); ((display_index++)); fi
		if [[ "${display[@]}" =~ "gpu" ]] && [[ "$gpu" != "Not Found" ]]; then mygpu=$(echo -e "$labelcolor GPU:$textcolor $gpu"); out_array=( "${out_array[@]}" "$mygpu" ); ((display_index++)); fi
		if [[ "${display[@]}" =~ "mem" ]]; then mymem=$(echo -e "$labelcolor RAM:$textcolor $mem"); out_array=( "${out_array[@]}" "$mymem" ); ((display_index++)); fi
	fi
	if [[ "$display_type" == "ASCII" ]]; then
		asciiText
	else
		if [[ "${display[@]}" =~ "host" ]]; then echo -e "$myinfo"; fi
		if [[ "${display[@]}" =~ "distro" ]]; then echo -e "$mydistro"; fi
		if [[ "${display[@]}" =~ "kernel" ]]; then echo -e "$mykernel"; fi
		if [[ "${distro}" == "Android" ]]; then
			echo -e "$mydevice"
			echo -e "$myrom"
			echo -e "$mybaseband"
			echo -e "$mykernel"
			echo -e "$myuptime"
			echo -e "$mycpu"
			echo -e "$mymem"
		else
			if [[ "${display[@]}" =~ "uptime" ]]; then echo -e "$myuptime"; fi
			if [[ "${display[@]}" =~ "pkgs" && "$mypkgs" != "Unknown" ]]; then echo -e "$mypkgs"; fi
			if [[ "${display[@]}" =~ "shell" ]]; then echo -e "$myshell"; fi
			if [[ "${display[@]}" =~ "res" ]]; then
				test -z "$myres" || echo -e "$myres"
			fi
			if [[ "${display[@]}" =~ "de" ]]; then
				if [[ "${DE}" != "Not Present" ]]; then echo -e "$myde"; fi
			fi
			if [[ "${display[@]}" =~ "wm" ]]; then
				test -z "$mywm" || echo -e "$mywm"
				if [[ "${Win_theme}" != "Not Applicable" && "${Win_theme}" != "Not Found" ]]; then
					test -z "$mywmtheme" || echo -e "$mywmtheme"
				fi
			fi
			if [[ "${display[@]}" =~ "gtk" ]]; then
				if [[ "$gtk_2line" == "yes" ]]; then
					test -z "$mygtk2" || echo -e "$mygtk2"
					test -z "$mygtk3" || echo -e "$mygtk3"
				else
					test -z "$mygtk" || echo -e "$mygtk"
				fi
				test -z "$myicons" || echo -e "$myicons"
				test -z "$myfont" || echo -e "$myfont"
			fi
			if [[ "${display[@]}" =~ "disk" ]]; then echo -e "$mydisk"; fi
			if [[ "${display[@]}" =~ "cpu" ]]; then echo -e "$mycpu"; fi
			if [[ "${display[@]}" =~ "gpu" ]]; then echo -e "$mygpu"; fi
			if [[ "${display[@]}" =~ "mem" ]]; then echo -e "$mymem"; fi
		fi
	fi
}

##################
# Let's Do This!
##################

if [[ -f "$HOME/.screenfetchOR" ]]; then
	source $HOME/.screenfetchOR
fi


if [[ "$overrideDisplay" ]]; then
	verboseOut "Found 'd' flag in syntax. Overriding display..."
	OLDIFS=$IFS
	IFS=';'
	for i in ${overrideDisplay}; do
		modchar="${i:0:1}"
		if [[ "${modchar}" == "-" ]]; then
			i=${i/${modchar}}
			_OLDIFS=IFS
			IFS=,
			for n in $i; do
				if [[ ! "${display[@]}" =~ "$n" ]]; then
					echo "The var $n is not currently being displayed."
				else
					display=( "${display[@]/${n}}" )
				fi
			done
			IFS=$_OLDIFS
		elif [[ "${modchar}" == "+" ]]; then
			i=${i/${modchar}}
			_OLDIFS=IFS
			IFS=,
			for n in $i; do
				if [[ "${valid_display[@]}" =~ "$n" ]]; then
					if [[ "${display[@]}" =~ "$n" ]]; then
						echo "The $n var is already being displayed."
					else
						display+=($n)
					fi
				else
					echo "The var $n is not a valid display var."
				fi
			done
			IFS=$_OLDIFS
		else
			IFS=$OLDIFS
			i="${i//,/ }"
			display=( $i )
		fi
	done
	IFS=$OLDIFS
fi

# Check for android
if [ -f /system/build.prop ]; then
	distro="Android"
	detectmem
	detectuptime
	detectkernel
	detectdroid
	infoDisplay
	exit 0
fi

for i in "${display[@]}"; do
	if [[ ! "$i" == "" ]]; then
		if [[ $i =~ wm ]]; then
			 ! [[ $WM  ]] && detectwm;
			 ! [[ $Win_theme ]] && detectwmtheme;
		else
			if [[ "${display[*]}" =~ "$i" ]]; then
				if [[ "$errorSuppress" == "1" ]]; then detect${i} 2>/dev/null
				else
					exec 3> >(stderrOut)
					detect${i} 2>&3
					exec 3>&-
				fi
			fi
		fi
	fi
done

infoDisplay
[ "$screenshot" == "1" ] && takeShot
[ "$exportTheme" == "1" ] && themeExport

exit 0
END
chmod +x /usr/bin/screenfetch
echo "clear" >> .profile
echo "screenfetch" >> .profile

# install webserver
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
cat > /etc/nginx/nginx.conf <<-END
user www-data;

worker_processes 1;
pid /var/run/nginx.pid;

events {
	multi_accept on;
  worker_connections 1024;
}

http {
	gzip on;
	gzip_vary on;
	gzip_comp_level 5;
	gzip_types    text/plain application/x-javascript text/xml text/css;

	autoindex on;
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 2048;
  server_tokens off;
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;
  client_max_body_size 32M;
	client_header_buffer_size 8m;
	large_client_header_buffers 8 8m;

	fastcgi_buffer_size 8m;
	fastcgi_buffers 8 8m;

	fastcgi_read_timeout 600;

  include /etc/nginx/conf.d/*.conf;
}
END
mkdir -p /home/vps/public_html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
args='$args'
uri='$uri'
document_root='$document_root'
fastcgi_script_name='$fastcgi_script_name'
cat > /etc/nginx/conf.d/vps.conf <<-END
server {
  listen       81;
  server_name  127.0.0.1 localhost;
  access_log /var/log/nginx/vps-access.log;
  error_log /var/log/nginx/vps-error.log error;
  root   /home/vps/public_html;

  location / {
    index  index.html index.htm index.php;
    try_files $uri $uri/ /index.php?$args;
  }

  location ~ \.php$ {
    include /etc/nginx/fastcgi_params;
    fastcgi_pass  127.0.0.1:9000;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
  }
}

END
sed -i 's/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php5/fpm/pool.d/www.conf
service php5-fpm restart
service nginx restart

# install vnstat gui
cd /home/vps/public_html/
wget https://raw.githubusercontent.com/airblue18/OS-script/master/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 vnstat
mv vnstat/*\ .
sed -i "s/\$iface_list = array('eth0', 'sixxs');/\$iface_list = array('eth0');/g" config.php
sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
sed -i 's/Internal/Internet/g' config.php
sed -i '/SixXS IPv6/d' config.php
cd

# ติดตั้งพร็อกซี่
apt-get -y install squid3;
cat > /etc/squid3/squid.conf <<-END
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
acl SSH dst xxxxxxxxx-xxxxxxxxx/32
http_access allow SSH
http_access allow manager localhost
http_access deny manager
http_access allow localhost
http_access deny all
http_port 8080
http_port 8000
http_port 3128
coredump_dir /var/spool/squid3
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
visible_hostname www.viber.com
END
MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0' | grep -v '192.168'`;
sed -i s/xxxxxxxxx/$MYIP/g /etc/squid3/squid.conf;
service squid3 restart;

# install mrtg
cat > /etc/snmp/snmpd.conf <<-END1
com2sec local     localhost           public
group MyRWGroup v1         local
group MyRWGroup v2c        local
group MyRWGroup usm        local
view all    included  .1                               80
access MyRWGroup ""      any       noauth    exact  all    all    none
syslocation Bangkok, Thailnd
syscontact Root <vpnseller54@gmail.com>

END1
cat > /root/mrtg-mem.sh <<END2
#!/bin/bash

FREE=`free -m | grep "buffers/cache" | awk '{print $3}'`
SWAP=`free -m | grep "Swap" | awk '{print $3}'`
UP=`uptime`

echo $FREE
echo $SWAP
echo $UP
echo "kunphiphit"
END2
chmod +x /root/mrtg-mem.sh
cd /etc/snmp/
sed -i 's/TRAPDRUN=no/TRAPDRUN=yes/g' /etc/default/snmpd
service snmpd restart
snmpwalk -v 1 -c public localhost 1.3.6.1.4.1.2021.10.1.3.1
mkdir -p /home/vps/public_html/mrtg
cfgmaker --zero-speed 100000000 --global 'WorkDir: /home/vps/public_html/mrtg' --output /etc/mrtg.cfg public@localhost
cat > /etc/mrtg.cfg <<END3
LoadMIBs: /usr/share/mibs/netsnmp/UCD-SNMP-MIB
Target[localhost.cpu]:(100 * 1.3.6.1.4.1.2021.10.1.3.1&1.3.6.1.4.1.2021.10.1.3.1:public@127.0.0.1)
RouterUptime[localhost.cpu]: public@127.0.0.1
MaxBytes[localhost.cpu]: 400
Title[localhost.cpu]: CPU Load
PageTop[localhost.cpu]: <H1>Active CPU Load %</H1>
#Unscaled[localhost.cpu]: ymwd
ShortLegend[localhost.cpu]: %
YLegend[localhost.cpu]: CPU Utilization
Legend1[localhost.cpu]: Active CPU in % (Load)
Legend2[localhost.cpu]:
Legend3[localhost.cpu]:
Legend4[localhost.cpu]:
LegendI[localhost.cpu]:  Active
LegendO[localhost.cpu]:
Options[localhost.cpu]: growright,nopercent,gauge

Target[localhost.freemem]: `/root/mrtg-mem.sh`
RouterUptime[localhost.freemem]: public@127.0.0.1
Title[localhost.freemem]: Memory Used 
PageTop[localhost.freemem]: <h1>Memory Used</h1>
MaxBytes[localhost.freemem]: 8192
ShortLegend[localhost.freemem]: B
YLegend[localhost.freemem]: Bytes
LegendI[localhost.freemem]: RAM
LegendO[localhost.freemem]: Swap
Options[localhost.freemem]: gauge,nopercent,growright,unknaszero
kMG[localhost.freemem]: k,M,G,T,P,X

END3
sed -i 's/WorkDir: \/var\/www\/mrtg/# WorkDir: \/var\/www\/mrtg/g' /etc/mrtg.cfg
sed -i 's/# Options\[_\]: growright, bits/Options\[_\]: growright/g' /etc/mrtg.cfg
indexmaker --output=/home/vps/public_html/mrtg/index.html /etc/mrtg.cfg
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
cd

# ตั้งค่า ไฟล์วอลล์
sudo ufw allow 22,80,81,222,443,5002,8080,9700,60000/tcp
sudo ufw allow 22,80,81,222,443,8080,5002,9700,60000/udp
sed -i 's|DEFAULT_INPUT_POLICY="DROP"|DEFAULT_INPUT_POLICY="ACCEPT"|' /etc/default/ufw
sed -i 's|DEFAULT_FORWARD_POLICY="DROP"|DEFAULT_FORWARD_POLICY="ACCEPT"|' /etc/default/ufw
cat > /etc/ufw/before.rules <<-END
# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to eth0
-A POSTROUTING -s 10.0.0.0/8 -o eth0 -j MASQUERADE
-A POSTROUTING -s 172.16.0.0/12 -o eth0 -j MASQUERADE
-A POSTROUTING -s 192.168.0.0/16 -o eth0 -j MASQUERADE
-A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
-A POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
COMMIT
# END OPENVPN RULES
END
sudo yes | ufw enable

# set ipv4 forward
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf

# install badvpn
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/kunphiphit/Debian8/master/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/kunphiphit/Debian8/master/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# install ddos deflate
cd
apt-get -y install dnsutils dsniff
wget https://github.com/jgmdev/ddos-deflate/archive/master.zip
unzip master.zip
cd ddos-deflate-master
./install.sh
rm -rf /root/master.zip

#Setting IPtables
cat > /etc/iptables.up.rules <<-END
*nat
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -j SNAT --to-source xxxxxxxxx
-A POSTROUTING -o eth0 -j MASQUERADE
-A POSTROUTING -s 10.0.0.0/8 -o eth0 -j MASQUERADE
-A POSTROUTING -s 172.16.0.0/12 -o eth0 -j MASQUERADE
-A POSTROUTING -s 192.168.0.0/16 -o eth0 -j MASQUERADE
-A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
-A POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
COMMIT

*filter
:INPUT ACCEPT [19406:27313311]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [9393:434129]
-A FORWARD -i eth0 -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -i tun0 -o eth0 -j ACCEPT
-A INPUT -p ICMP --icmp-type 8 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 53 -j ACCEPT
-A INPUT -p tcp --dport 22  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 80  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 80  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 81  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 443  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 1194  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 3128  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 5002  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 7300  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 8000  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 8080  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 10000  -m state --state NEW -j ACCEPT
COMMIT

*raw
:PREROUTING ACCEPT [158575:227800758]
:OUTPUT ACCEPT [46145:2312668]
COMMIT

*mangle
:PREROUTING ACCEPT [158575:227800758]
:INPUT ACCEPT [158575:227800758]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [46145:2312668]
:POSTROUTING ACCEPT [46145:2312668]
COMMIT
END
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local
sed -i $MYIP2 /etc/iptables.up.rules;
iptables-restore < /etc/iptables.up.rules

# finalizing
apt-get -y autoremove
chown -R www-data:www-data /home/vps/public_html
service nginx start
service php5-fpm start
service vnstat restart
service pritunl restart
service snmpd restart
service ssh restart
service squid3 restart
sysv-rc-conf rc.local on

#clearing history
history -c
clear
echo "กดที่ url เพื่อใช้งาน : https://$MYIP"
pritunl setup-key
echo ""


ipconfig