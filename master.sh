set -e
source helper.sh
mkdir $NFS_DIR
echo "$NFS_DIR  *(rw,sync,crossmnt,no_root_squash,crossmnt)" | sudo tee -a  /etc/exports
sudo /etc/init.d/nfs-kernel-server restart
export GIT_SSH_COMMAND="ssh -i /home/$PROJECT_USER/.ssh/prj_key"

git clone git@github.com:makemebitter/gsys.git $NFS_DIR/gsys

git clone git@github.com:makemebitter/dgl.git $NFS_DIR/dgl
# cd /local/dgl
# git reset --hard HEAD
# git checkout a9c83bce15246c3e71e372e8128c7e345c136f36



# # run 
# screen -dmS bg bash -c "nohup jupyter notebook --no-browser --ip 0.0.0.0 --notebook-dir=/ > /local/logs/jupyter.log 2>&1 \
# & nohup yarn theia start / --hostname=127.0.0.1 > /local/logs/theia.log 2>&1 &"


