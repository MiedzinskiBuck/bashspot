# Bashspot

A really basic script to use a wireless USB adapter as an AP to perform some tests.

To run this script you need to have hostapd and dnsmasq installed. The script will automatically install then if you do not have then already.

Please note that this script was written in a Debian machine, so maybe you'll need to install these packages in a different way.

Also, in order for these packages to run, they need to have root permissions, so you'll need to run this script as root.

The script will ask if you want to install some drivers to proper run hostapd. These drivers are from an Alfa wireless adapter. If your adapter uses different drivers, you'll need to install them.

### Usage

```sh
$ sudo ./bashspot.sh [USB_INTERFACE]
```

USB-INTERFACE = The name of the usb interface that you are using. You can get this name with "ifconfig" or "ip addr".
