#!/bin/bash

# configure hostname
/usr/bin/hostnamectl set-hostname ${hostname}
echo ${hostname} > /etc/hostname

# eth0 dns
nmcli con mod "Wired connection 1" ipv4.dns "1.1.1.1 1.0.0.1"
nmcli con mod "Wired connection 1" ipv4.dns-search "${domain}" yes
nmcli con mod "Wired connection 1" ipv4.ignore-auto-dns yes
nmcli con mod "Wired connection 1" ipv6.ignore-auto-dns yes

# eth1 dns
nmcli con mod "Wired connection 2" ipv4.ignore-auto-dns yes
nmcli con mod "Wired connection 2" ipv6.ignore-auto-dns yes

# disable ipv6 (as autoconfig does not work and there is no metadata api endpoint for getting the ipv6 network)
nmcli connection modify "Wired connection 1" ipv6.method "disabled"
nmcli connection modify "Wired connection 2" ipv6.method "disabled"

# reload configuration
nmcli connection reload
