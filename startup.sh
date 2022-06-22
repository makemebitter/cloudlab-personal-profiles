sudo mount -a
sudo chown -R $(whoami) /local/logs
nohup jupyter notebook --no-browser --ip 127.0.0.1 --notebook-dir=/ > /local/logs/jupyter.log 2>&1 & \
nohup yarn --cwd /local/theia theia start --hostname=127.0.0.1 > /local/logs/theia.log 2>&1 &
# install the system
cd $NFS_DIR/gsys
$DGL_PY -m pip install -e .

cd $NFS_DIR/aligraph/dist
$DGL_PY -m pip install graph_learn-1.0.1-cp38-cp38-linux_x86_64.whl

cd $NFS_DIR/gsys/logs/bin
. run_loggers.sh
if [[ "$WORKER_NAME" = "master" ]]; then
	$HADOOP_HOME/sbin/start-all.sh
	$SPARK_HOME/sbin/start-all.sh
fi

# backup logs
# gdrive upload -r -p 1JKqLPK6K_gqxRBp4LAHBx-uW7hmxbVpi /mnt/nfs/logs