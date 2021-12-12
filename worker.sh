

mkdir $NFS_DIR
echo "master:$NFS_DIR       $NFS_DIR      nfs auto 0 0" | sudo tee -a /etc/fstab


# waits master to finish
