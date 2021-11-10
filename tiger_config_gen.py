import json
import os
import argparse

parser = argparse.ArgumentParser()
parser.add_argument(
    '--input', type=str, default='/local/tigergraph-3.3.0-offline/install_conf.json'
)
parser.add_argument(
    '--output', type=str, default='/local/tigergraph-3.3.0-offline/install_conf.json'
)
args = parser.parse_args()


with open(args.input, "r") as jsonFile:
    data = json.load(jsonFile)

with open(os.environ['ALL_HOSTS_COMPLETE_DIR'], 'r') as f:
    hosts = f.readlines()

hosts = [x.rstrip().split() for x in hosts]
new_hosts = []
for x in hosts:
    if x[1] != 'master':
        new_x = "{}: {}".format(x[1], x[0])
    else:
        new_x = "{}: {}".format(x[1]+'0', x[0])
    new_hosts.append(new_x)
hosts = new_hosts

basicconfig = data['BasicConfig']
tigergraphconfig = basicconfig['TigerGraph']
tigergraphconfig['Username'] = os.environ['PROJECT_USER']
tigergraphconfig['PrivateKeyFile'] = os.environ['PROJECT_SSH_KEY']
tigergraphconfig['PublicKeyFile'] = os.environ['PROJECT_SSH_KEY_PUB']
rootdirconfig = basicconfig['RootDir']
rootdirconfig['AppRoot'] = os.path.join(os.environ['TIGER_HOME'], 'app')
rootdirconfig['DataRoot'] = os.path.join(os.environ['TIGER_HOME'], 'data')
rootdirconfig['LogRoot'] = os.path.join(os.environ['TIGER_HOME'], 'log')
rootdirconfig['TempRoot'] = os.path.join(os.environ['TIGER_HOME'], 'tmp')
basicconfig['NodeList'] = hosts
clusterconfig = data['AdvancedConfig']['ClusterConfig']['LoginConfig']
clusterconfig['SudoUser'] = os.environ['PROJECT_USER']
clusterconfig['Method'] = 'K'
clusterconfig['K'] = os.environ['PROJECT_SSH_KEY']

with open(args.output, "w") as jsonFile:
    json.dump(data, jsonFile)
