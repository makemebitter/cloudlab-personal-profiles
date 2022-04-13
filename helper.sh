add_one_global_var (){
    echo "$1=$2" | sudo tee -a /etc/environment
    source /etc/environment
}

add_global_vars (){
    sudo cat constants.sh | sudo tee -a /etc/environment
    worker_name=$(cat /proc/sys/kernel/hostname | cut -d'.' -f1)
    add_one_global_var "WORKER_NAME" $worker_name
    # echo "WORKER_NAME=$worker_name" | sudo tee -a /etc/environment

    worker_number=$(sed -n -e 's/^.*worker//p' <<<"$worker_name")
    # echo "WORKER_NUMBER=$worker_number" | sudo tee -a /etc/environment
    # echo "MNT_ROOT=$MNT_ROOT" | sudo tee -a /etc/environment
    # echo "GPU_ENABLED=$GPU_ENABLED" | sudo tee -a /etc/environment
    # echo "DUTY=$duty" | sudo tee -a /etc/environment
    # echo "GPU_WORKERS=$GPU_WORKERS" | sudo tee -a /etc/environment
    # echo "GPU_MASTER=$GPU_MASTER" | sudo tee -a /etc/environment
    add_one_global_var "WORKER_NUMBER" $worker_number
    add_one_global_var "MNT_ROOT" $MNT_ROOT
    add_one_global_var "GPU_ENABLED" $GPU_ENABLED
    add_one_global_var "DUTY" $duty
    add_one_global_var "GPU_WORKERS" $GPU_WORKERS
    add_one_global_var "GPU_MASTER" $GPU_MASTER
    source /etc/environment
}

create_ssd_partition(){
    mkdir -p $SSD_DIR
    sudo /usr/local/etc/emulab/mkextrafs.pl $SSD_DIR
    sudo chown -R $PROJECT_USER $SSD_DIR
}

wait_workers (){
    # --------------------- Check if every host online -------------------------
    awk 'NR>1 {print $NF}' /etc/hosts | grep -v 'master' > $HOSTS_DIR
    awk 'NR>1 {print $1}' /etc/hosts > $ALL_HOSTS_DIR
    awk 'NR>1 {print $1 " " $NF}' /etc/hosts > $ALL_HOSTS_COMPLETE_DIR
    sort -o $ALL_HOSTS_DIR $ALL_HOSTS_DIR
    sort -o $ALL_HOSTS_COMPLETE_DIR $ALL_HOSTS_COMPLETE_DIR
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

restart_all_workers (){
    set +e
    ssh_arg="-i $PROJECT_SSH_KEY"
    PARALLEL_SSH="parallel-ssh -i -h $HOSTS_DIR -t 0 -O StrictHostKeyChecking=no -x \"${ssh_arg}\""
    eval "$PARALLEL_SSH 'sudo shutdown -r now'"
}

sync_barrier (){
    readarray -t hosts < $ALL_HOSTS_DIR
    while true; do
        echo "Checking if all hosts finished"
        all_done=true
        for host in "${hosts[@]}"; do
            if ssh -i $PROJECT_SSH_KEY -o StrictHostKeychecking=no $host stat $TAG_PATH \> /dev/null 2\>\&1; then
                echo "$host finished"
            else
                echo "$host hasn't finished yet"
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
}

install_apt (){
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get update
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa

    sudo apt-get install -y $(cat pkglist)

    # setup sysstat
    sudo sed -i 's/"false"/"true"/g' /etc/default/sysstat
    sudo service sysstat restart

    sudo apt-get install -y openjdk-8-jdk
    sudo update-java-alternatives --set /usr/lib/jvm/java-1.8.0-openjdk-amd64
    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
    add_one_global_var JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

    

    # # blas
    # sudo update-alternatives --config libblas.so.3
    install_mkl


}

install_mkl (){
    # intel mkl
    # download the key to system keyring
    wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
    | gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null

    # add signed entry to apt sources and configure the APT client to use Intel repository:
    echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list
    sudo apt-get update
    sudo apt-get install -y intel-basekit
}

add_firewall (){
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp
    sudo ufw allow from 10.10.1.0/24
    sudo ufw enable
    sudo systemctl enable ufw
    echo "AllowUsers      yhzhang $PROJECT_USER" | sudo tee -a /etc/ssh/sshd_config
    sudo systemctl restart sshd 
}

migrate_a2b (){
    dir_a="$1"
    dir_b="$2"
    sudo mkdir -p $dir_b
    sudo rsync -avr $dir_a/ $dir_b/
    sudo rm -rvf $dir_a/*
    sudo mount -o bind $dir_b/ $dir_a/
    echo "$dir_b/    $dir_a/    none    bind    0    0" | sudo tee -a /etc/fstab
}

space_saver (){
    ori_dir=$1
    new_dir=$2
    dir_b="${MNT_ROOT}/$new_dir"
    dir_a="$ori_dir"
    migrate_a2b $dir_a $dir_b

}


save_space (){
    # sudo mkdir ${MNT_ROOT}/home
    # sudo rsync -avr /home/ ${MNT_ROOT}/home/
    # sudo rm -rvf /home/*
    # sudo mount -o bind ${MNT_ROOT}/home/ /home/

    space_saver "/home" "home"

    # sudo mkdir ${MNT_ROOT}/tmp
    # sudo rsync -avr /tmp/ ${MNT_ROOT}/tmp/
    # sudo rm -rvf /tmp/*
    # sudo mount -o bind ${MNT_ROOT}/tmp/ /tmp/

    space_saver "/tmp" "tmp"
    sudo chmod 1777 /tmp


    # sudo mkdir ${MNT_ROOT}/var
    # sudo rsync -avr /var/ ${MNT_ROOT}/var/
    # sudo rm -rvf /var/*
    # sudo mount -o bind ${MNT_ROOT}/var/ /var/

    space_saver "/var" "var"

    space_saver "/opt" "var"

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
    # add prj admin user
    sudo su -c "useradd $PROJECT_USER -s /bin/bash -m -g root"
    # add group
    sudo groupadd $PROJECT_USER
    # add user to group
    sudo usermod -a -G $PROJECT_USER $PROJECT_USER
    sudo usermod -aG sudo $PROJECT_USER
    echo "$PROJECT_USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$PROJECT_USER
    sudo chown $PROJECT_USER -R  /local /$MNT_ROOT
    echo "${PRIVATE_KEY}" > $SSH_KEY_FILE
    sudo chown $PROJECT_USER $SSH_KEY_FILE
    PROJECT_SSH_DIR="/home/$PROJECT_USER/.ssh"
    add_one_global_var "PROJECT_SSH_DIR" $PROJECT_SSH_DIR

    sudo -H -u $PROJECT_USER mkdir -m 700 $PROJECT_SSH_DIR

    PROJECT_AUTHORIZED_KEYS="$PROJECT_SSH_DIR/authorized_keys"
    add_one_global_var "PROJECT_AUTHORIZED_KEYS" $PROJECT_AUTHORIZED_KEYS

    sudo -H -u $PROJECT_USER touch $PROJECT_AUTHORIZED_KEYS

    PROJECT_SSH_KEY="$PROJECT_SSH_DIR/prj_key"
    add_one_global_var "PROJECT_SSH_KEY" $PROJECT_SSH_KEY

    sudo -H -u $PROJECT_USER cp $SSH_KEY_FILE $PROJECT_SSH_KEY

    sudo chmod 600 $PROJECT_AUTHORIZED_KEYS
    sudo chmod 600 $PROJECT_SSH_KEY
    ssh-keygen -y -f $SSH_KEY_FILE | sudo tee -a $PROJECT_AUTHORIZED_KEYS

    PROJECT_SSH_KEY_PUB="$PROJECT_SSH_DIR/prj_key.pub"
    add_one_global_var "PROJECT_SSH_KEY_PUB" $PROJECT_SSH_KEY_PUB

    ssh-keygen -y -f $SSH_KEY_FILE > $PROJECT_SSH_KEY_PUB
    cp $MNT_ROOT/local/repository/.screenrc /home/$PROJECT_USER
    cat bashrc | sudo tee -a /home/$PROJECT_USER/.bashrc
    sudo chown -R $PROJECT_USER /local

     
}

setup_loggers (){
    # (crontab -l ; echo "/local/gsys/logs/bin/run_loggers.sh $MNT_ROOT $GPU_ENABLED") | crontab
    echo -e "sudo -H -u $PROJECT_USER bash /local/repository/logs/bin/run_loggers.sh $NFS_DIR $GPU_ENABLED" | sudo tee -a /etc/rc.local
}

generally_good_stuff (){
    echo "RemoveIPC=no" | sudo tee -a /etc/systemd/logind.conf
    sudo service systemd-logind restart
    echo -e "$PROJECT_USER hard core unlimited\n$PROJECT_USER hard nproc 131072\n$PROJECT_USER hard nofile 65536" | sudo tee -a /etc/security/limits.d/$PROJECT_USER-limits.conf
    sudo -H -u $PROJECT_USER bash -c 'ssh-keygen -F github.com || ssh-keyscan github.com >>~/.ssh/known_hosts'

}

install_cuda (){
    # Add NVIDIA package repositories
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

    # Save space
    space_saver "/usr/local/cuda-11.0" "usr.local.cuda"

}

install_python_dep (){
    echo No
}

