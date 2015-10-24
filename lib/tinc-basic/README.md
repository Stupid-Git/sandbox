# Tinc Basic
This directory contains an example 2 node [Tinc][] VPN configuration using
[Vagrant][].


## Synopsis

```bash
# Setup & Run
$ git clone https://github.com/jamesbishopp/sandbox.git
$ cd sandbox/lib/tinc-basic
$ make

# Test: make HTTP request through VPN 
# from the host named 'tinc1' 
# to the host named 'tinc2'
$ vagrant ssh -c 'curl tinc2:8080/from/tinc1' tinc1
Response from tinc2 to requested path /from/tinc1

# Test: make HTTP request through VPN 
# from the host named 'tinc2' 
# to the host named 'tinc1'
$ vagrant ssh -c 'curl tinc1:8080/from/tinc2' tinc2
Response from tinc1 to requested path /from/tinc2

# Or better yet, run the tmux script to play around
$ ./tmux.sh
```

### Requirements
This demo was created with the following configuration. Be sure you have these
tools installed before trying this demo (it may work with earlier versions and
on other platforms).

* OSX/Darwin 10.11.1
* Tmux 2.1
* GNU Make 3.81
* VirtualBox 4.3.30
* Vagrant 1.7.4
* GNU Bash 4.3.42

## Details
The example creates two Ubuntu virtual machines. It then provisions each VM 
using the `provision.sh` shell script which installs [Node.js][] & [Tinc][], 
and creates the [Tinc][] configuration files. The script is idempotent, so it 
can be run multiple times without harming the configuration.

Each virtual machine will also run a simple HTTP server using a [Node.js][]
script: `server.js`. The script will echo the requested URI path and indicate
which host it came from.


### Configuration
The `Vagrantfile` contains a configuration for a private DHCP network. This, 
when using [VirtualBox][] as the virtual machine engine, will create a second
network interface that allows both hosts to communicate with each other. At
the time of this writing the network was assigned 172.28.128.0/24. The 
provision script will automatically detect the private IP address for each host
as long as the private interface name is `eth1`.

| Host  | DHCP eth1 IP  | Tinc VPN IP | Tinc Interface | HTTP Port |
|:-----:|:-------------:|:-----------:|:--------------:|:---------:|
| tinc1 | 172.28.128.3  | 10.0.0.1    |   tun0         |   8080    |
| tinc2 | 172.28.128.4  | 10.0.0.2    |   tun0         |   8080    |

Tinc's configuration can be found on each host at `/etc/tinc/sandbox`. The name 
`sandbox` represents the VPN network (Tinc supports multiple networks per host)
and can be anything. I decided it made some sense to name it sandbox for 
this demo.

* `tinc.conf`: configuration for the host/network (i.e. tinc1/sandbox)
* `tinc-up`: brings up the `tun0` network interface when tinc starts
* `tinc-down`: brings down the `tun0` network interface when tinc stops
* `hosts/*`: contains a file for each host in the sandbox network; in this case
  tinc1 and tinc2. Each file should contains its non-VPN interface, which in
  this case is the `eth1` IP address; and the subnet that the Tinc VPN network
  will handle, which is a single host (i.e. tinc1/10.0.0.1).

### Var Directory
The `./var` directory in this repository will contain all configuration and 
logs for both virtual machines. Within each host, the `/etc/tinc/sandbox`
directory is linked to `/vagrant/var/<hostname>/sandbox` which is located
on your host at `<repo>/var/<hostname>/sandbox`. 

The hosts directory is the same for both virtual machines since they both must
have the same files. Within each host the `/etc/tinc/sandbox/hosts` 
directory is linked to `/vagrant/var/hosts` which is located on your host
at `<repo>/var/hosts`.

Finally, both the HTTP and Tinc services log their output to 
`/etc/tinc/sandbox/logs` which is located on your host at 
`<repo>/var/<hostname>/sandbox/logs`. The Tinc service is set to log at a 
debug level of 5, which is a lot of detail but useful for a demo.

### Goal
Our goal is to allow both virtual machines to make HTTP requests that flow
through the VPN to their sibling host. 

* HTTP Request from Tinc 1 to Tinc 2 HTTP Server: `curl tinc2:8080`
* Request goes through the tun0 network interface to the Tinc daemon which 
  encrypts the packets and sends them to the tinc2 eth1 interface on port 655. 
* The tinc daemon on tinc2 then decrypts the packet and forwards it to port 8080
* HTTP server processes the request and sends a response which flows back through
  the VPN.

### Play
Once provisioning is complete you can play around with the configuration by
sending requests back and forth. You can either SSH into one of the hosts
or send a command through SSH.

```bash
# Send a command through SSH: request from tinc2 to tinc1
$ vagrant ssh -c 'curl tinc1:8080/from/tinc2' tinc2
Response from tinc1 to requested path /from/tinc2

# Login to Tinc1
$ vagrant ssh tinc1
...
vagrant@tinc1$ curl tinc1:8080/foo/bar
Response from tinc1 to requested path /foo/bar

vagrant@tinc1$ curl tinc2:8080/foo/bar
Response from tinc2 to requested path /foo/bar
```

### Tmux 
For those who enjoy Tmux, this repository has a script that will create a
useful tmux session with 4 windows. The 2 panes on the right will monitor the 
Tinc log files for both hosts and two panes on the left will be logged in to each
host. Sending commands can then be visualized in the log files in real time.
Run the `tmux.sh` script after the hosts have been provisioned and are running.

### Cleaning
Running `make clean` will remove all the configurations, which is essentially
resetting the configuration to a pre-provisioned state. This is useful when
making changes to the configuration so you don't have to rebuild the virtual
machines.

### Destroy
Once you've had enough, run `make destroy` to remove the virtual machines
and all temporary files. If you'd like to keep the files in the `var` directory
around for reference you can destroy only the virtual machines by running
`vagrant destroy`.


## Tinc Configuration
This section describes the Tinc configuration used in this demo.

### tinc.conf
The `tinc.conf` file contains settings for the sandbox network on the 
local `tincd` service. It contains the name of this node, the IP family, 
and the interface name it should bind to:

```bash
$ cat ./var/tinc1/sandbox/tinc.conf
Name = tinc1
AddressFamily = ipv4
Interface = tun0
```

Name and interface can be practically anything. In our case we remained sane
by naming the node the same as the hostname while the tunnel name is a 
standard convention in the Tinc documentation. You can find more settings 
in the [Tinc documentation](http://www.tinc-vpn.org/documentation/Main-configuration-variables.html#Main-configuration-variables).

### tinc-up
The `tinc-up` script is called by the Tinc daemon when it starts. May things
can be done here such as setting up a complicated routing scheme. For this demo
we simply created the `tun0` interface.

```bash
$ cat ./var/tinc1/sandbox/tinc-up
#!/bin/bash
ifconfig tun0 10.0.0.1 netmask 255.255.255.0
```

The IP address is the address that we're assigning to this node in the VPN 
network.

### tinc-down
The `tinc-down` interface is called by the Tinc daemon when the service is
stopped. It's primary responsibility is to clean up after the `tinc-up` work 
which is to remove the `tun0` interface and any routes created. In our case
we only need to remove the interface.

```bash
$ cat ./var/tinc1/sandbox/tinc-down
#!/bin/bash
ifconfig tun0 down
```

### hosts/*
The hosts directory must contain a reference to all nodes in the VPN network
where the file names map to the same names in each node's `tinc.conf` file.
The file should contain the IP address of the primary network interface that
the Tinc daemon should bind to and the subnet that the VPN node manages.
If the VPN node is a singleton, as in our demo, then the subnet is a single
IP address. 

```bash
$ cat ./var/hosts/tinc1
Address = 172.28.128.3
Subnet = 10.0.0.1

-----BEGIN RSA PUBLIC KEY-----
...
-----END RSA PUBLIC KEY-----
```

The subnet can be set to a range assigned to another interface (such as 
a local NAT). In this case, assuming the `tinc-up` script contains a route
from `tun0` to the defined subnet, then packets will be routed to the NAT 
(next demo). For more information, see the 
[Tinc documentation](http://www.tinc-vpn.org/documentation/Host-configuration-variables.html).

Keep reading for an explanation of the public key section.

### RSA Keys
When the configuration files are created, `tincd` must be run on each host
to generate encryption keys. Doing so creates a private key in the sandbox
directory named `rsa_key.priv` and appends a public key to the host file
in the hosts directory (above).

```bash
vagrant@tinc1$ tincd -n sandbox -K4096
```


[Tinc]: http://www.tinc-vpn.org/
[Vagrant]: https://www.vagrantup.com/
[Node.js]: https://nodejs.org
[VirtualBox]: https://www.virtualbox.org/

