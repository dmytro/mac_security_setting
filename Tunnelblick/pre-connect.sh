#!/bin/bash
#
# Tunnelblick certificate expiration check.
#
# This script verifies expiration time of the OpenVPN client
# certificate and opens AppleScript pop-out with a warning message if
# expiration is in less then ${WARN} days. Script is executed by
# Tunnelblick when user initiates connection.
#
# Installation
#
# - Copy script to the OpenVPN configuration directory ( for
#   Tunnelblick version 3.4.2 it's
#   ~/Library/openvpn/<<CONFIGURATION_NAME>>.tblk/Contents/Resources)
#   and make it executable.
#
# Configuration
#
# - Set WARN variable if you want different warning
# - Script expects OpenVPN configuration file named `config.ovpn`
#
PATH=/bin:/usr/bin

WARN=30
DIR=$(dirname "${BASH_SOURCE[0]}")
cd "$DIR"

CERT=$( awk  '$1 ~ /^cert$/ {print $2}' < config.ovpn)

DATE=$(openssl x509 -in ${CERT} -inform PEM -text -noout -enddate | grep -E "^notAfter=" | cut -d= -f2)

DAYS=$(ruby -rdate -e "print((Date.parse(\"${DATE}\") - Date.today).to_i)")

if [ $DAYS -lt $WARN ]; then
  osascript <<-EOSCRIPT

tell application "System Events" to display alert "OpenVPN certificate expiration warning" message "Your OpenVPN certificate expires in ${DAYS} days on ${DATE}. \n\n Do not forget to renew in time." as critical  buttons "OK" default button 1

EOSCRIPT

fi

#  LocalWords:  Tunnelblick OpenVPN AppleScript
