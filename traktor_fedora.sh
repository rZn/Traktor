#!/bin/bash
clear

RD='\033[91m' # Red Light
NC='\033[0m' # White

echo -e "${RD}Currently, Fedora isn't supported by Traktor. We Very Sorry, Please help us to develop Fedora Installer... :(\n\n"
exit

echo -e "${NC}Traktor v1.9\nTor will be automatically installed and configured…\n\n"

# Install Packages
sudo dnf install -y  \
	tor \
	privoxy \
	dnscrypt-proxy \
    torbrowser-launcher \

sudo dnf install -y \
    make \
    automake \
    gcc \
    python-pip \
    python-devel \
    libyaml-devel \
    redhat-rpm-config

sudo pip install obfsproxy

if [ -f "/etc/tor/torrc" ]; then
    echo "Backing up the old torrc to '/etc/tor/torrc.traktor-backup'..."
    sudo cp /etc/tor/torrc /etc/tor/torrc.traktor-backup
fi

#configuring dnscrypt-proxy
sudo wget https://gitlab.com/TraktorPlus/Traktor/raw/config/dnscrypt-proxy.service-fedora -O /etc/systemd/system/dnscrypt.service > /dev/null
sudo systemctl daemon-reload
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf >/dev/null
sudo chattr +i /etc/resolv.conf
sudo systemctl enable dnscrypt.service
sudo systemctl start dnscrypt.service

# Write Bridge
sudo wget https://gitlab.com/TraktorPlus/Traktor/raw/config/torrcV3 -O /etc/tor/torrc > /dev/null

# Change tor log file owner

sudo touch /var/log/tor/log
sudo chown toranon:toranon /var/log/tor/log

# Write Privoxy config
sudo perl -i -pe 's/^listen-address/#$&/' /etc/privoxy/config
echo 'logdir /var/log/privoxy
listen-address  0.0.0.0:8118
forward-socks5t             /     127.0.0.1:9050 .
forward         192.168.*.*/     .
forward            10.*.*.*/     .
forward           127.*.*.*/     .
forward           localhost/     .' | sudo tee -a /etc/privoxy/config > /dev/null
sudo systemctl enable privoxy
sudo systemctl restart privoxy.service

# Set IP and Port on HTTP and SOCKS
gsettings set org.gnome.system.proxy mode 'manual'
gsettings set org.gnome.system.proxy.http host 127.0.0.1
gsettings set org.gnome.system.proxy.http port 8118
gsettings set org.gnome.system.proxy.socks host 127.0.0.1
gsettings set org.gnome.system.proxy.socks port 9050
gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.0/8', '::1', '192.168.0.0/16', '192.168.8.1', '10.0.0.0/8', '172.16.0.0/12', '0.0.0.0/8', '10.0.0.0/8', '100.64.0.0/10', '127.0.0.0/8', '169.254.0.0/16', '172.16.0.0/12', '192.0.0.0/24', '192.0.2.0/24', '192.168.0.0/16', '192.88.99.0/24', '198.18.0.0/15', '198.51.100.0/24', '203.0.113.0/24', '224.0.0.0/3']"

# Install Finish
echo "Install Finished successfully…"

# Wait for tor to establish connection
echo "Tor is trying to establish a connection. This may take long for some minutes. Please wait" | sudo tee /var/log/tor/log
bootstraped='n'
sudo systemctl enable tor.service
sudo systemctl restart tor.service
while [ $bootstraped == 'n' ]; do
	if sudo cat /var/log/tor/log | grep "Bootstrapped 100%: Done"; then
		bootstraped='y'
	else
		sleep 1
	fi
done

# update finished
echo "Congratulations!!! Your computer is using Tor. may run torbrowser-launcher now."
