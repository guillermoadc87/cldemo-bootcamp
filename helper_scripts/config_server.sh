#!/bin/bash

echo "#################################"
echo "  Running OVERLOAD SCRIPT config_server.sh"
echo "#################################"
sudo su

# Remove warnings in MOTD that reboot is required
rm -fv /etc/update-motd.d/98-reboot-required

# Make DHCP Try Over and Over Again
echo "retry 1;" >> /etc/dhcp/dhclient.conf

#Replace existing network interfaces file
echo -e "auto lo" > /etc/network/interfaces
echo -e "iface lo inet loopback\n\n" >> /etc/network/interfaces

#Add vagrant interface
echo -e "\n\nauto eth0" >> /etc/network/interfaces
echo -e "iface eth0 inet dhcp\n\n" >> /etc/network/interfaces

useradd cumulus -m -s /bin/bash
echo "cumulus:CumulusLinux!" | chpasswd
sed "s/PasswordAuthentication no/PasswordAuthentication yes/" -i /etc/ssh/sshd_config

## Convenience code. This is normally done in ZTP.
echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus
mkdir /home/cumulus/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzH+R+UhjVicUtI0daNUcedYhfvgT1dbZXgY33Ibm4MOo+X84Iwuzirm3QFnYf2O3uyZjNyrA6fj9qFE7Ekul4bD6PCstQupXPwfPMjns2M7tkHsKnLYjNxWNql/rCUxoH2B6nPyztcRCass3lIc2clfXkCY9Jtf7kgC2e/dmchywPV5PrFqtlHgZUnyoPyWBH7OjPLVxYwtCJn96sFkrjaG9QDOeoeiNvcGlk4DJp/g9L4f2AaEq69x8+gBTFUqAFsD8ecO941cM8sa1167rsRPx7SK3270Ji5EUF3lZsgpaiIgMhtIB/7QNTkN9ZjQBazxxlNVN6WthF8okb7OSt" >> /home/cumulus/.ssh/authorized_keys
chmod 700 -R /home/cumulus
chown -R cumulus:cumulus /home/cumulus
chmod 600 /home/cumulus/.ssh/*
chmod 700 /home/cumulus/.ssh


# Other stuff
ping 8.8.8.8 -c2
if [ "$?" == "0" ]; then
  wget -O- https://apps3.cumulusnetworks.com/setup/cumulus-apps-deb.pubkey | apt-key add -

  cat << EOT > /etc/apt/sources.list.d/cumulus-apps-deb-xenial.list
deb [arch=amd64] https://apps3.cumulusnetworks.com/repos/deb xenial netq-1.4
EOT
  apt-get update -qy &&  apt-get install ifupdown2 python-ipaddr python-argcomplete lldpd ntp ntpdate cumulus-netq -qy --allow-unauthenticated && echo "configure lldp portidsubtype ifname" > /etc/lldpd.d/port_info.conf 
  systemctl enable netqd
  systemctl enable netq-agent
  cat << EOT > /etc/netq/netq.yml
  # See /usr/share/doc/netq.yml for full configuration file
backend:
  port: 6379
  server: 192.168.0.254
  vrf: default
user-commands:
- commands:
  - command: /bin/cat /etc/network/interfaces
    key: config-interfaces
    period: '60'
  - command: /bin/cat /etc/ntp.conf
    key: config-ntp
    period: '60'
  service: misc
- commands:
  - command:
    - /usr/bin/vtysh
    - -c
    - show running-config
    key: config-quagga
    period: '60'
  service: zebra
EOT
  wget -O /root/ifupdown2.deb http://ftp.us.debian.org/debian/pool/main/i/ifupdown2/ifupdown2_1.0~git20170314-1_all.deb && \
  dpkg -i /root/ifupdown2.deb && \
  rm -rfv /root/ifupdown2.deb
  cat << EOT > /etc/network/ifupdown2/policy.d/bond.json 
{
    "bond": {
       "defaults": {
           "bond-mode": "802.3ad",
     "bond-xmit-hash-policy": "layer3+4",
     "bond-lacp-rate": "fast",
     "bond-miimon": "100",
     "bond-min-links": "1",
     "bond-use-carrier": "yes",
     "bond-updelay": "0",
     "bond-downdelay": "0"
       }
    }
}
EOT

fi

# Set Timezone
cat << EOT > /etc/timezone
Etc/UTC
EOT

# Apply Timezone Now
# dpkg-reconfigure -f noninteractive tzdata

# Write NTP Configuration
cat << EOT > /etc/ntp.conf
# /etc/ntp.conf, configuration for ntpd; see ntp.conf(5) for help

driftfile /var/lib/ntp/ntp.drift

statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable

server 192.168.0.254 iburst

# By default, exchange time with everybody, but don't allow configuration.
restrict -4 default kod notrap nomodify nopeer noquery
restrict -6 default kod notrap nomodify nopeer noquery

# Local users may interrogate the ntp server more closely.
restrict 127.0.0.1
restrict ::1

# Specify interfaces, don't listen on switch ports
interface listen eth0
EOT

sudo systemctl enable ntp.service
sudo systemctl start ntp.service

echo "#################################"
echo "   Finished"
echo "#################################"
