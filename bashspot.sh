#!/bin/bash

# Add a few checks to see if some functionalities are installed.
# Ask if the user wants to install the packages

if [[ $EUID -ne 0 || $# -ne 1 ]];
then
	echo "[+] This script must be run as root!"
	echo "[+] Usage: {sudo} ./bashspot.sh [USB_INTERFACE]"
	exit 1
fi

echo ""
echo "[+] Type the SSID of the new access point"

read ssid

echo ""
echo "[+] Type the password of the new access point"

read -s pass

interface=$1

echo ""
echo "[?] Do you want to install drivers for the USB adapter?[?]"
echo "[?] Packages: firmware-linux / firmware-linux-nonfree / firmware-ralink / wireless-tools[?]"
read -p "[?] y/N [?]"
if [ $REPLY =~ ^[yY]$ ];
then
	echo ""
	echo "[+] Installing drivers..."
	apt-get install firmware-linux firmware-linux-nonfree firmware-ralink wireless-tools
else
	echo "[-] Skipping drivers installation [-]"
fi

echo ""
echo "[+] Checking if required packages are installed"
echo "[+] Checking dnsmasq...."

dnsmasq=$(dpkg -s dnsmasq 2>/dev/null | grep "installed")
if [ -z "$dnsmasq" ];
then
	echo "[-] Dnsmasq is not installed....installing now!"
        apt-get install hostapd
else
	echo "[+] Dnsmasq already installed!"
fi

echo "[+] Checking hostapd..."

hostapd=$(dpkg -s hostapd 2>/dev/null | grep "installed")
if [ -z "$hostapd" ];
then
	echo "[-] Hostapd is not installed....installing now!"
	apt-get install dnsmasq
else
	echo "[+] Hostapd already installed"
fi

echo "[+] Setting USB interface ip address"

ip a add 192.168.35.1/24 dev $interface
sleep 2

echo "[+] Setting up dnsmasq.conf"

cat >dnsmasq.conf<<EOF
# disables dnsmasq reading any other files like /etc/resolv.conf for nameservers
no-resolv
# Interface to bind to
interface=$interface
# Specify starting_range,end_range,lease_time
dhcp-range=192.168.35.10,192.168.35.15,255.255.255.0,12h
# dns addresses to send to the clients
server=8.8.8.8
server=8.8.4.4
EOF

echo "[+} Starting dnsmasq"

dnsmasq -C dnsmasq.conf 

echo "[+] Setting iptables rules"

iptables --table nat --append POSTROUTING -j MASQUERADE
iptables --append FORWARD -j ACCEPT

echo "[+] Setting port forward option"

sysctl -w net.ipv4.ip_forward=1

echo "[+] Setting up the hostapd run.conf" 

cat >run.conf<<EOF
#sets the wifi interface to use, is wlan0 in most cases
interface=$interface
#driver to use, nl80211 works in most cases
driver=nl80211
#sets the ssid of the virtual wifi access point
ssid=$ssid
#sets the mode of wifi, depends upon the devices you will be using. It can be a,b,g,n. Setting to g ensures backward compatiblity.
hw_mode=g
#sets the channel for your wifi
channel=6
#macaddr_acl sets options for mac address filtering. 0 means "accept unless in deny list"
macaddr_acl=0
#setting ignore_broadcast_ssid to 1 will disable the broadcasting of ssid
ignore_broadcast_ssid=0
#Sets authentication algorithm
#1 - only open system authentication
#2 - both open system authentication and shared key authentication
auth_algs=1
#####Sets WPA and WPA2 authentication#####
#wpa option sets which wpa implementation to use
#1 - wpa only
#2 - wpa2 only
#3 - both
wpa=3
#sets wpa passphrase required by the clients to authenticate themselves on the network
wpa_passphrase=$pass
#sets wpa key management
wpa_key_mgmt=WPA-PSK
#sets encryption used by WPA
wpa_pairwise=TKIP
#sets encryption used by WPA2
rsn_pairwise=CCMP
#################################
#####Sets WEP authentication#####
#WEP is not recommended as it can be easily broken into
#wep_default_key=0
#wep_key0=qwert    #5,13, or 16 characters
#optionally you may also define wep_key2, wep_key3, and wep_key4
#################################
#For No encryption, you don't need to set any options
EOF

echo "[+] Starting hostapd"

hostapd run.conf 

echo "[-] Cleaning up..."

killall dnsmasq
ip a del 192.168.35.1/24 dev $interface
sysctl -w net.ipv4.ip_forward=0
rm run.conf
rm dnsmasq.conf
