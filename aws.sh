sudo apt-get update
sudo apt-get install -y libsecret-1-dev
sudo mkdir /local
sudo chmod 777 /local
mkdir /local/theia
cd /local/theia
wget https://raw.githubusercontent.com/makemebitter/cloudlab-personal-profiles/master/latest.package.json -O package.json
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
source ~/.bashrc
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 12.14.1
curl -o- -L https://yarnpkg.com/install.sh | bash
source ~/.bashrc
yarn --cache-folder ./ycache && rm -rf ./ycache && \
 NODE_OPTIONS="--max_old_space_size=4096" yarn theia build ; \
yarn theia download:plugins
mkdir $HOME/.theia
wget https://raw.githubusercontent.com/makemebitter/cloudlab-personal-profiles/master/settings.json -O $HOME/.theia/settings.json
wget https://raw.githubusercontent.com/makemebitter/cloudlab-personal-profiles/master/.screenrc -O $HOME/.screenrc
mkdir -p /local/logs