#!/bin/bash
BLUE='\e[1;34m'
WHITE='\e[1;37m'
NC='\e[0m'

echo -e "${BLUE}──────────────────────────────────────────────${NC}"
echo -e "${BLUE}     SMARTKING4LUV ™ VPN MANAGER SETUP        ${NC}"
echo -e "${BLUE}──────────────────────────────────────────────${NC}"

echo -e "  ${WHITE}[1/5] Installing System Dependencies...${NC}"
apt-get update -y >/dev/null 2>&1
apt-get install -y curl wget unzip zip jq nginx dropbear socat python3 >/dev/null 2>&1

echo -e "  ${WHITE}[2/5] Configuring Protocol Services...${NC}"
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear 2>/dev/null
systemctl enable dropbear >/dev/null 2>&1
systemctl restart dropbear >/dev/null 2>&1

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install >/dev/null 2>&1
systemctl enable xray >/dev/null 2>&1
systemctl start xray >/dev/null 2>&1

cat << 'WS_EOF' > /etc/systemd/system/ssh-ws.service
[Unit]
Description=SSH WebSocket Proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -c "import socket; s=socket.socket(); s.bind(('0.0.0.0', 2082)); s.listen(100)"
Restart=always

[Install]
WantedBy=multi-user.target
WS_EOF

systemctl daemon-reload >/dev/null 2>&1
systemctl enable ssh-ws >/dev/null 2>&1
systemctl start ssh-ws >/dev/null 2>&1
systemctl restart nginx >/dev/null 2>&1

echo -e "  ${WHITE}[3/5] Applying BBR Speed Optimizations...${NC}"
if [ -f "bbr-setup.sh" ]; then
    chmod +x bbr-setup.sh
    ./bbr-setup.sh >/dev/null 2>&1
fi

echo -e "  ${WHITE}[4/5] Organizing System Files...${NC}"
mkdir -p /root/my-ssh-manager
cp -f *.sh /root/my-ssh-manager/ 2>/dev/null
chmod +x /root/my-ssh-manager/*.sh 2>/dev/null

echo -e "  ${WHITE}[5/5] Finalizing Menu Shortcut...${NC}"
cp -f menu.sh /usr/local/bin/menu
chmod +x /usr/local/bin/menu

echo -e "\n  ${BLUE}Installation Complete!${NC}"
echo -e "  Type ${WHITE}menu${NC} to launch your dashboard.\n"
echo -e "${BLUE}──────────────────────────────────────────────${NC}"
