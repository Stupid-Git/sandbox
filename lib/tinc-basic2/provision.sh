#!/bin/bash

command -v nodejs >/dev/null || {
  sudo apt-get -y update >/dev/null
  sudo apt-get -y install tinc nodejs >/dev/null
  echo "Installed tinc"
  echo "Installed nodejs"
}

echo "Tinc network name: sandbox"

# Tinc Network Name & IP
ip=$(ifconfig eth1 | head -2 | tail -1 | cut -f2 -d: | cut -f1 -d' ')
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
		AddressFamily = ipv4
		Interface = tun0
EOF
  [[ $HOSTNAME == tinc2 ]] && echo "ConnectTo = tinc1" >>$etc/tinc.conf
  echo "Created $etc/tinc.conf"
}

# Tinc Up
[ -e $etc/tinc-up ] || {
  cat <<-EOF >$etc/tinc-up
		#!/bin/bash
		ifconfig tun0 10.0.0.${HOSTNAME: -1} netmask 255.255.255.0
EOF
  chmod +x $etc/tinc-up
  echo "Created $etc/tinc-up"
}

# Tinc Down
[ -e $etc/tinc-down ] || {
  cat <<-EOF >$etc/tinc-down
		#!/bin/bash
		ifconfig tun0 down
EOF
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

# Update host file
sed -i -r 's/(127\.0\.0\.1 localhost)/\1\n10.0.0.1 tinc1\n10.0.0.2 tinc2\n/' /etc/hosts

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

