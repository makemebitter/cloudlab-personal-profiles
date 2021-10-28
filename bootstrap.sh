#!/bin/bash
set -e

duty=${1}
JUPYTER_PASSWORD=${2:-"root"}
PRIVATE_KEY=${3}
GPU_WORKERS=${4}
GPADMIN_PASSWORD=${5}
MNT_ROOT=${6}
GPU_MASTER=${7}
echo "PRIVATE KEY"
echo "${PRIVATE_KEY}"

source helper.sh
GPU_ENABLED=0
if ( [[ "$duty" = "s" ]] && [[ $GPU_WORKERS -eq 1 ]] ) || ( [[ "$duty" = "m" ]] && [[ $GPU_MASTER -eq 1 ]] ); then
    GPU_ENABLED=1
fi
add_global_vars
save_space
install_apt

if ( [[ $GPU_ENABLED -eq 1 ]] ); then
    install_cuda
fi
setup_project_user
setup_loggers
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

echo "Bootstraping complete, rebooting..."
sudo shutdown -r now









