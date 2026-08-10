#!/bin/bash
Y='\e[1;33m'   # Yellow/Gold
B='\e[38;5;24m' # Deep Blue
C='\e[0;36m'   # Cyan
G='\e[1;32m'   # Green
R='\e[1;31m'   # Red
NC='\e[0m'     # No Color

clear

# Fetch current domain & NS. Fallback to default if not set yet.
domain=$(cat /etc/xray/domain 2>/dev/null)
if [ -z "$domain" ]; then domain="xe.gregsmarty.co.uk"; fi

nsdomain=$(cat /etc/slowdns/nsdomain 2>/dev/null)
if [ -z "$nsdomain" ]; then nsdomain="ns-xe.gregsmarty.co.uk"; fi

echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e "                 ${Y}DOMAIN & SSL MANAGER${NC}"
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e "${C}Current Domain : ${G}$domain${NC}"
echo -e "${C}Current NS     : ${G}$nsdomain${NC}"
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e "    ${C}[01]${G} Change VPS Domain (Host)${NC}"
echo -e "    ${C}[02]${G} Change NameServer (SlowDNS NS)${NC}"
echo -e "    ${C}[03]${G} Force Renew SSL Certificate ${Y}(Crucial!)${NC}"
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e "    ${C}[00]${G} Back to Main Menu${NC}"
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e ""
read -p " Select menu : " option

case $option in
    1|01)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "               ${Y}CHANGE VPS DOMAIN${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        read -p " Enter New Domain : " new_domain
        if [ -n "$new_domain" ]; then
            mkdir -p /etc/xray
            echo "$new_domain" > /etc/xray/domain
            echo -e "\n${G}[+] Domain successfully updated to: $new_domain${NC}"
        else
            echo -e "\n${R}[!] Operation cancelled.${NC}"
        fi
        ;;
    2|02)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "               ${Y}CHANGE NAMESERVER${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        read -p " Enter New NameServer : " new_ns
        if [ -n "$new_ns" ]; then
            mkdir -p /etc/slowdns
            echo "$new_ns" > /etc/slowdns/nsdomain
            echo -e "\n${G}[+] NameServer successfully updated to: $new_ns${NC}"
        else
            echo -e "\n${R}[!] Operation cancelled.${NC}"
        fi
        ;;
    3|03)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "               ${Y}FORCE RENEW SSL CERTIFICATE${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}Stopping web services to free up port 80...${NC}"
        systemctl stop nginx 2>/dev/null
        systemctl stop xray 2>/dev/null
        
        # Ensure Port 80 is strictly clear for acme standalone
        fuser -k 80/tcp > /dev/null 2>&1
        
        echo -e "${Y}Generating SSL Certificate for $domain...${NC}"
        mkdir -p /root/.acme.sh
        curl -s https://get.acme.sh | sh &>/dev/null
        /root/.acme.sh/acme.sh --upgrade --auto-upgrade &>/dev/null
        /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt &>/dev/null
        /root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 --force
        /root/.acme.sh/acme.sh --installcert -d "$domain" --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc --force
        
        # ROOT CAUSE FIX: Grant the Xray unprivileged user read access to the new certificates
        if id "xray" &>/dev/null; then
            chown xray:xray /etc/xray/xray.crt /etc/xray/xray.key
        elif id "nobody" &>/dev/null; then
            chown nobody:nogroup /etc/xray/xray.crt /etc/xray/xray.key
        fi
        chmod 644 /etc/xray/xray.crt /etc/xray/xray.key
        
        echo -e "\n${C}Restarting services...${NC}"
        # We do not restart nginx if it is not explicitly configured as a proxy to avoid Port 80 clashes
        systemctl start xray 2>/dev/null
        
        if [ -s /etc/xray/xray.crt ]; then
            echo -e "${G}[+] SSL Certificate Renewed Successfully and assigned to Xray!${NC}"
        else
            echo -e "${R}[!] SSL Certificate Renewal Failed. Check if Domain is pointing to VPS IP.${NC}"
        fi
        ;;
    0|00)
        /root/my-ssh-manager/menu.sh
        exit 0
        ;;
    *)
        echo -e "\n${R}[!] Invalid option.${NC}"
        ;;
esac

echo ""
read -n 1 -s -r -p "Press any key to return..."
/root/my-ssh-manager/domain-ssl.sh

