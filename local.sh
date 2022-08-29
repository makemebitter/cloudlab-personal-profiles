# daily commit
gdrive about
gdrive upload -r -p 1RNwy-22Ode6dSKB49zM2-dinO6OHIpy3 /mnt/nfs/logs

tar --use-compress-program="pigz --best --recursive | pv" -cvf logs.tar.gz ./logs
