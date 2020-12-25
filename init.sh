#!/usr/bin/env sh
set -e

add_authorized_keys() {
    AUTHORIZED_KEYS_BASENAME=$1
    if [ -z $AUTHORIZED_KEYS_BASENAME ]; then
        printf "%s\n" "uh oh there is no authorized_keys path found, using a default!"
        AUTHORIZED_KEYS_BASENAME="/home/admin/.ssh"
    fi

    target_keytype="ssh-ed25519"
    curl -s https://github.com/jafow.keys -o keys.txt
    while read keytype piece; do
        if case $target_keytype in $keytype* ) true;; *) false;; esac; then
            echo "$keytype $piece" > $AUTHORIZED_KEYS_BASENAME/authorized_keys
        else
            printf "Skipping this unrecognized public key. What is this, a key party!??\n%s %s\n" $keytype $piece
        fi
    done < keys.txt
}

tidy_up() {
    rm keys.txt
    rm authorized_keys || printf "nope not here\n"
}

main() {
    # create a user
    sudo useradd -m admin -G atomicpi

    cp admin.sudoers.tpl admin
    chmod a-rwx,u+rw,go+r admin
    sudo chown root admin 
    sudo mv admin /etc/sudoers.d/admin
    sudo usermod -a -G admin admin

    # mkdir
    sudo mkdir /home/admin/.ssh
    sudo chmod 700 /home/admin/.ssh

    add_authorized_keys "$(pwd)"
    sudo cp ./authorized_keys /home/admin/.ssh
    sudo systemctl restart sshd.service
    printf "we are done and tidying up\n"
    tidy_up
}

printf "%s\n" "let us begin."
main
