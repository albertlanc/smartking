#!/bin/bash
clear
echo -e "\e[1;33m────────────────────────────────────────────────────────\e[0m"
echo -e "       \e[1;33mINSTALLING SMARTKING4LUV ™ VPN MANAGER\e[0m"
echo -e "\e[1;33m────────────────────────────────────────────────────────\e[0m"

echo -e "\e[1;37m[1/6] Updating System & Installing Core Packages...\e[0m"
apt-get update -y > /dev/null 2>&1
apt-get install -y git curl wget dropbear nginx python3 iptables-persistent > /dev/null 2>&1

echo -e "\e[1;37m[2/6] Installing Xray Core Engine...\e[0m"
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) install > /dev/null 2>&1
mkdir -p /etc/xray
[ ! -f /etc/xray/config.json ] && echo '{"log":{"loglevel":"warning"},"inbounds":[{"port":10085,"listen":"127.0.0.1","protocol":"dokodemo-door","settings":{"address":"127.0.0.1"},"tag":"api"}],"outbounds":[{"protocol":"freedom"}]}' > /etc/xray/config.json

echo -e "\e[1;37m[3/6] Configuring SSH-WS Proxy (Port 8080)...\e[0m"
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

echo -e "\e[1;37m[4/6] Applying BBR Turbo Speed Tweaks...\e[0m"
cat << 'SYS' >> /etc/sysctl.conf
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
SYS
sysctl -p > /dev/null 2>&1

echo -e "\e[1;37m[5/6] Downloading SMARTKING Files from GitHub...\e[0m"
rm -rf /root/my-ssh-manager
git clone https://github.com/albertlanc/smartking.git /root/my-ssh-manager > /dev/null 2>&1
chmod +x /root/my-ssh-manager/*.sh

echo -e "\e[1;37m[6/6] Starting All VPN Services...\e[0m"
cp /root/my-ssh-manager/menu.sh /usr/local/bin/menu
chmod +x /usr/local/bin/menu
systemctl daemon-reload > /dev/null 2>&1
systemctl restart nginx dropbear xray ws-dropbear > /dev/null 2>&1
systemctl enable nginx dropbear xray ws-dropbear > /dev/null 2>&1

echo -e "\n\e[1;32mInstallation Complete!\e[0m"
echo -e "\e[1;37mType \e[1;33mmenu\e[1;37m to launch your dashboard.\e[0m"
