set -e
mkdir $NFS_DIR
echo "$NFS_DIR  *(rw,sync,crossmnt,no_root_squash,crossmnt)" | sudo tee -a  /etc/exports
sudo /etc/init.d/nfs-kernel-server restart
# python
sudo python3 -m pip install -r requirements_master.txt
# Jupyter extension configs
mkdir -p ~/.jupyter;
sudo python3 -m jupyter contrib nbextension install --system ;
sudo python3 -m jupyter nbextensions_configurator enable --system ;
sudo python3 -m jupyter nbextension enable code_prettify/code_prettify --system ;
sudo python3 -m jupyter nbextension enable execute_time/ExecuteTime --system ;
sudo python3 -m jupyter nbextension enable collapsible_headings/main --system ;
sudo python3 -m jupyter nbextension enable freeze/main --system ;
sudo python3 -m jupyter nbextension enable spellchecker/main --system ;
HASHED_PASSWORD=$(python3 -c "from notebook.auth import passwd; print(passwd('$JUPYTER_PASSWORD'))");
echo "c.NotebookApp.password = u'$HASHED_PASSWORD'" >~/.jupyter/jupyter_notebook_config.py;
echo "c.NotebookApp.open_browser = False" >>~/.jupyter/jupyter_notebook_config.py;


# Theia
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
source ~/.bashrc
nvm install 12.14.1
mkdir /local/theia
wget https://raw.githubusercontent.com/theia-ide/theia-apps/a83be54ff44f087c87d8652f05ec73538ea055f7/theia-python-docker/latest.package.json -O /local/theia/package.json
cd /local/theia
yarn --cache-folder ./ycache && rm -rf ./ycache && \
 NODE_OPTIONS="--max_old_space_size=4096" yarn theia build ; \
yarn theia download:plugins


# # run 
# screen -dmS bg bash -c "nohup jupyter notebook --no-browser --ip 0.0.0.0 --notebook-dir=/ > /local/logs/jupyter.log 2>&1 \
# & nohup yarn theia start / --hostname=127.0.0.1 > /local/logs/theia.log 2>&1 &"



