set -e
source helper.sh
mkdir $NFS_DIR
echo "$NFS_DIR  *(rw,sync,crossmnt,no_root_squash,crossmnt)" | sudo tee -a  /etc/exports
sudo /etc/init.d/nfs-kernel-server restart






# # run 
# screen -dmS bg bash -c "nohup jupyter notebook --no-browser --ip 0.0.0.0 --notebook-dir=/ > /local/logs/jupyter.log 2>&1 \
# & nohup yarn theia start / --hostname=127.0.0.1 > /local/logs/theia.log 2>&1 &"


