#!/bin/bash
clear
echo -e "\e[1;33m────────────────────────────────────────────────────────\e[0m"
echo -e "       \e[1;33mINSTALLING SMARTKING4LUV ™ VPN MANAGER\e[0m"
echo -e "\e[1;33m────────────────────────────────────────────────────────\e[0m"
echo -e "\e[1;37m[1/5] Updating System & Installing Dependencies...\e[0m"
apt-get update -y > /dev/null 2>&1
apt-get install -y git curl wget dropbear > /dev/null 2>&1

echo -e "\e[1;37m[2/5] Applying BBR Turbo Speed Tweaks...\e[0m"
cat << 'SYS' >> /etc/sysctl.conf
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
SYS
sysctl -p > /dev/null 2>&1

echo -e "\e[1;37m[3/5] Fixing Dropbear (Port 143)...\e[0m"
systemctl stop dropbear 2>/dev/null
cat << 'DBEAR' > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=143
DROPBEAR_EXTRA_ARGS="-p 109"
DROPBEAR_BANNER="/etc/issue.net"
DROPBEAR_RECEIVE_WINDOW=65536
DBEAR
mkdir -p /etc/dropbear
[ ! -f /etc/dropbear/dropbear_rsa_host_key ] && dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key -s 2048 2>/dev/null
[ ! -f /etc/dropbear/dropbear_ecdsa_host_key ] && dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key 2>/dev/null
systemctl daemon-reload
systemctl restart dropbear
systemctl enable dropbear

echo -e "\e[1;37m[4/5] Downloading SMARTKING Files from Cloud...\e[0m"
rm -rf /root/my-ssh-manager
git clone https://github.com/albertlanc/smartking.git /root/my-ssh-manager > /dev/null 2>&1
chmod +x /root/my-ssh-manager/*.sh

echo -e "\e[1;37m[5/5] Finalizing Menu Shortcut...\e[0m"
cp /root/my-ssh-manager/menu.sh /usr/local/bin/menu
chmod +x /usr/local/bin/menu

echo -e "\n\e[1;32mInstallation Complete!\e[0m"
echo -e "\e[1;37mType \e[1;33mmenu\e[1;37m to launch your dashboard.\e[0m"
