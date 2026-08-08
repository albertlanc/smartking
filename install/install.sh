#!/bin/bash
BLUE='\e[1;34m'
WHITE='\e[1;37m'
NC='\e[0m'

clear
echo -e "${BLUE}──────────────────────────────────────────────${NC}"
echo -e "${BLUE}     SMARTKING4LUV ™ SERVER INITIALIZATION    ${NC}"
echo -e "${BLUE}──────────────────────────────────────────────${NC}"

read -p " Enter Domain Name (e.g. vpn.example.com) : " DOMAIN
read -p " Enter NameServer (e.g. ns.example.com) : " NS_DOMAIN

echo "$DOMAIN" > /root/domain.txt
echo "$NS_DOMAIN" > /root/nsdomain.txt

echo -e "  ${WHITE}[1/6] Installing Dependencies & OpenVPN...${NC}"
apt-get update -y >/dev/null 2>&1
apt-get install -y curl wget unzip zip jq nginx dropbear socat python3 certbot openvpn stunnel4 cmake screen >/dev/null 2>&1

echo -e "  ${WHITE}[2/6] Validating SSL Certificate...${NC}"
systemctl stop nginx 2>/dev/null
certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email >/dev/null 2>&1
systemctl start nginx 2>/dev/null

echo -e "  ${WHITE}[3/6] Installing SlowDNS & UDP Custom (BadVPN)...${NC}"
wget -qO /usr/local/bin/dnstt-server "https://raw.githubusercontent.com/massdns/dnstt/master/dnstt-server/dnstt-server" 2>/dev/null
chmod +x /usr/local/bin/dnstt-server 2>/dev/null

wget -qO /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/badvpn/master/badvpn-udpgw" 2>/dev/null
chmod +x /usr/bin/badvpn-udpgw 2>/dev/null

cat << 'UDP_EOF' > /etc/systemd/system/badvpn.service
[Unit]
Description=BadVPN UDPGW
After=network.target
[Service]
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10
Restart=always
[Install]
WantedBy=multi-user.target
UDP_EOF
systemctl enable badvpn >/dev/null 2>&1
systemctl start badvpn >/dev/null 2>&1

echo -e "  ${WHITE}[4/6] Configuring Protocol Services...${NC}"
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear 2>/dev/null
systemctl enable dropbear >/dev/null 2>&1
systemctl restart dropbear >/dev/null 2>&1

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install >/dev/null 2>&1
systemctl enable xray >/dev/null 2>&1
systemctl start xray >/dev/null 2>&1

cat << 'PY_EOF' > /usr/local/bin/ssh-ws
import socket, threading
def handle_client(client_socket):
    try:
        target = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        target.connect(('127.0.0.1', 22))
        def forward(src, dst):
            try:
                while True:
                    data = src.recv(4096)
                    if not data: break
                    dst.sendall(data)
            except: pass
        t1 = threading.Thread(target=forward, args=(client_socket, target))
        t2 = threading.Thread(target=forward, args=(target, client_socket))
        t1.start(); t2.start()
    except:
        client_socket.close()
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('0.0.0.0', 2082))
server.listen(100)
while True:
    client, addr = server.accept()
    threading.Thread(target=handle_client, args=(client,)).start()
PY_EOF
chmod +x /usr/local/bin/ssh-ws

cat << 'WS_EOF' > /etc/systemd/system/ssh-ws.service
[Unit]
Description=SSH WebSocket Proxy
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/ssh-ws
Restart=always
[Install]
WantedBy=multi-user.target
WS_EOF

systemctl daemon-reload >/dev/null 2>&1
systemctl enable ssh-ws >/dev/null 2>&1
systemctl start ssh-ws >/dev/null 2>&1

echo -e "  ${WHITE}[5/6] Organizing System Files...${NC}"
mkdir -p /root/my-ssh-manager
cp -f *.sh /root/my-ssh-manager/ 2>/dev/null
chmod +x /root/my-ssh-manager/*.sh 2>/dev/null

echo -e "  ${WHITE}[6/6] Finalizing Menu Shortcut...${NC}"
cp -f menu.sh /usr/local/bin/menu
chmod +x /usr/local/bin/menu

echo -e "\n  ${BLUE}Installation Complete!${NC}"
echo -e "  Active Domain : $DOMAIN"
echo -e "  Type menu to launch your dashboard.\n"
echo -e "${BLUE}──────────────────────────────────────────────${NC}"
