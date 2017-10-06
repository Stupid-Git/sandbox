#!/bin/bash

command -v nodejs >/dev/null || {
  sudo apt-get -y update >/dev/null
  sudo apt-get -y install tinc nodejs >/dev/null
  echo "Installed tinc"
  echo "Installed nodejs"
}

echo "Tinc network name: sandbox"

# Tinc Network Name & IP
#ip=$(ifconfig eth1 | head -2 | tail -1 | cut -f2 -d: | cut -f1 -d' ')
# For the ubuntu/XXX64 image I used (see Vagrantfile) ethernet ports are named
# differently, hence the change here from "eth1" to "enp0s8"
ip=$(ifconfig enp0s8 | head -2 | tail -1 | cut -f2 -d: | cut -f1 -d' ')
echo "$HOSTNAME IP Address: $ip"

# Tinc etc Directory
etc=/etc/tinc/sandbox
[ -e $etc ] || {
  mkdir -p /vagrant/var/$HOSTNAME/sandbox
  mkdir -p /vagrant/var/hosts
  sleep 1
  ln -s /vagrant/var/$HOSTNAME/sandbox $etc
  ln -s /vagrant/var/hosts $etc/hosts
}

# Tinc Configuration File
[ -e $etc/tinc.conf ] || {
  cat <<-EOF >$etc/tinc.conf
		Name = $HOSTNAME
    Mode = switch
		AddressFamily = ipv4
		#Interface = tun0
    PrivateKeyFile  = /etc/tinc/sandbox/rsa_key.priv
EOF
  [[ $HOSTNAME == tinc2 ]] && echo "ConnectTo = tinc1" >>$etc/tinc.conf
  echo "Created $etc/tinc.conf"
}

#debug
#rm $etc/tinc-up
#rm $etc/tinc-down
#debug

# Tinc Up
[ -e $etc/tinc-up ] || {
  [[ $HOSTNAME == tinc1 ]] && {
    cat <<-EOF >$etc/tinc-up
  		#!/bin/bash
  		#ifconfig tun0 10.0.0.${HOSTNAME: -1} netmask 255.255.255.0
      #TINC1
      ip link set $`echo INTERFACE` up mtu 1280 txqueuelen 1000
      ip addr  add 10.0.0.1/24 dev $`echo INTERFACE`
      ip route add 10.0.0.0/24 dev $`echo INTERFACE`
      ip route add 10.0.2.0/24 via 10.0.0.2
EOF
  }
  [[ $HOSTNAME == tinc2 ]] && {
    cat <<-EOF >$etc/tinc-up
  		#!/bin/bash
  		#ifconfig tun0 10.0.0.${HOSTNAME: -1} netmask 255.255.255.0
      #TINC2
      ip link set $`echo INTERFACE` up mtu 1280
      ip addr  add 10.0.0.2/24 dev $`echo INTERFACE`
      ip route add 10.0.0.0/24 via 10.0.0.1
EOF
  }
  chmod +x $etc/tinc-up
  echo "Created $etc/tinc-up"
}

# Tinc Down
[ -e $etc/tinc-down ] || {
#  cat <<-EOF >$etc/tinc-down
#		#!/bin/bash
#		ifconfig tun0 down
#EOF
  [[ $HOSTNAME == tinc1 ]] && {
    cat <<-EOF >$etc/tinc-down
      #!/bin/bash
      #ifconfig tun0 down
      #TINC1
      ip route del 10.0.2.0/24 via 10.0.0.2

      ip route del 10.0.0.0/24 dev $`echo INTERFACE`
      ip addr  del 10.0.0.1/24 dev $`echo INTERFACE`
      ip link set $`echo INTERFACE` down
EOF
  }
  [[ $HOSTNAME == tinc2 ]] && {
    cat <<-EOF >$etc/tinc-down
      #!/bin/bash
      #ifconfig tun0 down
      #TINC2
      ip route del default via 10.0.0.1
      ip addr  del 10.0.0.2/24 dev $`echo INTERFACE`
      ip link set $`echo INTERFACE` down
EOF
  }
  chmod +x $etc/tinc-down
  echo "Created $etc/tinc-down"
}

# Create Tinc Host File
mkdir -p $etc/hosts;
[ -e $etc/hosts/$HOSTNAME ] || {
  cat <<-EOF >$etc/hosts/$HOSTNAME
		Address = $ip
		Subnet = 10.0.0.${HOSTNAME:4}
EOF
  echo "Created $etc/hosts/$HOSTNAME"

  # Key Pairs
  [ -e $etc/rsa_key.priv ] && rm $etc/rsa_key.priv
  { echo; echo; } | tincd -n sandbox -K4096 2>/dev/null
  echo "Created RSA Keys for $HOSTNAME"
}


function addhost() {
    HOSTNAME=$1
    IP=$2
    HOSTS_LINE="$IP\t$HOSTNAME"
    if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
        then
            echo "$HOSTNAME already exists : $(grep $HOSTNAME $ETC_HOSTS)"
        else
            echo "Adding $HOSTNAME to your $ETC_HOSTS";
            sudo -- sh -c -e "echo '$HOSTS_LINE' >> /etc/hosts";

            if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
                then
                    echo "$HOSTNAME was added succesfully \n $(grep $HOSTNAME /etc/hosts)";
                else
                    echo "Failed to Add $HOSTNAME, Try again!";
            fi
    fi
}
# Update host file
# TODO this sed command below will fail if there is a TAB between 127.0.0.1 AND localhost
sed -i -r 's/(127\.0\.0\.1 localhost)/\1\n10.0.0.1 tinc1\n10.0.0.2 tinc2\n/' /etc/hosts
addhost "tinc1" "10.0.0.1"
addhost "tinc2" "10.0.0.2"


# Log files
logs=$etc/logs
mkdir -p $logs

# Start Tinc
pid=$(pidof tincd)
(( pid )) || {
  tincd -n sandbox -D -d5 >$logs/tinc.log 2>&1 &
  echo "Started Tinc with PID $!"
}

# Start Web Server
pid=$(pidof nodejs)
(( pid )) || {
  nodejs /vagrant/server.js >$logs/http.log &
  echo "Started HTTP Server with PID $!"
}
