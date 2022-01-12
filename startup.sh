sudo mount -a
sudo chown -R $(whoami) /local/logs
nohup jupyter notebook --no-browser --ip 127.0.0.1 --notebook-dir=/ > /local/logs/jupyter.log 2>&1 & \
nohup yarn --cwd /local/theia theia start --hostname=127.0.0.1 > /local/logs/theia.log 2>&1 &
cd logs/bin
. run_loggers.sh
if [[ "$WORKER_NAME" = "master" ]]; then
	$HADOOP_HOME/sbin/start-all.sh
	$SPARK_HOME/sbin/start-all.sh
fi

# backup logs
# gdrive upload -r -p 1JKqLPK6K_gqxRBp4LAHBx-uW7hmxbVpi /mnt/nfs/logs