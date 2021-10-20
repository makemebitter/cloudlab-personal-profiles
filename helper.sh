add_global_vars (){
    sudo cat constants.sh | sudo tee -a /etc/environment
    source /etc/environment
}

wait_workers (){
    # --------------------- Check if every host online -------------------------
    awk 'NR>1 {print $NF}' /etc/hosts | grep -v 'master' > $HOSTS_DIR
    if [ "$duty" = "m" ]; then
        readarray -t hosts < $HOSTS_DIR
        while true; do
            echo "Checking if other hosts online"
            all_done=true
            for host in "${hosts[@]}"; do
                if nc -w 2 -z $host 22 2>/dev/null; then
                    echo "$host ✓"
                else
                    echo "$host ✗"
                    all_done=false
                fi
            done
            

            if [ "$all_done" = true ] ; then
                break
            else
                echo "WAITING"
                sleep 5s
            fi
        done
    fi
    # --------------------------------------------------------------------------
}

install_apt (){
    sudo apt-get update
    sudo apt-get install -y $(cat pkglist)
}

save_space (){
    sudo mkdir ${MNT_ROOT}/home
    sudo rsync -av /home/ ${MNT_ROOT}/home/
    sudo rm -rvf /home/*
    sudo mount -o bind ${MNT_ROOT}/home/ /home/

    sudo mkdir ${MNT_ROOT}/tmp
    sudo rsync -av /tmp/ ${MNT_ROOT}/tmp/
    sudo rm -rvf /tmp/*
    sudo mount -o bind ${MNT_ROOT}/tmp/ /tmp/
    sudo chmod 1777 /tmp


    sudo mkdir ${MNT_ROOT}/var.lib
    sudo rsync -av /var/lib/ ${MNT_ROOT}/var.lib/
    sudo rm -rvf /var/lib/*
    sudo mount -o bind ${MNT_ROOT}/var.lib/ /var/lib/

    sudo mkdir ${MNT_ROOT}/var.cache
    sudo rsync -av /var/cache/ ${MNT_ROOT}/var.cache/
    sudo rm -rvf /var/cache/*
    sudo mount -o bind ${MNT_ROOT}/var.cache/ /var/cache/
    sudo dpkg --configure -a
}

setup_project_user (){
    sudo su -c "useradd $PROJECT_USER -s /bin/bash -m -g root"
    sudo usermod -aG sudo $PROJECT_USER
    echo "$PROJECT_USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$PROJECT_USER
    sudo chown $PROJECT_USER -R  /local /$MNT_ROOT
    echo "${PRIVATE_KEY}" > $SSH_KEY_FILE
    sudo chown $PROJECT_USER $SSH_KEY_FILE
    sudo chmod 600 $SSH_KEY_FILE
    ssh-keygen -y -f $SSH_KEY_FILE | sudo tee -a /home/$PROJECT_USER/.ssh/authorized_keys

}

