#!/bin/bash
set -e
source helper.sh
source /home/$PROJECT_USER/.bashrc
sync_barrier
restart_all_workers