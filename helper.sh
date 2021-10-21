add_global_vars (){
    sudo cat constants.sh | sudo tee -a /etc/environment
    worker_name=$(cat /proc/sys/kernel/hostname | cut -d'.' -f1)
    echo "WORKER_NAME=$worker_name" | sudo tee -a /etc/environment
    worker_number=$(sed -n -e 's/^.*worker//p' <<<"$worker_name")
    echo "WORKER_NUMBER=$worker_number" | sudo tee -a /etc/environment
    echo "MNT_ROOT=$MNT_ROOT" | sudo tee -a /etc/environment
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
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get update
    sudo apt-get install -y $(cat pkglist)
}

save_space (){
    sudo mkdir ${MNT_ROOT}/home
    sudo rsync -avr /home/ ${MNT_ROOT}/home/
    sudo rm -rvf /home/*
    sudo mount -o bind ${MNT_ROOT}/home/ /home/

    sudo mkdir ${MNT_ROOT}/tmp
    sudo rsync -avr /tmp/ ${MNT_ROOT}/tmp/
    sudo rm -rvf /tmp/*
    sudo mount -o bind ${MNT_ROOT}/tmp/ /tmp/
    sudo chmod 1777 /tmp


    sudo mkdir ${MNT_ROOT}/var
    sudo rsync -avr /var/ ${MNT_ROOT}/var/
    sudo rm -rvf /var/*
    sudo mount -o bind ${MNT_ROOT}/var/ /var/

    # sudo mkdir ${MNT_ROOT}/var.lib
    # sudo rsync -avr /var/lib/ ${MNT_ROOT}/var.lib/
    # sudo rm -rvf /var/lib/*
    # sudo mount -o bind ${MNT_ROOT}/var.lib/ /var/lib/

    # don't use
    # sudo mkdir ${MNT_ROOT}/var.cache
    # sudo rsync -avr /var/cache/ ${MNT_ROOT}/var.cache/
    # sudo rm -rvf /var/cache/*
    # sudo mount -o bind ${MNT_ROOT}/var.cache/ /var/cache/

    sudo dpkg --configure -a
}

setup_project_user (){
    sudo su -c "useradd $PROJECT_USER -s /bin/bash -m -g root"
    sudo usermod -aG sudo $PROJECT_USER
    echo "$PROJECT_USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$PROJECT_USER
    sudo chown $PROJECT_USER -R  /local /$MNT_ROOT
    echo "${PRIVATE_KEY}" > $SSH_KEY_FILE
    sudo chown $PROJECT_USER $SSH_KEY_FILE
    sudo -H -u $PROJECT_USER mkdir -m 700 /home/$PROJECT_USER/.ssh
    sudo -H -u $PROJECT_USER touch /home/$PROJECT_USER/.ssh/authorized_keys
    sudo -H -u $PROJECT_USER cp $SSH_KEY_FILE /home/$PROJECT_USER/.ssh/prj_key
    sudo chmod 600 /home/$PROJECT_USER/.ssh/authorized_keys
    sudo chmod 600 /home/$PROJECT_USER/.ssh/prj_key
    ssh-keygen -y -f $SSH_KEY_FILE | sudo tee -a /home/$PROJECT_USER/.ssh/authorized_keys
    cp .screenrc /home/$PROJECT_USER
    cat bashrc | sudo tee -a /home/$PROJECT_USER/.bashrc
}

generally_good_stuff (){
    echo "RemoveIPC=no" | sudo tee -a /etc/systemd/logind.conf
    sudo service systemd-logind restart
    echo -e "$PROJECT_USER hard core unlimited\n$PROJECT_USER hard nproc 131072\n$PROJECT_USER hard nofile 65536" | sudo tee -a /etc/security/limits.d/$PROJECT_USER-limits.conf
    sudo -H -u $PROJECT_USER bash -c 'ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts'

}

install_cuda (){
    # Add NVIDIA package repositories
    cd /local
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin
    sudo mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
    sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
    sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /"
    sudo apt-get update

    wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb

    sudo apt-get install -y ./nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb
    sudo apt-get update

    wget https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/libnvinfer7_7.1.3-1+cuda11.0_amd64.deb
    sudo apt-get install -y ./libnvinfer7_7.1.3-1+cuda11.0_amd64.deb
    sudo apt-get update

    # Install development and runtime libraries (~4GB)
    sudo apt-get install -y --no-install-recommends --allow-downgrades \
        cuda-11-0 \
        libcudnn8=8.0.4.30-1+cuda11.0  \
        libcudnn8-dev=8.0.4.30-1+cuda11.0

}

install_python_dep (){
    
}

