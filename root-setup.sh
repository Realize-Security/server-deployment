#!/bin/bash

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
sudo apt-get remove docker docker-engine docker.io containerd runc -y
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

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


ufw --force disable
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

new_user_path=/home/$newuser
ssh_path=$new_user_path/.ssh/git_ssh
rsec_working_dir=$new_user_path/realizesec_dot_com
echo
echo "[!] Creating new SSH key for Git [!]"
ssh-keygen -C "richard@realizesec.com" -f $ssh_path 
ssh-add $ssh_path  
echo "[#] Copy this public key value into Github"
cat $ssh_path.pub
chown -R $newuser:$newuser $new_user_path/.ssh
echo
read -p "Press enter when done ready to clone Git repo..."

git clone git@github.com:Realize-Security/realizesec_dot_com.git
mv realizesec_dot_com $rsec_working_dir
mkdir -p $rsec_working_dir/nginx/certs/PROD
mv fullchain.pem $rsec_working_dir/nginx/certs/PROD/
mv privkey.pem $rsec_working_dir/nginx/certs/PROD/
chown -R $newuser:$newuser $rsec_working_dir

echo "*** Setup complete. Press enter to reboot. Then log in with $newuser. ***" 
read -p  "[!] SSH root access now disabled. [!]"
reboot