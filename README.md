# Cumulus Linux Demo Boot Camp
This repository exists to provide a more accurate facsimile of the Cumulus Linux Boot Camp course.

### What is Vagrant?
[Vagrant](https://www.vagrantup.com/) is an open source tool for quickly
deploying large topologies of virtual machines. Vagrant and [Cumulus VX](#what-is-cumulus-vx) can be
used together to build virtual simulations of production networks to validate
configurations, develop automation code, and simulate failure scenarios.

Vagrant uses [Vagrantfiles](#what-is-a-vagrantfile) to represent the topology.

### What is a Vagrantfile?
Vagrant topologies are described in a text file called a "Vagrantfile," 
which is also the filename. A Vagrantfile is a Ruby program that
tells Vagrant which devices to create and how to configure their networks.
`vagrant up` will execute the Vagrantfile and create the reference topology
using Virtualbox. 

[Vagrantfiles](#what-is-a-vagrantfile) for the Libvirt/KVM hypervisor are also included in this repository.
To use them you need to be using a Linux system and follow the [Linux setup instructions](./documentation/linux).

### Which Software Versions Should I Use?
Software versions are always changing. At the time of this writing the following 
versions are known to work well: 
* Vagrant v2.0.2+
* Virtualbox v5.1.22

### What Is The Out Of Band Server Doing?
The following tasks are completed to make using the topology more convenient.

 * DHCP, DNS, and Apache are installed and configured on the oob-mgmt-server
 * Static MAC address entries are added to DHCP on the oob-mgmt-server for all devices
 * A bridge is created on the oob-mgmt-switch to connect all devices eth0 interfaces together
 * A private key for the Cumulus user is installed on the oob-mgmt-server
 * Public keys for the cumulus user are installed on all of the devices, allowing passwordless ssh
 * A NOPASSWD stanza is added for the cumulus user in the sudoers file of all devices

After the topology comes up, we use `vagrant ssh` to log in to the management
device and switch to the `cumulus` user. The `cumulus` user is able to access
other devices (leaf01, spine02) in the network using its SSH key, and has
passwordless sudo enabled on all devices to make it easy to run administrative
commands. Further, most automation tools (Ansible, Puppet, Chef) are run
from this management server. **Most demos assume that you are logged into
the out of band management server as the `cumulus` user**.

Note that due to the way we simulate the out of band network, it is not possible
to use `vagrant ssh` to access in-band devices like leaf01 and leaf02. These
devices **must** be accessed via the out-of-band management server.

### How are IP addresses Allocated?
The [Reference Topology](#what-is-the-reference-topology) only specifies the IP addresses used in the Out-of-Band network
for maximum flexibility when creating new demos. To see the IP address allocation for the
Out-of-Band Network check the [IPAM diagram](./documentation/ipam.md)

### Tips on Managing the VMs in the Topology
The topology built using this Vagrantfile does not support `vagrant halt` or
`vagrant resume` for in-band devices. To resume working with the demos at a later point in time, use 
the hypervisor's halt and resume functionality.

In Virtualbox this can be done inside of the GUI by powering off (and later powering-on) the devices 
involved in the simulation or by running the following CLI commands:

    * VBoxManage controlvm leaf01 poweroff
    * VBoxManage startvm leaf01 --type headless


#### Factory-reset a device

    vagrant destroy -f leaf01
    vagrant up leaf01


#### Destroy the entire topology

    vagrant destroy -f

### Can I Preserve My Configuration
In order to keep your configuration across Vagrant sessions, you should either save your configuration
in a repository using an automation tool such as Ansible, Puppet, or Chef (preferred) or alternatively 
copy the configuration files off of the VMs before running the "vagrant destroy" command to remove and 
destroy the VMs involved in the simulation.

One helpful command for saving configuration from Cumulus devices is:

    net show configuration files

or 

    net show configuration command

**This command will not show configuration for third-party applications.**

### Running More Than One Simulation At Once
Using this demo environment, it is possible to run multiple simulations at once. The procedure varies
slightly from hypervisor to hypervisor.

#### Virtualbox
In the Vagrantfile built for Virtualbox there is a line which sets `simid= [some integer]` in order to
create unique simulations a text editor can be used to modify the simid value to something unique which 
does not match other running simulations on the simulation node.

### How Can I Customize the Topology?
This Vagrant topology is built using [Topology Converter](https://github.com/cumulusnetworks/topology_converter).
To create your own arbitrary topology, we recommend using Topology Converter. This will create a new 
Vagrantfile which is specific to your environment.For more details on how to make customized 
topologies, read Topology Converter's [documentation](https://github.com/CumulusNetworks/topology_converter/tree/master/documentation).

#### **Advanced Users ONLY: ** Editing the existing topology
This can be a bit tricky, to edit the existing topologies you can bring in the required portions of [Topology Converter](https://github.com/cumulusnetworks/topology_converter) needed to get the job done.
The process looks like what is featured below and is also found in the `build.sh` script used to rebuild and update this environment.

    vagrant destroy -f
    wget https://raw.githubusercontent.com/CumulusNetworks/topology_converter/master/topology_converter.py
    mkdir ./templates/
    wget -O ./templates/Vagrantfile.j2 https://raw.githubusercontent.com/CumulusNetworks/topology_converter/master/templates/Vagrantfile.j2
    # edit topology.dot as desired
    python topology_converter.py topology.dot


## Quick Start:
Before running this demo or any of the other demos in the list below, install
[VirtualBox](https://www.virtualbox.org/wiki/Download_Old_Builds) and
[Vagrant](https://releases.hashicorp.com/vagrant/).

**NOTE: On Windows, if you have HyperV enabled, you will need to disable it as it will
conflict with Virtualbox's ability to create 64-bit VMs.**

### Provision the Topology and Log-in

    git clone https://github.com/cumulusnetworks/cldemo-vagrant
    cd cldemo-vagrant
    vagrant up oob-mgmt-server oob-mgmt-switch leaf01
    vagrant ssh oob-mgmt-server
    ssh leaf01

---

>©2017 Cumulus Networks. CUMULUS, the Cumulus Logo, CUMULUS NETWORKS, and the Rocket Turtle Logo 
(the “Marks”) are trademarks and service marks of Cumulus Networks, Inc. in the U.S. and other 
countries. You are not permitted to use the Marks without the prior written consent of Cumulus 
Networks. The registered trademark Linux® is used pursuant to a sublicense from LMI, the exclusive 
licensee of Linus Torvalds, owner of the mark on a world-wide basis. All other marks are used under 
fair use or license from their respective owners.

For further details please see: [cumulusnetworks.com](http://www.cumulusnetworks.com)
