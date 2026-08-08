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

echo -e "  [1/6] Installing Dependencies & Disabling Firewalls..."
# Aggressively disable default blocking
ufw disable >/dev/null 2>&1
iptables -F
iptables -X
iptables -t nat -F
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

apt-get update -y >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget unzip zip jq nginx dropbear socat python3 certbot openvpn stunnel4 screen git speedtest-cli iptables-persistent >/dev/null 2>&1

echo -e "  [2/6] Validating SSL & Configuring Stunnel..."
systemctl stop nginx 2>/dev/null
certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email >/dev/null 2>&1
systemctl start nginx 2>/dev/null

cat /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/letsencrypt/live/$DOMAIN/privkey.pem > /etc/stunnel/stunnel.pem 2>/dev/null || openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN" -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem >/dev/null 2>&1

# Stunnel Config: Routes 443 and 8880 to WS Proxy (2082), and 444 to Dropbear (109)
cat << STUNNEL_EOF > /etc/stunnel/stunnel.conf
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ws_443]
accept = 443
connect = 127.0.0.1:2082

[ws_8880]
accept = 8880
connect = 127.0.0.1:2082

[dropbear_444]
accept = 444
connect = 127.0.0.1:109
STUNNEL_EOF
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
systemctl restart stunnel4 >/dev/null 2>&1

echo -e "  [3/6] Starting HTTP-Aware Python WebSocket Proxy..."
# This Python script actually answers the 101 WebSocket Handshake so the connection doesn't drop
cat << 'PY_EOF' > /usr/local/bin/ssh-ws
import socket, threading

def handle_client(client_socket):
    try:
        target = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        target.connect(('127.0.0.1', 22))
        
        # Check for HTTP Upgrade handshake
        data = client_socket.recv(8192)
        if data and b"HTTP" in data:
            response = b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
            client_socket.send(response)
        elif data:
            target.send(data)
            
        def forward(src, dst):
            try:
                while True:
                    buffer = src.recv(4096)
                    if not buffer: break
                    dst.send(buffer)
            except: pass
            finally:
                src.close()
                dst.close()
                
        threading.Thread(target=forward, args=(client_socket, target)).start()
        threading.Thread(target=forward, args=(target, client_socket)).start()
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

echo -e "  [4/6] Compiling SlowDNS & Routing UDP 53..."
mkdir -p /etc/slowdns
wget -qO go.tar.gz https://go.dev/dl/go1.21.1.linux-amd64.tar.gz
tar -C /usr/local -xzf go.tar.gz
export PATH=$PATH:/usr/local/go/bin
git clone https://www.bamsoftware.com/git/dnstt.git /tmp/dnstt >/dev/null 2>&1
cd /tmp/dnstt/dnstt-server
go build >/dev/null 2>&1
mv dnstt-server /usr/local/bin/
cd - >/dev/null
rm -rf /tmp/dnstt go.tar.gz /usr/local/go
/usr/local/bin/dnstt-server -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.pub >/dev/null 2>&1

cat << SLOWDNS_EOF > /etc/systemd/system/slowdns.service
[Unit]
Description=SlowDNS DNSTT Server
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/dnstt-server -udp :5300 -privkey-file /etc/slowdns/server.key $NS_DOMAIN 127.0.0.1:22
Restart=always
[Install]
WantedBy=multi-user.target
SLOWDNS_EOF
systemctl daemon-reload >/dev/null 2>&1
systemctl enable slowdns >/dev/null 2>&1
systemctl start slowdns >/dev/null 2>&1

# Route DNS traffic from 53 to 5300
NIC=$(ip -o -4 route show to default | awk '{print $5}')
iptables -t nat -A PREROUTING -i $NIC -p udp --dport 53 -j REDIRECT --to-ports 5300
netfilter-persistent save >/dev/null 2>&1

echo -e "  [5/6] Configuring Dropbear & Other Services..."
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=109/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=.*/DROPBEAR_EXTRA_ARGS="-p 143"/g' /etc/default/dropbear
systemctl restart dropbear >/dev/null 2>&1

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install >/dev/null 2>&1
systemctl enable xray >/dev/null 2>&1
systemctl start xray >/dev/null 2>&1

echo -e "  [6/6] Organizing System Files..."
mkdir -p /root/my-ssh-manager
cp -f *.sh /root/my-ssh-manager/ 2>/dev/null
chmod +x /root/my-ssh-manager/*.sh 2>/dev/null
cp -f menu.sh /usr/local/bin/menu
chmod +x /usr/local/bin/menu

echo -e "\n  ${BLUE}Installation Complete!${NC}"
echo -e "  Active Domain : $DOMAIN"
echo -e "  Type menu to launch your dashboard.\n"
echo -e "${BLUE}──────────────────────────────────────────────${NC}"
