nohup jupyter notebook --no-browser --ip 0.0.0.0 --notebook-dir=/ > /local/logs/jupyter.log 2>&1 & \
nohup yarn --cwd /local/theia theia  start --hostname=127.0.0.1 > /local/logs/theia.log 2>&1 &