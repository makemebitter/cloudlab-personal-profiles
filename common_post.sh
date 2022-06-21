set -e
source helper.sh

# Aligraph setup
cd $NFS_DIR/aligraph/dist
$DGL_PY -m pip install graph_learn-1.0.1-cp38-cp38-linux_x86_64.whl