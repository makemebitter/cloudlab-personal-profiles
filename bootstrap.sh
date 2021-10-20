#!/bin/bash
set -e

duty=${1}
JUPYTER_PASSWORD=${2:-"root"}
PRIVATE_KEY=${3}
GPU_WORKERS=${4}
GPADMIN_PASSWORD=${5}
MNT_ROOT=${6}
echo "PRIVATE KEY"
echo "${PRIVATE_KEY}"

source helper.sh
add_global_vars
install_apt
save_space
setup_project_user

wait_workers







# -----------------------------------------------------------------------------
# if [ "$duty" = "m" ]; then
#   # Master bootstrap
# fi
# elif [ "$duty" = "s" ]; then
#   # Slave bootstrap
# fi
# -----------------------------------------------------------------------------

echo "Bootstraping complete"









