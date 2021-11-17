set -e
source helper.sh
CUR_DIR=$(pwd)
# Make extra filesystem, caution, not generic on all machines
create_ssd_partition

# Git user and email
git config --global user.email "yuz870@eng.ucsd.edu"
git config --global user.name "Yuhao Zhang"

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
# wget https://raw.githubusercontent.com/theia-ide/theia-apps/a83be54ff44f087c87d8652f05ec73538ea055f7/theia-python-docker/latest.package.json -O /local/theia/package.json
wget https://raw.githubusercontent.com/theia-ide/theia-apps/master/theia-python-docker/latest.package.json -O /local/theia/package.json

cp latest.package.json ca
cd /local/theia
yarn --cache-folder ./ycache && rm -rf ./ycache && \
 NODE_OPTIONS="--max_old_space_size=4096" yarn theia build ; \
yarn theia download:plugins
mkdir $HOME/.theia
cd $CUR_DIR
cp settings.json $HOME/.theia/ 

# DGL setup
cd /local
python3 -m venv --system-site-packages env_dgl
sudo env_dgl/bin/python3 -m ipykernel install --name=env_dgl

env_dgl/bin/python3 -m pip install torch==1.7.1 torchvision==0.8.2 torchaudio==0.7.2 ogb

if ( [[ $GPU_ENABLED -eq 1 ]] ); then
    env_dgl/bin/python3 -m pip install dgl-cu110==0.7.1 -f https://data.dgl.ai/wheels/repo.html
else
    env_dgl/bin/python3 -m pip install dgl -f https://data.dgl.ai/wheels/repo.html
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
echo "export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin" | tee -a ~/.bashrc
source ~/.bashrc
echo "export JAVA_HOME=$JAVA_HOME" | tee -a $HADOOP_HOME/etc/hadoop/hadoop-env.sh
cp $BOOTSTRAP_ROOT/core-site.xml $HADOOP_HOME/etc/hadoop/
cp $BOOTSTRAP_ROOT/yarn-site.xml $HADOOP_HOME/etc/hadoop/
cp $BOOTSTRAP_ROOT/hdfs-site.xml $HADOOP_HOME/etc/hadoop/
cp $BOOTSTRAP_ROOT/mapred-site.xml $HADOOP_HOME/etc/hadoop/

# Spark
cd /local
wget https://dlcdn.apache.org/spark/spark-3.2.0/spark-3.2.0-bin-hadoop2.7.tgz
tar -xvf spark-3.2.0-bin-hadoop2.7.tgz
mv spark-3.2.0-bin-hadoop2.7 $SPARK_HOME
echo "export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin" | tee -a ~/.bashrc
source ~/.bashrc
cp $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh;

cp $ALL_HOSTS_DIR $SPARK_HOME/conf/workers
echo "export PYSPARK_PYTHON=$DGL_PY/bin/python3" | tee -a $SPARK_HOME/conf/spark-env.sh
echo "export SPARK_MASTER_HOST=master" | tee -a $SPARK_HOME/conf/spark-env.sh



# Giraph
cd /local
git clone https://github.com/apache/giraph.git $GIRAPH_HOME/
cd $GIRAPH_HOME
git checkout release-1.3
mvn -Phadoop_2 -Dhadoop.version=2.7.2 package -DskipTests

mkdir -p $HADOOP_HOME/share/hadoop/giraph

cp $GIRAPH_HOME/giraph-examples/target/giraph-examples-1.3.0-SNAPSHOT-for-hadoop-2.7.2-jar-with-dependencies.jar $HADOOP_HOME/share/hadoop/giraph/

cp $GIRAPH_HOME/giraph-core/target/giraph-1.3.0-SNAPSHOT-for-hadoop-2.7.2-jar-with-dependencies.jar $HADOOP_HOME/share/hadoop/giraph/


export GUAVA_JAR=$GIRAPH_HOME/giraph-dist/target/giraph-1.3.0-SNAPSHOT-for-hadoop-2.7.2-bin/giraph-1.3.0-SNAPSHOT-for-hadoop-2.7.2/lib/guava-21.0.jar

rm -rf $HADOOP_HOME/share/hadoop/hdfs/lib/guava-11.0.2.jar
rm -rf $HADOOP_HOME/share/hadoop/tools/lib/guava-11.0.2.jar
rm -rf $HADOOP_HOME/share/hadoop/httpfs/tomcat/webapps/webhdfs/WEB-INF/lib/guava-11.0.2.jar
rm -rf $HADOOP_HOME/share/hadoop/yarn/lib/guava-11.0.2.jar
rm -rf $HADOOP_HOME/share/hadoop/common/lib/guava-11.0.2.jar


cp $GUAVA_JAR $HADOOP_HOME/share/hadoop/hdfs/lib/
cp $GUAVA_JAR $HADOOP_HOME/share/hadoop/tools/lib/
cp $GUAVA_JAR $HADOOP_HOME/share/hadoop/httpfs/tomcat/webapps/webhdfs/WEB-INF/lib/
cp $GUAVA_JAR $HADOOP_HOME/share/hadoop/yarn/lib/
cp $GUAVA_JAR $HADOOP_HOME/share/hadoop/common/lib/




# git clone https://github.com/dmlc/dgl.git /local/dgl
# cd /local/dgl
# git reset --hard HEAD
# git checkout a9c83bce15246c3e71e372e8128c7e345c136f36




