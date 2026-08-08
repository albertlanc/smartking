




#!/bin/bash
B='\e[38;5;24m' # Deep Blue
M='\e[1;35m'   # Magenta
C='\e[0;36m'   # Cyan
G='\e[1;32m'   # Green
R='\e[1;31m'   # Red
NC='\e[0m'     # No Color
clear
echo -e "${B}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${B}║${M}           SYSTEM SETTINGS & AUTO-REBOOT              ${B}║${NC}"
echo -e "${B}╚══════════════════════════════════════════════════════╝${NC}"
echo -e "  ${C}[1]${NC} Set Daily Auto-Reboot Time"
echo -e "  ${C}[2]${NC} Disable Auto-Reboot"
echo -e "  ${C}[3]${NC} Update & Upgrade Server Packages"
echo -e "  ${C}[4]${NC} Clear System Cache (Free up RAM)"
echo -e "  ${C}[5]${NC} Advanced Protocol & Port Changer"
echo -e "  ${C}[0]${NC} Return to Main Menu"
echo -e "${B}╚══════════════════════════════════════════════════════╝${NC}"
read -p " Select Option : " option
case $option in
    1)
        echo -e "\n${B}═══ Configure Daily Auto-Reboot ═══${NC}"
        read -p " Enter Time to Reboot (Format HH:MM, e.g., 03:00): " time_rb
        if [[ "$time_rb" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
            hr=$(echo $time_rb | cut -d: -f1)
            min=$(echo $time_rb | cut -d: -f2)
            crontab -l 2>/dev/null | grep -v "/sbin/reboot" > /tmp/cron_temp
            echo "$min $hr * * * /sbin/reboot" >> /tmp/cron_temp
            crontab /tmp/cron_temp
            rm -f /tmp/cron_temp
            echo -e "${G}[+] Auto-Reboot successfully scheduled for $time_rb every day.${NC}"
        else
            echo -e "${R}[!] Invalid time format. Please use HH:MM (e.g., 04:30).${NC}"
        fi
        ;;
    2)
        echo -e "\n${B}═══ Disable Auto-Reboot ═══${NC}"
        crontab -l 2>/dev/null | grep -v "/sbin/reboot" > /tmp/cron_temp
        crontab /tmp/cron_temp
        rm -f /tmp/cron_temp
        echo -e "${G}[+] Auto-Reboot has been disabled successfully.${NC}"
        ;;
    3)
        clear
        echo -e "${B}═══ Updating Server Packages ═══${NC}"
        apt-get update -y && apt-get upgrade -y
        apt-get autoremove -y && apt-get clean
        echo -e "\n${G}[+] Server update complete!${NC}"
        ;;
    4)
        echo -e "\n${B}═══ Clearing RAM Cache ═══${NC}"
        sync; echo 3 > /proc/sys/vm/drop_caches
        echo -e "${G}[+] System cache cleared. RAM freed up!${NC}"
        ;;
    5)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "               ${M}PROTOCOL & PORT MANAGER${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "  ${C}[1]${NC} Change VMess Protocol Port"
        echo -e "  ${C}[2]${NC} Change VLESS Protocol Port"
        echo -e "  ${C}[3]${NC} Change Trojan Protocol Port"
        echo -e "  ${C}[4]${NC} Change Stunnel (SSL) Port"
        echo -e "  ${C}[5]${NC} Change Dropbear Port"
        echo -e "  ${C}[0]${NC} Back to Settings Menu"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        read -p " Select Protocol : " proto_opt
        case $proto_opt in
            1)
                read -p " Enter New Port for VMess (Internal Backend): " new_vmess
                if [[ "$new_vmess" =~ ^[0-9]+$ ]]; then
                    jq --argjson port "$new_vmess" '.inbounds |= map(if .protocol == "vmess" then .port = $port else . end)' /etc/xray/config.json > /tmp/xray.json && mv /tmp/xray.json /etc/xray/config.json
                    cp /etc/xray/config.json /usr/local/etc/xray/config.json
                    systemctl restart xray
                    sed -i "/proxy_pass http:\/\/127.0.0.1:/ { /vmess/ { n; s/proxy_pass http:\/\/127.0.0.1:[0-9]*/proxy_pass http:\/\/127.0.0.1:$new_vmess/ } }" /etc/nginx/conf.d/xray.conf
                    systemctl restart nginx
                    echo -e "\n${G}[+] VMess internal routing port updated to $new_vmess.${NC}"
                else
                    echo -e "\n${R}[!] Invalid port number.${NC}"
                fi
                ;;
            2)
                read -p " Enter New Port for VLESS (Internal Backend): " new_vless
                if [[ "$new_vless" =~ ^[0-9]+$ ]]; then
                    jq --argjson port "$new_vless" '.inbounds |= map(if .protocol == "vless" then .port = $port else . end)' /etc/xray/config.json > /tmp/xray.json && mv /tmp/xray.json /etc/xray/config.json
                    cp /etc/xray/config.json /usr/local/etc/xray/config.json
                    systemctl restart xray
                    sed -i "/proxy_pass http:\/\/127.0.0.1:/ { /vless/ { n; s/proxy_pass http:\/\/127.0.0.1:[0-9]*/proxy_pass http:\/\/127.0.0.1:$new_vless/ } }" /etc/nginx/conf.d/xray.conf
                    systemctl restart nginx
                    echo -e "\n${G}[+] VLESS internal routing port updated to $new_vless.${NC}"
                else
                    echo -e "\n${R}[!] Invalid port number.${NC}"
                fi
                ;;
            3)
                read -p " Enter New Port for Trojan (Internal Backend): " new_trojan
                if [[ "$new_trojan" =~ ^[0-9]+$ ]]; then
                    jq --argjson port "$new_trojan" '.inbounds |= map(if .protocol == "trojan" then .port = $port else . end)' /etc/xray/config.json > /tmp/xray.json && mv /tmp/xray.json /etc/xray/config.json
                    cp /etc/xray/config.json /usr/local/etc/xray/config.json
                    systemctl restart xray
                    sed -i "/proxy_pass http:\/\/127.0.0.1:/ { /trojan/ { n; s/proxy_pass http:\/\/127.0.0.1:[0-9]*/proxy_pass http:\/\/127.0.0.1:$new_trojan/ } }" /etc/nginx/conf.d/xray.conf
                    systemctl restart nginx
                    echo -e "\n${G}[+] Trojan internal routing port updated to $new_trojan.${NC}"
                else
                    echo -e "\n${R}[!] Invalid port number.${NC}"
                fi
                ;;
            4)
                read -p " Enter New SSL/Stunnel Entry Port (e.g. 443): " new_ssl
                if [[ "$new_ssl" =~ ^[0-9]+$ ]]; then
                    sed -i "/\[ws_443\]/,/connect/ s/accept = .*/accept = $new_ssl/" /etc/stunnel/stunnel.conf
                    systemctl restart stunnel4
                    iptables -A INPUT -p tcp --dport $new_ssl -j ACCEPT
                    netfilter-persistent save >/dev/null 2>&1
                    echo -e "\n${G}[+] Stunnel entry port changed to $new_ssl.${NC}"
                else
                    echo -e "\n${R}[!] Invalid port number.${NC}"
                fi
                ;;
            5)
                read -p " Enter New Dropbear Port : " new_db
                if [[ "$new_db" =~ ^[0-9]+$ ]]; then
                    sed -i "s/DROPBEAR_PORT=.*/DROPBEAR_PORT=$new_db/g" /etc/default/dropbear
                    systemctl restart dropbear
                    iptables -A INPUT -p tcp --dport $new_db -j ACCEPT
                    netfilter-persistent save >/dev/null 2>&1
                    echo -e "\n${G}[+] Dropbear port successfully changed to $new_db.${NC}"
                else
                    echo -e "\n${R}[!] Invalid port number.${NC}"
                fi
                ;;
            *)
                echo -e "\n${R}[!] Returning to settings...${NC}"
                ;;
        esac
        ;;
    0)
        /root/my-ssh-manager/menu.sh
        exit 0
        ;;
    *)
        echo -e "${R}[!] Invalid option.${NC}"
        ;;
esac
echo ""
read -n 1 -s -r -p "Press any key to return..."
/root/my-ssh-manager/settings.sh
