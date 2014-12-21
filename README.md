Mac Security Setting
====================

Scripts to set MacOSX security, mainly to satisfy PCI DSS requirements


Installation
----------------------

Deploy security setting using this command line:


    curl -sSL https://raw.githubusercontent.com/Coiney/mac_security_setting/master/setup_security.sh | bash

Requirements
------------

Known problems
----------------------

1. Password expiration warning reported broken in 10.9 but resolved in 10.10 (both not tested --DK)

* https://discussions.apple.com/thread/2636399?tstart=0
* https://macmule.com/2014/03/29/no-password-expiry-warning-at-the-login-window-on-10-9/

2. MacOSX `passwd` command does not return status code on error (always 0). If user password change unsuccessfull, script continues.


TODO
----

Show password expiration:

dscl localhost -readpl /Local/Default/Users/${USER} PasswordPolicyOptions passwordLastSetTime
