#!/bin/bash
clear
echo -e "\e[1;33m────────────────────────────────────────────────────────\e[0m"
echo -e "       \e[1;33mINSTALLING SMARTKING4LUV ™ VPN MANAGER\e[0m"
echo -e "\e[1;33m────────────────────────────────────────────────────────\e[0m"

echo -e "\e[1;37m[1/6] OS Detection & Dependency Resolution...\e[0m"
# OS Detection
if [ -f /etc/os-release ]; then
    source /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo -e "\e[1;31m[!] Unsupported OS. /etc/os-release not found.\e[0m"
    exit 1
fi

if [[ ! "$OS" =~ ^(ubuntu|debian)$ ]]; then
    echo -e "\e[1;31m[!] This script strictly supports Ubuntu and Debian.\e[0m"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y > /dev/null 2>&1

# Install comprehensive dependencies mapped for Debian/Ubuntu
apt-get install -y git curl wget dropbear nginx python3 iptables iptables-persistent jq socat cron unzip zip > /dev/null 2>&1

echo -e "\e[1;37m[2/6] Fixing OS-Specific Network Conflicts...\e[0m"
# Free Port 53 for SlowDNS on Ubuntu 22/24 and Debian 12/13
if systemctl is-active --quiet systemd-resolved; then
    if grep -q "DNSStubListener=yes" /etc/systemd/resolved.conf 2>/dev/null || grep -q "#DNSStubListener=yes" /etc/systemd/resolved.conf 2>/dev/null; then
        sed -i 's/#DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
        sed -i 's/DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
        systemctl restart systemd-resolved
    fi
fi

# Stop default Nginx from hijacking Port 80
systemctl stop nginx
rm -f /etc/nginx/sites-enabled/default
systemctl disable nginx > /dev/null 2>&1

echo -e "\e[1;37m[3/6] Installing & Configuring Xray Core...\e[0m"
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) install > /dev/null 2>&1
mkdir -p /etc/xray

# Generate a robust, protocol-ready base configuration
cat << 'EOF' > /etc/xray/config.json
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 10085,
      "listen": "127.0.0.1",
      "protocol": "dokodemo-door",
      "settings": { "address": "127.0.0.1" },
      "tag": "api"
    },
    {
      "port": 443,
      "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/xray/xray.crt",
              "keyFile": "/etc/xray/xray.key"
            }
          ]
        },
        "wsSettings": { "path": "/vless" }
      }
    },
    {
      "port": 443,
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/xray/xray.crt",
              "keyFile": "/etc/xray/xray.key"
            }
          ]
        },
        "wsSettings": { "path": "/vmess" }
      }
    },
    {
      "port": 443,
      "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/xray/xray.crt",
              "keyFile": "/etc/xray/xray.key"
            }
          ]
        },
        "wsSettings": { "path": "/trojan" }
      }
    }
  ],
  "outbounds": [ { "protocol": "freedom" } ]
}
EOF

# Create dummy certs so Xray doesn't crash on initial boot before domain-ssl.sh is run
touch /etc/xray/xray.crt /etc/xray/xray.key
chown xray:xray /etc/xray/xray.crt /etc/xray/xray.key 2>/dev/null || chown nobody:nogroup /etc/xray/xray.crt /etc/xray/xray.key
chmod 644 /etc/xray/xray.crt /etc/xray/xray.key

echo -e "\e[1;37m[4/6] Configuring SSH-WS Proxy (Port 8080)...\e[0m"
cat << 'WS' > /usr/local/bin/ws-dropbear
#!/usr/bin/python3
import socket, threading
def handle_client(client_socket):
    try:
        request = client_socket.recv(1024)
        if b"Upgrade: websocket" in request or b"HTTP/1.1" in request:
            client_socket.sendall(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
            server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server_socket.connect(('127.0.0.1', 143))
            def forward(src, dst):
                while True:
                    data = src.recv(4096)
                    if not data: break
                    dst.sendall(data)
            threading.Thread(target=forward, args=(client_socket, server_socket), daemon=True).start()
            forward(server_socket, client_socket)
    except: pass
    finally: client_socket.close()

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', 8080))
    server.listen(100)
    while True:
        client, _ = server.accept()
        threading.Thread(target=handle_client, args=(client,), daemon=True).start()

if __name__ == '__main__': main()
WS
chmod +x /usr/local/bin/ws-dropbear

cat << 'SERVICE' > /etc/systemd/system/ws-dropbear.service
[Unit]
Description=SMARTKING4LUV SSH-WS Proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ws-dropbear
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE

echo -e "\e[1;37m[5/6] Applying BBR Turbo Speed Tweaks...\e[0m"
# Idempotent BBR config
if ! grep -q "net.ipv4.tcp_congestion_control = bbr" /etc/sysctl.conf; then
cat << 'SYS' >> /etc/sysctl.conf
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
SYS
fi
sysctl -p > /dev/null 2>&1

echo -e "\e[1;37m[6/6] Downloading SMARTKING Files & Starting Services...\e[0m"
rm -rf /root/my-ssh-manager
git clone https://github.com/albertlanc/smartking.git /root/my-ssh-manager > /dev/null 2>&1
chmod +x /root/my-ssh-manager/*.sh
cp /root/my-ssh-manager/menu.sh /usr/local/bin/menu
chmod +x /usr/local/bin/menu

systemctl daemon-reload > /dev/null 2>&1
systemctl restart dropbear xray ws-dropbear > /dev/null 2>&1
systemctl enable dropbear xray ws-dropbear > /dev/null 2>&1

echo -e "\n\e[1;32mInstallation Complete!\e[0m"
echo -e "\e[1;37mType \e[1;33mmenu\e[1;37m to launch your dashboard.\e[0m"

