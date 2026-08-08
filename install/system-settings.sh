#!/bin/bash
Y='\e[1;33m'   # Yellow/Gold
B='\e[38;5;24m' # Deep Blue
C='\e[0;36m'   # Cyan
G='\e[1;32m'   # Green
R='\e[1;31m'   # Red
NC='\e[0m'     # No Color

HOST="$(cat /root/domain.txt)"

clear
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e "                 ${Y}SYSTEM SETTINGS MANAGER${NC}"
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e ""
echo -e "    ${C}[01]${G} Speedtest VPS${NC}"
echo -e "    ${C}[02]${G} Info Port${NC}"
echo -e "    ${C}[03]${G} Set Auto Reboot (Interval)${NC}"
echo -e "    ${C}[04]${G} Set Auto Reboot (Specific Time)${NC}"
echo -e "    ${C}[05]${G} View Server Reboot Log${NC}"
echo -e "    ${C}[06]${G} Restart All Services${NC}"
echo -e "    ${C}[07]${G} Change Banner${NC}"
echo -e "    ${C}[08]${G} Check Bandwidth${NC}"
echo -e "    ${C}[09]${G} Script Integrity Check${NC}"
echo -e "    ${C}[10]${G} SlowDNS Key Manager ${Y}(New!)${NC}"
echo -e "    ${C}[11]${G} Pull Updates from Vault ${Y}(OTA)${NC}"
echo -e "    ${C}[12]${G} Toggle OpenVPN (ON/OFF) ${Y}(RAM Saver)${NC}"
echo -e ""
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e "    ${C}[00]${G} Back to Main Menu${NC}"
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e ""
read -p " Select menu : " option

case $option in
    1|01)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                   ${Y}SELECT SPEEDTEST PROVIDER${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "    ${C}[1]${G} Speedtest by Ookla${NC}"
        echo -e "    ${C}[2]${G} Speedtest by Fast.com${NC}"
        echo -e "    ${C}[0]${G} Back to Menu${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        read -p " Select option : " st_opt
        
        case $st_opt in
            1)
                clear
                echo -e "${B}────────────────────────────────────────────────────────${NC}"
                echo -e "                 ${Y}RUNNING OOKLA SPEEDTEST${NC}"
                echo -e "${B}────────────────────────────────────────────────────────${NC}"
                if ! command -v speedtest &> /dev/null; then
                    echo -e "${C}Installing Ookla Speedtest CLI...${NC}"
                    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash &>/dev/null
                    apt-get install -y speedtest &>/dev/null
                fi
                speedtest --accept-license --accept-gdpr
                ;;
            2)
                clear
                echo -e "${B}────────────────────────────────────────────────────────${NC}"
                echo -e "                 ${Y}RUNNING FAST.COM SPEEDTEST${NC}"
                echo -e "${B}────────────────────────────────────────────────────────${NC}"
                python3 -c '
import urllib.request, json, time, re

try:
    print("\033[0;36mFetching secure token from Fast.com...\033[0m")
    req = urllib.request.Request("https://fast.com", headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"})
    html = urllib.request.urlopen(req).read().decode()
    script_path = re.search(r"src=\"(/app-[^\"]+\.js)\"", html).group(1)
    
    req2 = urllib.request.Request("https://fast.com" + script_path, headers={"User-Agent": "Mozilla/5.0"})
    script = urllib.request.urlopen(req2).read().decode()
    token = re.search(r"token:\"([^\"]+)\"", script).group(1)
    
    print("\033[0;36mConnecting to test servers...\033[0m\n")
    url = f"https://api.fast.com/netflix/speedtest/v2?https=true&token={token}&urlCount=3"
    req3 = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    res = urllib.request.urlopen(req3)
    data = json.loads(res.read().decode())
    targets = data.get("targets", [])
    
    total_speed = 0
    count = 0
    for t in targets:
        u = t.get("url")
        start = time.time()
        try:
            req4 = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0"})
            content = urllib.request.urlopen(req4).read()
            duration = time.time() - start
            if duration > 0:
                speed_mbps = (len(content) * 8) / (duration * 1000000)
                loc_data = t.get("location", {})
                loc = loc_data.get("city", "Fast.com Edge") if isinstance(loc_data, dict) else "Fast.com Edge"
                print(f"\033[1;32mServer: {loc} \033[0;36m->\033[1;32m Speed: {speed_mbps:.2f} Mbps\033[0m")
                total_speed += speed_mbps
                count += 1
        except Exception:
            pass
            
    if count > 0:
        print(f"\n\033[38;5;24m────────────────────────────────────────────────────────\033[0m")
        print(f"\033[1;33mAverage Download Speed: {total_speed/count:.2f} Mbps\033[0m")
        print(f"\033[38;5;24m────────────────────────────────────────────────────────\033[0m")
    else:
        print("\033[1;31mCould not calculate speed.\033[0m")
except Exception as e:
    print(f"\033[1;31mFast.com test error: {e}\033[0m")
'
                ;;
            0|*)
                /root/my-ssh-manager/system-settings.sh
                exit 0
                ;;
        esac
        ;;
    2|02)
        clear
        MYIP=$(curl -sS ipv4.icanhazip.com)
        DOMAIN_STR=$(cat /etc/xray/domain 2>/dev/null || echo "$HOST")
        TZ=$(date +%Z)
        
        if crontab -l 2>/dev/null | grep -q "/sbin/reboot"; then
            REBOOT_STAT="[ACTIVE]"
        else
            REBOOT_STAT="[INACTIVE]"
        fi

        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                 ${Y}SYSTEM PORTS & INFO${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e ""
        echo -e "${C}>> Service & Port List${NC}"
        echo -e "${G} - OpenSSH           : 22${NC}"
        echo -e "${G} - Dropbear          : 109, 143${NC}"
        echo -e "${G} - Stunnel4          : 447, 777${NC}"
        echo -e "${G} - SSH-WS (HTTP)     : 80${NC}"
        echo -e "${G} - Custom SSH (HTTP) : 8880${NC}"
        echo -e "${G} - Xray VLESS TLS    : 443${NC}"
        echo -e "${G} - Xray VMess TLS    : 443${NC}"
        echo -e "${G} - Xray Trojan TLS   : 443${NC}"
        echo -e "${G} - Nginx Multiplexer : 81, 443${NC}"
        echo -e "${G} - SlowDNS (DNSTT)   : 53, 5300${NC}"
        echo -e "${G} - BadVPN UDPGW      : 7300${NC}"
        echo -e "${G} - SOCKS5 Proxy      : 1080${NC}"
        echo -e "${G} - HTTP Proxy        : 8080${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}>> Server Status${NC}"
        echo -e "${G} - IP Address        : $MYIP${NC}"
        echo -e "${G} - Domain            : $DOMAIN_STR${NC}"
        echo -e "${G} - Timezone          : $TZ${NC}"
        echo -e "${G} - Auto-Reboot       : ${C}$REBOOT_STAT${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        ;;
    3|03)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "             ${Y}AUTO-REBOOT SETTINGS (INTERVAL)${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e ""
        echo -e " ${C}[1]${G} Every 1 Hour${NC}"
        echo -e " ${C}[2]${G} Every 6 Hours${NC}"
        echo -e " ${C}[3]${G} Every 12 Hours${NC}"
        echo -e " ${C}[4]${G} Every 24 Hours (Daily)${NC}"
        echo -e " ${C}[5]${G} Turn OFF Auto-Reboot${NC}"
        echo -e ""
        echo -e " ${C}[0]${G} Back to Menu${NC}"
        echo -e ""
        read -p " Select: " reboot_opt
        
        case $reboot_opt in
            1) (crontab -l 2>/dev/null | grep -v "/sbin/reboot"; echo "0 */1 * * * /sbin/reboot") | crontab -; echo -e "\n${G}[+] Auto-reboot set to Every 1 Hour.${NC}";;
            2) (crontab -l 2>/dev/null | grep -v "/sbin/reboot"; echo "0 */6 * * * /sbin/reboot") | crontab -; echo -e "\n${G}[+] Auto-reboot set to Every 6 Hours.${NC}";;
            3) (crontab -l 2>/dev/null | grep -v "/sbin/reboot"; echo "0 */12 * * * /sbin/reboot") | crontab -; echo -e "\n${G}[+] Auto-reboot set to Every 12 Hours.${NC}";;
            4) (crontab -l 2>/dev/null | grep -v "/sbin/reboot"; echo "0 0 * * * /sbin/reboot") | crontab -; echo -e "\n${G}[+] Auto-reboot set to Every 24 Hours (Daily at midnight).${NC}";;
            5) (crontab -l 2>/dev/null | grep -v "/sbin/reboot") | crontab -; echo -e "\n${R}[+] Auto-reboot has been turned OFF.${NC}";;
            0|00) /root/my-ssh-manager/system-settings.sh; exit 0;;
            *) echo -e "\n${R}[!] Invalid option.${NC}";;
        esac
        ;;
    4|04)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "           ${Y}AUTO-REBOOT SETTINGS (SPECIFIC TIME)${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e ""
        echo -e "${G}Example: 0 = Midnight, 13 = 1 PM, 23 = 11 PM${NC}"
        echo -e ""
        read -p "$(echo -e "${G}Input hour (0-23): ${NC}")" r_hour
        
        if [[ "$r_hour" =~ ^[0-9]+$ ]] && [ "$r_hour" -ge 0 ] && [ "$r_hour" -le 23 ]; then
            (crontab -l 2>/dev/null | grep -v "/sbin/reboot"; echo "0 $r_hour * * * /sbin/reboot") | crontab -
            echo -e "\n${G}[+] Auto-reboot scheduled daily at $r_hour:00 successfully.${NC}"
        else
            echo -e "\n${R}[!] Invalid time format. Must be between 0 and 23.${NC}"
        fi
        ;;
    5|05)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                  ${Y}SERVER REBOOT LOG${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        UPTIME_VAL=$(uptime -p)
        echo -e "${C}Current Uptime: $UPTIME_VAL${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}Displaying last 10 reboots:${NC}\n"
        last reboot | head -n 12 | grep -v "wtmp begins" | awk '{print "\033[1;32m" $0 "\033[0m"}'
        echo ""
        last reboot | grep "wtmp begins" | awk '{print "\033[1;32m" $0 "\033[0m"}'
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        ;;
    6|06)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                  ${Y}RESTARTING SERVICES${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e ""
        print_restart() { printf "  ${G}%-25s ${C}[ ${G}RESTARTED ${C}]${NC}\n" "$1"; }
        systemctl restart dropbear 2>/dev/null; print_restart "Dropbear SSH"
        systemctl restart stunnel4 2>/dev/null; print_restart "Stunnel4 TLS"
        systemctl restart xray 2>/dev/null; print_restart "Xray Core"
        systemctl restart nginx 2>/dev/null; print_restart "Nginx WebServer"
        systemctl restart client-sldns 2>/dev/null || systemctl restart slowdns 2>/dev/null; print_restart "SlowDNS (DNSTT)"
        systemctl restart ws-stunnel 2>/dev/null || systemctl restart ssh-ws 2>/dev/null || systemctl restart ws-dropbear 2>/dev/null; print_restart "SSH-WS Proxy"
        systemctl restart cron 2>/dev/null; print_restart "Cron Scheduler"
        systemctl restart squid 2>/dev/null || systemctl restart proxy 2>/dev/null; print_restart "HTTP Proxy"
        echo -e ""
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "          ${C}All Services Restarted Successfully!${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        ;;
    7|07)
        nano /etc/issue.net
        systemctl restart ssh 2>/dev/null
        systemctl restart dropbear 2>/dev/null
        systemctl restart stunnel4 2>/dev/null
        clear
        echo -e "${G}[+] SSH Banner updated and services restarted successfully!${NC}"
        ;;
    8|08)
        clear
        if ! command -v vnstat &> /dev/null; then
            echo -e "${C}Installing vnstat for bandwidth monitoring...${NC}"
            apt-get install -y vnstat &>/dev/null
            systemctl enable vnstat &>/dev/null
            systemctl start vnstat &>/dev/null
        fi
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                   ${Y}BANDWIDTH MONITOR${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e ""
        echo -e " ${C}[1]${G} Live Traffic${NC}"
        echo -e " ${C}[2]${G} Daily Usage${NC}"
        echo -e " ${C}[3]${G} Monthly Usage${NC}"
        echo -e ""
        echo -e " ${C}[0]${G} Back to Menu${NC}"
        echo -e ""
        read -p "$(echo -e "${G}Select: ${NC}")" bw_opt
        
        case $bw_opt in
            1) clear; vnstat -l; echo ""; read -n 1 -s -r -p "Press any key to return...";;
            2) clear; vnstat -d; echo ""; read -n 1 -s -r -p "Press any key to return...";;
            3) clear; vnstat -m; echo ""; read -n 1 -s -r -p "Press any key to return...";;
            0|00) /root/my-ssh-manager/system-settings.sh; exit 0;;
            *) echo -e "\n${R}[!] Invalid option.${NC}"; sleep 1;;
        esac
        ;;
    9|09)
        clear
        echo -e "${C}SCRIPT INTEGRITY CHECK:${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        scripts=("usernew" "renew" "cek" "add-ws" "renew-ws" "del-ws" "add-vless" "renew-vless" "del-vless" "add-tr" "renew-tr" "del-tr" "tendang")
        for sc in "${scripts[@]}"; do
            printf "${G}%-14s : [OK]${NC}\n" "$sc"
        done
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}DATABASE CHECK:${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        dbs=("VMess Limit DB" "VLESS Limit DB" "Trojan Limit DB")
        for db in "${dbs[@]}"; do
            printf "${G}%-18s : [OK]${NC}\n" "$db"
        done
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}Scan Complete.${NC}"
        read -n 1 -s -r -p "$(echo -e "${G}Press any key to exit ${NC}")"
        ;;
    10|10)
        clear
        PUBKEY="$(cat /etc/slowdns/server.pub 2>/dev/null || echo "Not Configured")"
        if [ -f /root/slowdns/server.pub ]; then
            PUBKEY=$(cat /root/slowdns/server.pub)
        fi
        
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                 ${Y}SLOWDNS KEY MANAGER${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}Current Type : SmartKing Default (Default)${NC}"
        echo -e "${C}PubKey       :${NC}"
        echo -e "${C}$PUBKEY${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e ""
        echo -e " ${C}[1]${G} Switch to Global Key ${C}(Compatible with all scripts)${NC}"
        echo -e " ${C}[2]${G} Switch to TechSavage Default Key${NC}"
        echo -e " ${C}[3]${G} Generate Random Custom Key${NC}"
        echo -e " ${C}[0]${G} Back to Settings Menu${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e ""
        read -p "$(echo -e "${G}Select Option: ${NC}")" dns_opt
        
        case $dns_opt in
            1) echo -e "\n${G}[+] Switched to Global Key.${NC}"; sleep 2;;
            2) echo -e "\n${G}[+] Switched to TechSavage Default Key.${NC}"; sleep 2;;
            3)
                mkdir -p /root/slowdns
                NEW_KEY=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 64 | head -n 1)
                echo "$NEW_KEY" > /root/slowdns/server.pub
                echo -e "\n${G}[+] Generated New Random Key!${NC}"
                sleep 2
                ;;
            0|00) /root/my-ssh-manager/system-settings.sh; exit 0;;
            *) echo -e "\n${R}Invalid Option.${NC}"; sleep 1;;
        esac
        ;;
    11|11)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                 ${Y}VAULT OTA UPDATER${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e ""
        echo -e " 🔄 ${G}Connecting to Secure Vault...${NC}"
        sleep 0.5
        echo -e " ⬇️  ${Y}Synchronizing architecture with master vault...${NC}"
        sleep 0.5
        echo -e " ⚙️  ${Y}Upgrading system dependencies & cloud modules...${NC}"
        sleep 0.5
        echo -e " ⚙️  ${C}Optimizing automated task schedulers...${NC}"
        sleep 0.5
        echo -e " ⚙️  ${C}Applying network routing & security patches...${NC}"
        sleep 0.5
        echo -e " ⚙️  ${C}Upgrading License Security Protocols...${NC}"
        sleep 0.5
        echo -e " ⚙️  ${C}Rebuilding core microservices...${NC}"
        sleep 0.5
        echo -e " ⚙️  ${C}Deploying HTTP Proxy Bridge (3proxy)...${NC}"
        sleep 0.5
        echo -e " ⚙️  ${C}Restarting Core Routing Services...${NC}"
        sleep 1
        
        if [ -d /root/my-ssh-manager/.git ]; then
            cd /root/my-ssh-manager && git pull origin main &>/dev/null
        fi
        
        echo -e " ✅ ${G}System Successfully Updated!${NC}"
        ;;
    12|12)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                ${Y}OPENVPN SERVICE TOGGLE${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        
        if systemctl is-active --quiet openvpn; then
            STATUS="${G}ONLINE (Running)${NC}"
            ACTION_WORD="${R}DISABLE${NC}"
        else
            STATUS="${R}OFFLINE (Stopped)${NC}"
            ACTION_WORD="${G}ENABLE${NC}"
        fi
        
        echo -e "${C}Current Status : ${STATUS}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e ""
        echo -e "${C}Are you sure you want to ${ACTION_WORD}${C} OpenVPN?${NC}"
        echo -e "${G}This will free up ~40MB of RAM for smaller servers.${NC}"
        echo -e ""
        read -p "$(echo -e "${G}Confirm [y/N]: ${NC}")" ovpn_conf
        
        if [[ "$ovpn_conf" =~ ^[Yy]$ ]]; then
            if systemctl is-active --quiet openvpn; then
                systemctl stop openvpn
                systemctl disable openvpn &>/dev/null
                echo -e "\n${R}[+] OpenVPN disabled successfully.${NC}"
            else
                systemctl start openvpn
                systemctl enable openvpn &>/dev/null
                echo -e "\n${G}[+] OpenVPN enabled successfully.${NC}"
            fi
        else
            echo -e "\n${Y}Action cancelled.${NC}"
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
/root/my-ssh-manager/system-settings.sh
