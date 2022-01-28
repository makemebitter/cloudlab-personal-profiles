#!/bin/bash
set -e
source helper.sh
source /home/$PROJECT_USER/.bashrc
sync_barrier
echo "Rebooting all workers"
restart_all_workers
echo "Rebooting master"
sudo shutdown -r now
