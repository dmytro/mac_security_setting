#!/bin/bash
PATH="/bin:/usr/bin:/sbin:/usr/sbin"

##################################################################
# Configuration
#
USER_NAME="Coiney"
minChars=7
usingHistory=4
maxFailedLoginAttempts=6
maxDays=90
maxMinutesUntilChangePassword=$((maxDays * 24 * 60))

idleTime_minutes=15
idleTime=$((idleTime_minutes  * 60 ))

DONT_DELETE_PASSWORD_FILE=0 # Set this to 1 if you want to keep generated file on disk
#
# There is no user configurable parts below this line
##################################################################

set -e

#
# Return codes:
# 0 - all OK
# 1 - user already exists
# 2 - could not generate password
# 3 - admin user name is not configured

# Run this at the very begining just to make sure user has sudo
# permissions.
cache_sudo() {

    local ALERT=$(cat <<EOF

THIS SCRIPT WILL MODIFY SEVERAL SECURITY RELATED SETTINGS ON THIS
COMPUTER:

EOF
)

    local MESSAGE=$(cat <<EOF
* Create administrator user ${USER_NAME};
* Update your password policies:
  - password expiration time set to ${maxDays} days;
  - account lock after ${maxFailedLoginAttempts} failed login attempts;
  - min password length ${minChars} characters;
* Configure screen saver start time (${idleTime_minutes} minutes);
* Require password to unlock the screen saver screen.

After scripts completed do not forget to print out administrator password file (it will open in TextEdit for you by the script).

Since your password policies will be changed by the script, during the execution you will be asked for a password change.

>>>

This script uses sudo to create user account and to modify system setting. Please provide your sudo password at the prompt below.

EOF
          )

    echo -e "${ALERT} \n\n ${MESSAGE}"
    osascript <<EOF
set currentApp to (path to frontmost application as text)

tell application "System Events" to display alert "${ALERT}" message "${MESSAGE}" as critical  buttons "OK" default button 1
tell application currentApp to activate

EOF

    sudo -k
    sudo -l > /dev/null 2>&1
}

random_password() {
    ruby -r securerandom -e "puts SecureRandom.base64(15)" | tr -d "[:punct:]" 2> /dev/null
}

guard(){
    local TARGETUSER=${1}
    test -z ${TARGETUSER} && { echo "Admin user name is not set."; exit 3; }

    dscl . -read /Users/${TARGETUSER} > /dev/null 2>&1 && \
        { echo "User ${TARGETUSER} already exists.";  exit 1; } || true
}

make_admin_user(){
echo "-- Creating admin user "
    local TARGETUSER=${1}
    local PASSWORD=${2}

    GID=$(dscl . list groups gid | awk '$1 ~ /^staff/ {print $2}')

    sudo dscl . -create /Users/${TARGETUSER}
    printf '.'
    sudo dscl . -create /Users/${TARGETUSER} UserShell /bin/bash
    printf '.'
    sudo dscl . -create /Users/${TARGETUSER} RealName ${TARGETUSER}
    printf '.'

    lastid=$(dscl . -list /Users UniqueID | awk 'BEGIN {max = 0} {if ($2>max) max=$2} END {print max}')
    newid=$((lastid+1))

    sudo dscl . -create /Users/${TARGETUSER} UniqueID         ${newid}
    printf '.'
    sudo dscl . -create /Users/${TARGETUSER} PrimaryGroupID   ${GID}
    printf '.' #5
    sudo dscl . -create /Users/${TARGETUSER} NFSHomeDirectory /Users/${TARGETUSER}
    printf '.'

    sudo cp -a /System/Library/User\ Template/English.lproj /Users/${TARGETUSER}
    printf '.'
    sudo chown -R ${TARGETUSER}\:staff /Users/${TARGETUSER}
    printf '.'
    sudo chmod 701 /Users/${TARGETUSER}
    printf '.'
    sudo dscl . -passwd /Users/${TARGETUSER} ${PASSWORD}
    printf '.'
    sudo dscl . append /Groups/admin GroupMembership ${TARGETUSER}
    printf '.'

    # Admin user should NOT expire
    sudo pwpolicy -setpolicy -u ${TARGETUSER} "maxMinutesUntilChangePassword=2147483647"
    printf '.'

    printf " OK\n"
}

# This sets global policy
set_pw_policy(){
    echo "-- Setting default password policies"

    sudo pwpolicy -setglobalpolicy \
         "minChars=${minChars} requiresNumeric=1 requiresAlpha=1 usingHistory=${usingHistory} maxFailedLoginAttempts=${maxFailedLoginAttempts} maxMinutesUntilChangePassword=${maxMinutesUntilChangePassword}"

}

# Configure Screen saver to 15 mins - PCI DSS requirement
screen_saver() {
    echo "-- Configuring screensaver"
    defaults -currentHost write com.apple.screensaver idleTime 900
}

# Require password immediately after sleep or screen saver begins
screen_lock() {
    echo "-- Configuring screen lock"
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
}

print_out_admins(){
    echo "-------check admins-------"
    dscl localhost -read /Local/Default/Groups/admin
}

computer_name() {
    scutil --get ComputerName
}

print_policy() {
    echo '----------------------------------------------------------'
    printf "Your effective password policies are:\n\n\n"
    pwpolicy get-effective-policy  -u $(whoami)
}
save_password() {
    local OUTPUT="${HOME}/admin_user_password.txt"

    rm -f ${OUTPUT}
    cat <<EOF > ${OUTPUT}
================================================================


This password was generated by security script for administrator
user '${USER_NAME}' on
computer "$(computer_name)" at $(date "+%Y %m %d %H:%M")

${USER_NAME}'s password: ${PASSWORD}

Current user: $(whoami)

Please keep this record safe.

================================================================
EOF

    cat <<EOF
  ======================================================================
  =
  =  User's ${USER_NAME} password saved to the file
  =
  = ${OUTPUT}
  =
  = Please print out and delete this file. Keep it in safe place.
  =
  ======================================================================

EOF


    osascript <<EOF
set currentApp to (path to frontmost application as text)

tell application "TextEdit"
activate
open "${OUTPUT}"
display  dialog "

User's ${USER_NAME} password saved to the file ${OUTPUT}. Before continuing please print out the file on the next print dialog.

Keep printout in the safe place.

" buttons "OK" default button 1 with icon caution

print "${OUTPUT}" print dialog "true"
end tell

tell application currentApp to activate

EOF

    test ${DONT_DELETE_PASSWORD_FILE} = 1 || rm -f ${OUTPUT}

 }

change_user_password(){
    echo "You password policies will be modified. To avoid password lock please change your password now."
    passwd
}
######################################################################
# START MAIN
#

guard ${USER_NAME}
cache_sudo

PASSWORD=$(random_password)
test -z "${PASSWORD}" && { echo "Something wrong. Empty password."; exit 2; }
save_password

make_admin_user ${USER_NAME} ${PASSWORD}

change_user_password
set_pw_policy
screen_saver
screen_lock

print_out_admins
print_policy

printf  "\n\n\n----success----\n\n\n"
exit 0
