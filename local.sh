# daily commit
gdrive about
gdrive upload -r -p 1RNwy-22Ode6dSKB49zM2-dinO6OHIpy3 /mnt/nfs/logs

gdrive upload -r -p 1RNwy-22Ode6dSKB49zM2-dinO6OHIpy3 /mnt/nfs/datasets/amazon
gdrive download -r 1yz7Q98h4GC9UA_nU27oJYdn9rcIu-5jH

gdrive download -r 1PTJCZjFPnkFqQrQQ7I85f2fhNHJRpCUO

gdrive upload -r -p 1ApdPQ1_ayKaiOhlpui-0zbiwJ3my0JcZ /mnt/nfs/ssd/dgl_cached/amazon


pkill -f server_main.py; pkill -f pipe.py; pkill -f run_ali.py; pkill -f run_dgl.py

tar --use-compress-program="pigz --best --recursive | pv" -cvf logs_before_oct28.tar.gz ./logs

tar -xvzf logs_08_30.tar.gz
gzip -d -v metadata.json.gz


hdfs dfsadmin -report

hdfs balancer -Ddfs.balancer.moverThreads=200000 -Ddfs.balancer.dispatcherThreads=1000 -Ddfs.balance.bandwidthPerSec=100000000 -Ddfs.balancer.max-size-to-move=107374182400 -Ddfs.datanode.balance.max.concurrent.moves=500 -threshold 1



