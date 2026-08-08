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

echo -e "  [1/6] Installing Dependencies & Speedtest Tools..."
apt-get update -y >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget unzip zip jq nginx dropbear socat python3 certbot openvpn stunnel4 screen git speedtest-cli iptables iptables-persistent >/dev/null 2>&1
wget -qO /usr/local/bin/fast https://github.com/ddo/fast/releases/download/v0.0.4/fast_linux_amd64 2>/dev/null
chmod +x /usr/local/bin/fast 2>/dev/null

echo -e "  [2/6] Validating SSL & Configuring Stunnel (Ports 443, 444, 8880)..."
systemctl stop nginx 2>/dev/null
certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email >/dev/null 2>&1
systemctl start nginx 2>/dev/null

# Bind SSL cert to Stunnel
cat /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/letsencrypt/live/$DOMAIN/privkey.pem > /etc/stunnel/stunnel.pem 2>/dev/null || openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN" -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem >/dev/null 2>&1

# Write Stunnel Configuration for Custom SSH
cat << STUNNEL_EOF > /etc/stunnel/stunnel.conf
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear_443]
accept = 443
connect = 127.0.0.1:109

[dropbear_444]
accept = 444
connect = 127.0.0.1:143

[custom_ssh_8880]
accept = 8880
connect = 127.0.0.1:22
STUNNEL_EOF
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
systemctl restart stunnel4 >/dev/null 2>&1

echo -e "  [3/6] Compiling SlowDNS & Starting Background Service (Port 5300)..."
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

# Create persistent background service for SlowDNS
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

echo -e "  [4/6] Configuring Dropbear & SSH-WS (Nginx Proxy Port 80)..."
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=109/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=.*/DROPBEAR_EXTRA_ARGS="-p 143"/g' /etc/default/dropbear
systemctl restart dropbear >/dev/null 2>&1

# Route traffic from Port 80 through Nginx to the Python WebSocket on 2082
cat << NGINX_EOF > /etc/nginx/conf.d/ssh-ws.conf
server {
    listen 80;
    server_name $DOMAIN;
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

# Python WebSocket Loop
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

echo -e "  [5/6] Opening Firewall Ports..."
iptables -F
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
netfilter-persistent save >/dev/null 2>&1

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
