set -e
source helper.sh
mkdir $NFS_DIR
echo "$NFS_DIR  *(rw,sync,crossmnt,no_root_squash,crossmnt)" | sudo tee -a  /etc/exports
sudo /etc/init.d/nfs-kernel-server restart
mkdir $NFS_DIR/ssd
mkdir $SSD_DIR/nfs
migrate_a2b $NFS_DIR/ssd $SSD_DIR/nfs
mkdir $NFS_DIR/jars
wget https://repo1.maven.org/maven2/sh/almond/spark-stubs_30_2.12/0.11.0/spark-stubs_30_2.12-0.11.0.jar -O $NFS_DIR/jars/spark-stubs_30_2.12-0.11.0.jar

cp $ALL_HOSTS_DIR $NFS_DIR/
export GIT_SSH_COMMAND="ssh -i /home/$PROJECT_USER/.ssh/prj_key"

git clone git@github.com:makemebitter/gsys.git $NFS_DIR/gsys

git clone git@github.com:makemebitter/dgl.git $NFS_DIR/dgl

git clone git@github.com:makemebitter/roc.git $NFS_DIR/roc

git clone git@github.com:makemebitter/graph-learn.git $NFS_DIR/aligraph

cd $NFS_DIR/aligraph
git submodule update --init
make test
make python PYTHON=$SYS_PY



# cd /local/dgl
# git reset --hard HEAD
# git checkout a9c83bce15246c3e71e372e8128c7e345c136f36


# Gdrive
cd /local 
wget https://github.com/prasmussen/gdrive/releases/download/2.1.1/gdrive_2.1.1_linux_amd64.tar.gz
tar -xvzf gdrive_2.1.1_linux_amd64.tar.gz
sudo mv gdrive /usr/local/bin/gdrive

# Tigergraph
cd /local
wget https://dl.tigergraph.com/enterprise-edition/tigergraph-3.3.0-offline.tar.gz
tar -xzvf tigergraph-3.3.0-offline.tar.gz

cd tigergraph-3.3.0-offline
python3 /local/repository/tiger_config_gen.py --input $(pwd)/install_conf.json --output $(pwd)/install_conf.json
sudo ./install.sh -n
source ~/.bashrc
$TIGER_HOME/app/cmd/gadmin stop all -y

# HDFS
$HADOOP_HOME/bin/hdfs namenode -format "spark_cluster"






# Execution

# use start-all.sh manully
# Hadoop master
# $HADOOP_HOME/bin/hdfs namenode -format "spark_cluster"
# $HADOOP_HOME/sbin/hadoop-daemon.sh --script hdfs start namenode
# $HADOOP_HOME/sbin/yarn-daemon.sh start resourcemanager
# # Hadoop slave
# $HADOOP_HOME/sbin/hadoop-daemon.sh --script hdfs start datanode
# $HADOOP_HOME/sbin/yarn-daemon.sh start nodemanager


