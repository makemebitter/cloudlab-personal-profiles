set -e
source helper.sh

# python
sudo -H python3 -m pip install -r requirements_master.txt
# Jupyter extension configs
mkdir -p ~/.jupyter;
sudo -H python3 -m jupyter contrib nbextension install --system ;
sudo -H python3 -m jupyter nbextensions_configurator enable --system ;
sudo -H python3 -m jupyter nbextension enable code_prettify/code_prettify --system ;
sudo -H python3 -m jupyter nbextension enable execute_time/ExecuteTime --system ;
sudo -H python3 -m jupyter nbextension enable collapsible_headings/main --system ;
sudo -H python3 -m jupyter nbextension enable freeze/main --system ;
sudo -H python3 -m jupyter nbextension enable spellchecker/main --system ;
HASHED_PASSWORD=$(python3 -c "from notebook.auth import passwd; print(passwd('$JUPYTER_PASSWORD'))");
echo "c.NotebookApp.password = u'$HASHED_PASSWORD'" >~/.jupyter/jupyter_notebook_config.py;
echo "c.NotebookApp.open_browser = False" >>~/.jupyter/jupyter_notebook_config.py;

# Theia
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
source ~/.bashrc
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 12.14.1
mkdir /local/theia
wget https://raw.githubusercontent.com/theia-ide/theia-apps/a83be54ff44f087c87d8652f05ec73538ea055f7/theia-python-docker/latest.package.json -O /local/theia/package.json
cd /local/theia
yarn --cache-folder ./ycache && rm -rf ./ycache && \
 NODE_OPTIONS="--max_old_space_size=4096" yarn theia build ; \
yarn theia download:plugins

# DGL setup
cd /local
python3 -m venv --system-site-packages env_dgl
sudo env_dgl/bin/python3 -m ipykernel install --name=env_dgl

env_dgl/bin/python3 -m pip install torch==1.7.1 torchvision==0.8.2 torchaudio==0.7.2 ogb
# env_dgl/bin/python3 -m pip install dgl -f https://data.dgl.ai/wheels/repo.html
env_dgl/bin/python3 -m pip install dgl-cu110==0.7.1 -f https://data.dgl.ai/wheels/repo.html

git clone https://github.com/dmlc/dgl.git /local/dgl
cd /local/dgl
git reset --hard HEAD
git checkout a9c83bce15246c3e71e372e8128c7e345c136f36

# Git user and email
git config --global user.email "yuz870@eng.ucsd.edu"
git config --global user.name "Yuhao Zhang"


