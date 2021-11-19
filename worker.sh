# n=0
# until [ $n -ge 1000 ]
# do
#    sudo mount master:$NFS_DIR $NFS_DIR && break  # substitute your command here
#    n=$[$n+1]
#    sleep 15
# done


echo "master:$NFS_DIR       $NFS_DIR      nfs auto 0 0" | sudo tee -a /etc/fstab
sudo mount -a