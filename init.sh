#!/usr/bin/env sh
set -e

PI_USER=admin

add_authorized_keys() {
    AUTHORIZED_KEYS_BASENAME=$1
    if [ -z $AUTHORIZED_KEYS_BASENAME ]; then
        printf "%s\n" "uh oh there is no authorized_keys path found, using a default!"
        AUTHORIZED_KEYS_BASENAME="/home/$PI_USER/.ssh"
    fi
    curl -s https://github.com/jafow.keys -o $AUTHORIZED_KEYS_BASENAME/authorized_keys
}

tidy_up() {
    test -e keys.txt || touch keys.txt
    rm keys.txt
    test -e authorized_keys  || touch authorized_keys
    rm authorized_keys
}

main() {
    # create a user
    sudo useradd -m -g atomicpi $PI_USER

    # add them to sudoers, yolo!
    cat admin.sudoers.tpl | sed "s/%PI_USER%/$PI_USER/g" > $PI_USER
    chmod a-rwx,u+rw,go+r $PI_USER
    sudo chown root:root $PI_USER
    sudo mv $PI_USER /etc/sudoers.d/$PI_USER

    # setup keys
    sudo mkdir /home/$PI_USER/.ssh
    sudo chown -R $PI_USER /home/$PI_USER/.ssh
    sudo chmod 700 /home/$PI_USER/.ssh

    add_authorized_keys "$(pwd)"
    sudo cp authorized_keys /home/$PI_USER/.ssh
    sudo chmod a-rwx,u+rw /home/$PI_USER/.ssh/authorized_keys
    sudo chown $PI_USER /home/$PI_USER/.ssh/authorized_keys

    sudo chown root:root sshd_config
    sudo mv sshd_config /etc/ssh/sshd_config

    sudo systemctl restart sshd
    printf "we are done and tidying up\n"
    tidy_up
}

printf "%s\n" "let us begin."
main
