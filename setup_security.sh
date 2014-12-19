#!/bin/sh

set -e

GUARD(){
    local TARGETUSER=$1

    if dscl . -list /Users | grep $TARGETUSER > /dev/null
    then
        echo "$TARGETUSER already exists."
        exit 0
    fi
}

MAKE_ADMIN_USER(){
    local TARGETUSER=$1
    local PASSWORD=$2

    GID=`dscl . list groups gid|grep \^staff | tail -1 | awk '{print $2}'`

    sudo dscl . -create /Users/$TARGETUSER
    sudo dscl . -create /Users/$TARGETUSER UserShell /bin/bash
    sudo dscl . -create /Users/$TARGETUSER RealName $TARGETUSER

    lastid=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -ug | tail -1)
    newid=$((lastid+1))

    sudo dscl . -create /Users/$TARGETUSER UniqueID         $newid
    sudo dscl . -create /Users/$TARGETUSER PrimaryGroupID   $GID
    sudo dscl . -create /Users/$TARGETUSER NFSHomeDirectory /Users/$TARGETUSER

    sudo cp -a /System/Library/User\ Template/English.lproj /Users/$TARGETUSER
    sudo chown -R $TARGETUSER\:staff /Users/$TARGETUSER
    sudo chmod 701 /Users/$TARGETUSER
    sudo dscl . -passwd /Users/$TARGETUSER $PASSWORD
    sudo dscl . append /Groups/admin GroupMembership $TARGETUSER
}

SET_PW_POLICY(){
    local MYUSERNAME=`whoami`
    local ADMIN_USER=$1
    local PASSWORD=$2

    expect -c "
    set timeout 5
    spawn pwpolicy -a $ADMIN_USER -u $MYUSERNAME -setpolicy “minChars=7 usingHistory=4 maxFailedLoginAttempts=6 requiresNumeric=1 maxMinutesUntilChangePassword=129600”
    expect \"Password for authenticator\"
    send \"$PASSWORD\n\"
    interact
    "
}

CHECK(){
    echo "-------check admins-------"
    dscl localhost -read /Local/Default/Groups/admin
}

USER_NAME="Coiney"
PASSWORD="[put_admin_pass]"

GUARD $USER_NAME
MAKE_ADMIN_USER $USER_NAME $PASSWORD
SET_PW_POLICY $USER_NAME $PASSWORD
CHECK


echo "----success----"
exit 0
