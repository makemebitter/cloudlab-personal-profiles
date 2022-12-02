# daily commit
gdrive about
gdrive upload -r -p 1RNwy-22Ode6dSKB49zM2-dinO6OHIpy3 /mnt/nfs/logs

tar --use-compress-program="pigz --best --recursive | pv" -cvf logs_before_oct28.tar.gz ./logs

tar -xvzf logs_08_30.tar.gz


hdfs dfsadmin -report

hdfs balancer -Ddfs.balancer.moverThreads=200000 -Ddfs.balancer.dispatcherThreads=1000 -Ddfs.balance.bandwidthPerSec=100000000 -Ddfs.balancer.max-size-to-move=10737418240 -Ddfs.datanode.balance.max.concurrent.moves=500 -threshold 1