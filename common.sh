set -e
source helper.sh
CUR_DIR=$(pwd)
# Make extra filesystem, caution, not generic on all machines
create_ssd_partition

# ssh setting
echo "Host *" | tee ~/.ssh/config
echo "    StrictHostKeyChecking no" | tee -a ~/.ssh/config

# Git user and email
git config --global user.email "yuz870@eng.ucsd.edu"
git config --global user.name "Yuhao Zhang"
git config --global core.editor "vim"

# python
sudo -H $SYS_PY -m pip install pip --upgrade
sudo -H $SYS_PY -m pip install -r requirements_master.txt
# Jupyter extension configs
mkdir -p ~/.jupyter;
sudo -H $SYS_PY -m jupyter contrib nbextension install --system ;
sudo -H $SYS_PY -m jupyter nbextensions_configurator enable --system ;
sudo -H $SYS_PY -m jupyter nbextension enable code_prettify/code_prettify --system ;
sudo -H $SYS_PY -m jupyter nbextension enable execute_time/ExecuteTime --system ;
sudo -H $SYS_PY -m jupyter nbextension enable collapsible_headings/main --system ;
sudo -H $SYS_PY -m jupyter nbextension enable freeze/main --system ;
sudo -H $SYS_PY -m jupyter nbextension enable spellchecker/main --system ;
# sudo -H $SYS_PY -m pip install spylon_kernel
# sudo -H $SYS_PY -m spylon_kernel install

# Jupyter notebook almond kernel
cd /local
curl -Lo coursier https://git.io/coursier-cli
chmod +x coursier
sudo ./coursier launch --fork almond:0.11.1 --scala 2.12 -- --install

HASHED_PASSWORD=$($SYS_PY -c "from notebook.auth import passwd; print(passwd('$JUPYTER_PASSWORD'))");
echo "c.NotebookApp.password = u'$HASHED_PASSWORD'" >~/.jupyter/jupyter_notebook_config.py;
echo "c.NotebookApp.open_browser = False" >>~/.jupyter/jupyter_notebook_config.py;

# Theia
# curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
# source ~/.bashrc
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# nvm install 12.14.1
# mkdir /local/theia

git clone https://github.com/makemebitter/theia-ide.git /local/theia
cd /local/theia
bash install.sh download $DGL_PY

# wget https://raw.githubusercontent.com/theia-ide/theia-apps/a83be54ff44f087c87d8652f05ec73538ea055f7/theia-python-docker/latest.package.json -O /local/theia/package.json
# wget https://raw.githubusercontent.com/theia-ide/theia-apps/master/theia-python-docker/latest.package.json -O /local/theia/package.json

cd $BOOTSTRAP_ROOT
cp latest.package.json /local/theia/package.json
cd /local/theia
yarn --cache-folder ./ycache && rm -rf ./ycache && \
 NODE_OPTIONS="--max_old_space_size=4096" yarn theia build ; \
yarn theia download:plugins

yarn autoclean --init && \
echo *.ts >> .yarnclean && \
echo *.ts.map >> .yarnclean && \
echo *.spec.* >> .yarnclean && \
yarn autoclean --force && \
yarn cache clean

npm run build-deb


mkdir $HOME/.theia
cd $BOOTSTRAP_ROOT
cp settings.json $HOME/.theia/ 
sudo mkdir /.metals
sudo chown $PROJECT_USER /.metals

# DGL setup
cd /local
$SYS_PY -m venv --system-site-packages env_dgl
$DGL_PY -m pip install --upgrade pip
sudo $DGL_PY -m ipykernel install --name=env_dgl

sudo $DGL_PY -m pip install torch==1.10.2 torchvision==0.11.3 torchaudio==0.10.2 --extra-index-url https://download.pytorch.org/whl/cu113
$DGL_PY -m pip install ogb
$DGL_PY -m pip install torch-scatter==2.1.0 -f https://data.pyg.org/whl/torch-1.10.2+cu113.html
$DGL_PY -m pip install torch-sparse==0.6.16 -f https://data.pyg.org/whl/torch-1.10.2+cu113.html
# $DGL_PY -m pip install torch-sparse -f https://data.pyg.org/whl/torch-1.10.2+cpu.html
$DGL_PY -m pip install torch-geometric==2.2.0
$DGL_PY -m pip install nvidia-pyindex
# $DGL_PY -m pip install nvidia-tensorflow[horovod]==1.15.5+nv21.5
# $DGL_PY -m pip install protobuf==3.20.*
# $DGL_PY -m pip install numpy==1.15.0

# cudatoolkit==11.3 



if ( [[ $GPU_ENABLED -eq 1 ]] ); then
    $DGL_PY -m pip install dgl-cu113==0.9.1.post1 dglgo -f https://data.dgl.ai/wheels/repo.html
else
    $DGL_PY -m pip install dgl==0.9.1.post1 dglgo -f https://data.dgl.ai/wheels/repo.html
fi


# tigergraph stuff

mkdir -p $TIGER_HOME/app
mkdir -p $TIGER_HOME/data
mkdir -p $TIGER_HOME/log
mkdir -p $TIGER_HOME/tmp





# Hadoop
cd /local
wget https://archive.apache.org/dist/hadoop/core/hadoop-2.7.2/hadoop-2.7.2.tar.gz
tar -xvf hadoop-2.7.2.tar.gz 
mv hadoop-2.7.2 $HADOOP_HOME
cp $ALL_HOSTS_DIR $HADOOP_HOME/etc/hadoop/slaves
echo "master" | tee $HADOOP_HOME/etc/hadoop/workers
# echo "export PATH=\"$PATH\":$HADOOP_HOME/bin:$HADOOP_HOME/sbin" | tee -a ~/.bashrc
source ~/.bashrc
echo "export JAVA_HOME=$JAVA_HOME" | tee -a $HADOOP_HOME/etc/hadoop/hadoop-env.sh
cp $BOOTSTRAP_ROOT/core-site.xml $HADOOP_HOME/etc/hadoop/
cp $BOOTSTRAP_ROOT/yarn-site.xml $HADOOP_HOME/etc/hadoop/
cp $BOOTSTRAP_ROOT/hdfs-site.xml $HADOOP_HOME/etc/hadoop/
cp $BOOTSTRAP_ROOT/mapred-site.xml $HADOOP_HOME/etc/hadoop/
source ~/.bashrc

# Spark
cd /local
wget https://archive.apache.org/dist/spark/spark-3.2.0/spark-3.2.0-bin-hadoop2.7.tgz
tar -xvf spark-3.2.0-bin-hadoop2.7.tgz
mv spark-3.2.0-bin-hadoop2.7 $SPARK_HOME
echo "export PATH=\"$PATH\":$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin" | tee -a ~/.bashrc
source ~/.bashrc
cp $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh;

cp $ALL_HOSTS_DIR $SPARK_HOME/conf/workers
echo "export PYSPARK_PYTHON=$DGL_PY" | tee -a $SPARK_HOME/conf/spark-env.sh
echo "export SPARK_MASTER_HOST=master" | tee -a $SPARK_HOME/conf/spark-env.sh
echo "export SPARK_LOCAL_DIRS=$SPARK_LOCAL_DIRS,/mnt/tmp" | tee -a $SPARK_HOME/conf/spark-env.sh
echo "export SPARK_LOCAL_IP=$WORKER_NAME" | tee -a $SPARK_HOME/conf/spark-env.sh
# blas thread
echo "export OPENBLAS_NUM_THREADS=1" | tee -a $SPARK_HOME/conf/spark-env.sh
echo "export MKL_NUM_THREADS=1" | tee -a $SPARK_HOME/conf/spark-env.sh
echo "export LD_LIBRARY_PATH=/usr/local/lib" | tee -a $SPARK_HOME/conf/spark-env.sh






# Giraph
cd /local
git clone https://github.com/apache/giraph.git $GIRAPH_HOME/
cd $GIRAPH_HOME
git checkout release-1.3
mvn -Phadoop_2 -Dhadoop.version=2.7.2 package -DskipTests

mkdir -p $HADOOP_HOME/share/hadoop/giraph

cp $GIRAPH_HOME/giraph-examples/target/giraph-examples-1.3.0-SNAPSHOT-for-hadoop-2.7.2-jar-with-dependencies.jar $HADOOP_HOME/share/hadoop/giraph/

cp $GIRAPH_HOME/giraph-core/target/giraph-1.3.0-SNAPSHOT-for-hadoop-2.7.2-jar-with-dependencies.jar $HADOOP_HOME/share/hadoop/giraph/



# jzmq
cd /local
git clone https://github.com/zeromq/jzmq.git
cd jzmq/jzmq-jni
./autogen.sh
./configure
sudo make install
cd ..
mvn install -Dgpg.skip=true -Dmaven.test.skip=true 

# export GUAVA_JAR=$GIRAPH_HOME/giraph-dist/target/giraph-1.3.0-SNAPSHOT-for-hadoop-2.7.2-bin/giraph-1.3.0-SNAPSHOT-for-hadoop-2.7.2/lib/guava-21.0.jar


# There are problems on guava, would break HDFS
# rm -rf $HADOOP_HOME/share/hadoop/hdfs/lib/guava-11.0.2.jar
# rm -rf $HADOOP_HOME/share/hadoop/tools/lib/guava-11.0.2.jar
# rm -rf $HADOOP_HOME/share/hadoop/httpfs/tomcat/webapps/webhdfs/WEB-INF/lib/guava-11.0.2.jar
# rm -rf $HADOOP_HOME/share/hadoop/yarn/lib/guava-11.0.2.jar
# rm -rf $HADOOP_HOME/share/hadoop/common/lib/guava-11.0.2.jar


# cp $GUAVA_JAR $HADOOP_HOME/share/hadoop/hdfs/lib/
# cp $GUAVA_JAR $HADOOP_HOME/share/hadoop/tools/lib/
# cp $GUAVA_JAR $HADOOP_HOME/share/hadoop/httpfs/tomcat/webapps/webhdfs/WEB-INF/lib/
# cp $GUAVA_JAR $HADOOP_HOME/share/hadoop/yarn/lib/
# cp $GUAVA_JAR $HADOOP_HOME/share/hadoop/common/lib/



# Sdk and scala
curl -s "https://get.sdkman.io" | bash
source "/home/projectadmin/.sdkman/bin/sdkman-init.sh"
sdk install scala 2.12.15
sdk install sbt


# change hostnames
sudo hostname $WORKER_NAME



# git clone https://github.com/dmlc/dgl.git /local/dgl
# cd /local/dgl
# git reset --hard HEAD
# git checkout a9c83bce15246c3e71e372e8128c7e345c136f36




