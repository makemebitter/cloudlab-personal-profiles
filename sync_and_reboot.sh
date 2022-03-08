#!/bin/bash
set -e
source helper.sh
source /home/$PROJECT_USER/.bashrc
sync_barrier
set +e
restart_all_workers
set -e
sudo shutdown -r now