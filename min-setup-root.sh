#!/bin/bash

# Include a new non-root username and the public SSH key for that user
newuser=
pubkey=

if [ -z $newuser ]
then
  echo "[!] Missing username."
  exit 1
fi

if [ -z $pubkey ]
then
  echo "[!] Missing SSH PUBKEY for: $newuser"
  exit 1
fi


apt-get update && apt-get upgrade -y
apt-get install net-tools -y
apt-get install nmap -y
apt install tmux -y
apt install git -y
apt install zip -y
apt install tree -y

# Install Docker
apt-get remove docker docker-engine docker.io containerd runc -y
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install docker-ce docker-ce-cli containerd.io

# docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

##

useradd -m -d /home/$newuser $newuser
groupadd $newuser
passwd $newuser
usermod -aG sudo $newuser
usermod -aG $newuser $newuser
usermod --shell /bin/bash $newuser
mkdir /home/$newuser/.ssh
touch /home/$newuser/.ssh/authorized_keys
echo $pubkey > /home/$newuser/.ssh/authorized_keys
chown -hR $newuser:$newuser /home/$newuser

sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#GatewayPorts no/GatewayPorts yes/g' /etc/ssh/sshd_config

apt-get update && apt-get upgrade -y
apt autoremove

# Disable IPv6 rules for UFW
echo "IPV6=yes" | sudo tee --append /etc/ufw/ufw.conf

ufw --force disable
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "*** Setup complete. Press enter to reboot. Then log in with $newuser. ***" 
echo "*** Execute docker-compose file to deploy app on reboot ***" 
read -p  "[!] SSH root access now disabled. [!]"
reboot
