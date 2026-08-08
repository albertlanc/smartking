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

echo -e "  [1/7] Installing Dependencies & Disabling Firewalls..."
ufw disable >/dev/null 2>&1
iptables -F
iptables -X
iptables -t nat -F
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

apt-get update -y >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget unzip zip jq nginx dropbear socat python3 certbot openvpn stunnel4 screen git speedtest-cli iptables-persistent >/dev/null 2>&1

echo -e "  [2/7] Validating SSL & Configuring Stunnel..."
systemctl stop nginx 2>/dev/null
certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email >/dev/null 2>&1
systemctl start nginx 2>/dev/null

cat /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/letsencrypt/live/$DOMAIN/privkey.pem > /etc/stunnel/stunnel.pem 2>/dev/null || openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN" -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem >/dev/null 2>&1

# Stunnel decrypts 443 and 8880, sends to Nginx on port 81 so Nginx can read the path
cat << STUNNEL_EOF > /etc/stunnel/stunnel.conf
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ws_443]
accept = 443
connect = 127.0.0.1:81

[ws_8880]
accept = 8880
connect = 127.0.0.1:81

[dropbear_444]
accept = 444
connect = 127.0.0.1:109
STUNNEL_EOF
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
systemctl restart stunnel4 >/dev/null 2>&1

echo -e "  [3/7] Building Xray Core & JSON Configs..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install >/dev/null 2>&1
mkdir -p /etc/xray /var/log/xray
# Generate the empty base configuration that your scripts expect
cat << XRAY_EOF > /etc/xray/config.json
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 10001,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vless" } }
    },
    {
      "port": 10002,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } }
    },
    {
      "port": 10003,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/trojan" } }
    }
  ],
  "outbounds": [ { "protocol": "freedom", "settings": {} } ]
}
XRAY_EOF
systemctl enable xray >/dev/null 2>&1
systemctl restart xray >/dev/null 2>&1

echo -e "  [4/7] Configuring Nginx Path Routing (Multiplexer)..."
rm -f /etc/nginx/sites-enabled/default
cat << NGINX_EOF > /etc/nginx/conf.d/xray.conf
server {
    listen 80;
    listen 81;
    server_name $DOMAIN;

    location /vless {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
    location /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
    location /trojan {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
    location / {
        proxy_pass http://127.0.0.1:2082;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
NGINX_EOF
systemctl restart nginx >/dev/null 2>&1

echo -e "  [5/7] Starting HTTP-Aware Python WebSocket Proxy..."
cat << 'PY_EOF' > /usr/local/bin/ssh-ws
import socket, threading

def handle_client(client_socket):
    try:
        target = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        target.connect(('127.0.0.1', 22))
        
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
systemctl restart ssh-ws >/dev/null 2>&1

echo -e "  [6/7] Compiling SlowDNS & Routing UDP 53..."
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
systemctl restart slowdns >/dev/null 2>&1

NIC=$(ip -o -4 route show to default | awk '{print $5}')
iptables -t nat -A PREROUTING -i $NIC -p udp --dport 53 -j REDIRECT --to-ports 5300
netfilter-persistent save >/dev/null 2>&1

echo -e "  [7/7] Configuring Dropbear & Organizing System Files..."
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=109/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=.*/DROPBEAR_EXTRA_ARGS="-p 143"/g' /etc/default/dropbear
systemctl restart dropbear >/dev/null 2>&1

mkdir -p /root/my-ssh-manager
cp -f *.sh /root/my-ssh-manager/ 2>/dev/null
chmod +x /root/my-ssh-manager/*.sh 2>/dev/null
cp -f menu.sh /usr/local/bin/menu
chmod +x /usr/local/bin/menu

echo -e "\n  ${BLUE}Installation Complete!${NC}"
echo -e "  Active Domain : $DOMAIN"
echo -e "  Type menu to launch your dashboard.\n"
echo -e "${BLUE}──────────────────────────────────────────────${NC}"
