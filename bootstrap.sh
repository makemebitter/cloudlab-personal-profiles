#!/bin/bash
set -e

export duty=${1}
export JUPYTER_PASSWORD=${2:-"root"}
export PRIVATE_KEY=${3}
export GPU_WORKERS=${4}
export GPADMIN_PASSWORD=${5}
export MNT_ROOT=${6}
export GPU_MASTER=${7}
echo "PRIVATE KEY"
echo "${PRIVATE_KEY}"

source helper.sh
if ( [[ "$duty" = "s" ]] && [[ $GPU_WORKERS = "True" ]] ) || ( [[ "$duty" = "m" ]] && [[ $GPU_MASTER = "True" ]] ); then
    export GPU_ENABLED=1
else
    export GPU_ENABLED=0
fi
add_global_vars
save_space
install_apt
add_firewall

if ( [[ $GPU_ENABLED -eq 1 ]] ); then
    install_cuda
fi
setup_project_user
generally_good_stuff
wait_workers




# -----------------------------------------------------------------------------
sudo -H -u $PROJECT_USER bash common.sh
# -----------------------------------------------------------------------------
if [[ "$duty" = "m" ]]; then
  # Master bootstrap
  sudo -H -u $PROJECT_USER bash master.sh
elif [[ "$duty" = "s" ]]; then
  # Slave bootstrap
  sudo -H -u $PROJECT_USER bash worker.sh
fi
# -----------------------------------------------------------------------------
touch $TAG_PATH
echo "Bootstraping complete, rebooting ..."

if [[ "$duty" = "m" ]]; then
# Master control reboot
    sudo -H -u $PROJECT_USER bash sync_and_reboot.sh
fi










