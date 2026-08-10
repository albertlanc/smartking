
#!/bin/bash
CYAN='\e[1;36m'
W='\e[1;37m'
R='\e[1;31m'
NC='\e[0m'

SERVER_IP=$(curl -sS --max-time 3 ipv4.icanhazip.com || hostname -I | awk '{print $1}')
MASTER_IP="104.105.205.88"
WHITELIST_URL="https://raw.githubusercontent.com/albertlanc/smartking/main/whitelist.txt"

if [ "$SERVER_IP" != "$MASTER_IP" ]; then
    # Added a 5-second timeout so the server doesn't freeze if GitHub is unreachable
    VALID_IP=$(curl -sS --max-time 5 "$WHITELIST_URL" 2>/dev/null | grep -w "$SERVER_IP")
    if [ -z "$VALID_IP" ]; then
        clear
        echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
        echo -e "          ${R}[!] ACCESS DENIED: UNLICENSED SERVER${NC}          "
        echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
        echo -e "\n  ${W}Your Server IP :${NC} ${CYAN}$SERVER_IP${NC} is not registered."
        echo -e "  ${W}Please contact the developer to purchase a license.${NC}"
        echo -e "  ${W}Telegram       :${NC} ${CYAN}T.me/SmartKing4Luv${NC}\n"
        echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
        exit 1
    fi
fi

chk_svc() {
    if systemctl is-active --quiet $1 2>/dev/null; then
        echo -e "${W}ON ${NC}"
    else
        echo -e "${W}OFF${NC}"
    fi
}

# Helper function to safely execute sub-menus
run_script() {
    local script_path="/root/my-ssh-manager/$1"
    if [ -f "$script_path" ]; then
        bash "$script_path"
    else
        clear
        echo -e "${R}[!] Error: Module '$1' is missing or deleted.${NC}"
        sleep 2
    fi
}

while true; do
    clear
    DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "No Domain Set")
    NS_DOMAIN=$(cat /etc/xray/nsdomain 2>/dev/null || echo "ns-$DOMAIN")

    echo -e "${CYAN}Scripted & Programged By Albert Tech Inc${NC}"
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}                    ${CYAN}SYSTEM INFO${NC}                       ${CYAN}│${NC}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}  ${W}OS:          ${NC} ${OS_VER}"
    echo -e "${CYAN}│${NC}  ${W}Domain:      ${NC} ${CYAN}$DOMAIN${NC}"
    echo -e "${CYAN}│${NC}  ${W}Name Server: ${NC} ${CYAN}$NS_DOMAIN${NC}"
    echo -e "${CYAN}│${NC}  ${W}Time:        ${NC} ${W}$CUR_DATE $CUR_TIME${NC}"
    echo -e "${CYAN}│${NC}  ${W}Users:       ${NC} ${CYAN}$ACTIVE_USERS Connected${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    echo -e ""
    OS_VER=$(grep -E '^(PRETTY_NAME)=' /etc/os-release | cut -d'"' -f2)
    GEO_INFO=$(curl -sS --max-time 3 "http://ip-api.com/json/$SERVER_IP" 2>/dev/null)
    
    if echo "$GEO_INFO" | grep -q "success"; then
        CITY=$(echo "$GEO_INFO" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
        COUNTRY=$(echo "$GEO_INFO" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
        LOC_STR="$CITY, $COUNTRY"
    else
        LOC_STR="Unknown Location"
    fi
    
    CUR_DATE=$(date "+%Y-%m-%d")
    CUR_TIME=$(date "+%H:%M:%S")
    ACTIVE_USERS=$(who | awk '{print $1}' | sort -u | wc -l | tr -d '[:space:]')
    
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}                      ${CYAN}MAIN MENU${NC}                      ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    echo -e ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}1${NC}  ${CYAN}│${NC}  ${W}SSH & OpenVPN Manager${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}2${NC}  ${CYAN}│${NC}  ${W}VMess Manager${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}3${NC}  ${CYAN}│${NC}  ${W}VLESS Manager${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}4${NC}  ${CYAN}│${NC}  ${W}Trojan Manager${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}5${NC}  ${CYAN}│${NC}  ${W}Domain & SSL Manager${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}6${NC}  ${CYAN}│${NC}  ${W}HTTP Proxy Status (Port 8080)${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}7${NC}  ${CYAN}│${NC}  ${W}System Settings & Auto-Reboot${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}8${NC}  ${CYAN}│${NC}  ${W}System Backup Manager${NC}"
    echo -e "${CYAN}│${NC}  ${CYAN}9${NC}  ${CYAN}│${NC}  ${W}Exit Manager${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    echo -e ""
    echo -ne "${CYAN}Select an option : ${NC}"
    read option
    
    case $option in
        1|01) run_script "ssh-manager.sh" ;;
        2|02) run_script "xray-manager.sh" ;;
        3|03) run_script "vless-manager.sh" ;;
        4|04) run_script "trojan-manager.sh" ;;
        5|05) run_script "domain-ssl.sh" ;;
        6|06) run_script "http-proxy.sh" ;;
        7|07) run_script "system-settings.sh" ;;
        8|08) run_script "backup-manager.sh" ;;
        9|09) clear; exit 0 ;;
        *) echo -e "\n${R}[!] Invalid option selected.${NC}"; sleep 1 ;;
    esac
done
