Mac Security Setting
====================

Scripts to set MacOSX security, mainly to satisfy PCI DSS requirements

# Hardening Mac security #

Script `setup_security.sh` performs several modifications required by PCI DSS:

- creates admininstator account:
    - with randomly generated password;
    - password should be printed out and stored securely for emergency access;
- sets password policies for user running script:
  - account lock after defined number of failed login attempts;
  - password expiration
  - sets screenlock time
  - and requirement to use password for unlock.


## Installation ##

Deploy security setting using this command line:


    curl -sSL https://raw.githubusercontent.com/Coiney/mac_security_setting/master/setup_security.sh | bash

## Requirements ##

## Known problems ##

1. Password expiration warning reported broken in 10.9 but resolved in 10.10 (both not tested --DK)

* https://discussions.apple.com/thread/2636399?tstart=0
* https://macmule.com/2014/03/29/no-password-expiry-warning-at-the-login-window-on-10-9/

2. MacOSX `passwd` command does not return status code on error (always 0). If user password change unsuccessfull, script continues.

# Other #

## Tunnelblick

Script `pre-connect.sh` in Tunnelblick directory is small utility to verify expiration time of the OpenVPN client certificate. Script is executed by Tunnelblick when user initiates connection and pops-out warning message if expiration is in less then specified number of days.

TODO
----

Show password expiration:

dscl localhost -readpl /Local/Default/Users/${USER} PasswordPolicyOptions passwordLastSetTime
