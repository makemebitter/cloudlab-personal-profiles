"""Spawn a cluster and setup the networking, personal scripts to setup
various things"""

# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.
import geni.rspec.pg as pg
# Import the Emulab specific extensions.
# import geni.rspec.emulab as emulab
DISK_IMAGES = {
    'ubuntu16': 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU16-64-STD',
    'ubuntu18': 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD',
    'ubuntu20': 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU20-64-STD'
}

# Create a portal object,
pc = portal.Context()

pc.defineParameter("slaveCount", "Number of slave nodes",
                   portal.ParameterType.INTEGER, 1)
pc.defineParameter("osNodeTypeSlave", "Hardware Type for slaves",
                   portal.ParameterType.NODETYPE, "",
                   longDescription='''A specific hardware type to use for each
                   node. Cloudlab clusters all have machines of specific types.
                     When you set this field to a value that is a specific
                     hardware type, you will only be able to instantiate this
                     profile on clusters with machines of that type.
                     If unset, when you instantiate the profile, the resulting
                     experiment may have machines of any available type
                     allocated.''')
pc.defineParameter("osNodeTypeMaster", "Hardware Type for master",
                   portal.ParameterType.NODETYPE, "",
                   longDescription='''A specific hardware type to use for each
                   node. Cloudlab clusters all have machines of specific types.
                     When you set this field to a value that is a specific
                     hardware type, you will only be able to instantiate this
                     profile on clusters with machines of that type.
                     If unset, when you instantiate the profile, the resulting
                     experiment may have machines of any available type
                     allocated.''')

pc.defineParameter(
    "osNode", "OS for the nodes",
    portal.ParameterType.STRING,
    "ubuntu18",
    legalValues=sorted(list(DISK_IMAGES.keys())),
    longDescription='''OS for the nodes''')
pc.defineParameter(
    "publicIPSlaves", "Request public IP addresses for the slaves or not",
    portal.ParameterType.BOOLEAN, True)

pc.defineParameter(
    "jupyterPassword", "The password of jupyter notebook, default: root",
    portal.ParameterType.STRING, 'root')
pc.defineParameter(
    "GPUWorkers", "Workers have GPU or not, default: 1",
    portal.ParameterType.BOOLEAN, True)
pc.defineParameter(
    "privateKey", "Your private ssh key, this is required for greenplum.",
    portal.ParameterType.STRING, "",
    longDescription='''Please create a project
                   private key and upload it also to your cloudlab account.
                   Don't use your personal private key.''')
pc.defineParameter(
    "gpadminPassword",
    "The password of gpadmin user. WARNING: use a very strong one",
    portal.ParameterType.STRING, "")


# Optional ephemeral blockstore
pc.defineParameter(
    "tempFileSystemSize",
    "Temporary Filesystem Size",
    portal.ParameterType.INTEGER, 400, advanced=True,
    longDescription="""
    The size in GB of a temporary file system to mount on each of your nodes.
    Temporary means that they are deleted when your experiment is terminated.
    The images provided by the system have small root partitions,
    so use this option if you expect you will need more space to build your
    software packages or store temporary files.""")

# Instead of a size, ask for all available space.
pc.defineParameter(
    "tempFileSystemMax",
    "Temp Filesystem Max Space",
    portal.ParameterType.BOOLEAN, False,
    advanced=True,
    longDescription="""
    Instead of specifying a size for your temporary filesystem,
    check this box to allocate all available disk space.
    Leave the size above as zero.""")

pc.defineParameter(
    "tempFileSystemMount", "Temporary Filesystem Mount Point",
    portal.ParameterType.STRING, "/mnt", advanced=True,
    longDescription="""
    Mount the temporary file system at this mount point; in general you
    you do not need to change this, but we provide the option just in case your
    software is finicky.""")


params = pc.bindParameters()


def create_request(request, params, role, ip, worker_num=None):
    if role == 'm':
        name = 'master'
        worker_num = 0
    elif role == 's':
        name = 'worker{}'.format(worker_num)
    req = request.RawPC(name)
    if role == 'm':
        req.routable_control_ip = True
        if params.osNodeTypeMaster:
            req.hardware_type = params.osNodeTypeMaster
    elif role == 's':
        req.routable_control_ip = params.publicIPSlaves
        if params.osNodeTypeSlave:
            req.hardware_type = params.osNodeTypeSlave
    proper_key = '\n'.join(params.privateKey.split())
    proper_key = '-----BEGIN RSA PRIVATE KEY-----\n' + \
        proper_key + '\n-----END RSA PRIVATE KEY-----\n'
    req.disk_image = DISK_IMAGES[params.osNode]
    exec_string = """
    sudo chmod 777 -R /local /mnt;
    rsync -av /local/ /mnt/local/;
    sudo mount -o bind /mnt/local /local;
    sudo bash /local/repository/bootstrap.sh\
    '{role}'\
    '{params.jupyterPassword}'\
    '{proper_key}'\
    '{params.GPUWorkers}'\
    '{params.gpadminPassword}'\
    '{params.tempFileSystemMount}'\
    2>&1 | sudo tee -a /local/logs/setup.log
    """.format(**locals())

    req.addService(
        pg.Execute(
            'bash',
            exec_string
        )
    )

    if params.tempFileSystemSize > 0 or params.tempFileSystemMax:
        bs = req.Blockstore(
            "bs_{}_{}".format(role, worker_num), params.tempFileSystemMount)
        if params.tempFileSystemMax:
            bs.size = "0GB"
        else:
            bs.size = "{}GB".format(params.tempFileSystemSize)
    iface = req.addInterface(
        'eth1', pg.IPv4Address(ip, '255.255.255.0'))
    return iface


# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()

# Link link-0
link_0 = request.LAN('link-0')
link_0.Site('undefined')

# Master Node
iface = create_request(request, params, 'm', '10.10.1.1')
link_0.addInterface(iface)

# Slave Nodes
for i in range(params.slaveCount):
    iface = create_request(
        request, params, 's', '10.10.1.{}'.format(i + 2), worker_num=i)
    link_0.addInterface(iface)


# Print the generated rspec
pc.printRequestRSpec(request)
