#!/bin/bash
Y='\e[1;33m'   # Bold Gold
W='\e[1;37m'   # Bold Bright White
R='\e[1;31m'   # Bold Red
NC='\e[0m'     # No Color

# ==========================================
# 🔒 ADVANCED IP WHITELIST LICENSING SYSTEM
# ==========================================
SERVER_IP=$(curl -sS ipv4.icanhazip.com || hostname -I | awk '{print $1}')
MASTER_IP="104.105.205.88" # Developer IP
WHITELIST_URL="https://raw.githubusercontent.com/albertlanc/smartking/main/install/whitelist.txt"

if [ "$SERVER_IP" != "$MASTER_IP" ]; then
    VALID_IP=$(curl -sS "$WHITELIST_URL" 2>/dev/null | grep -w "$SERVER_IP")
    if [ -z "$VALID_IP" ]; then
        clear
        echo -e "${R}────────────────────────────────────────────────────────${NC}"
        echo -e "          ${R}[!] ACCESS DENIED: UNLICENSED SERVER${NC}          "
        echo -e "${R}────────────────────────────────────────────────────────${NC}"
        echo -e "\n  ${W}Your Server IP :${NC} ${Y}$SERVER_IP${NC} is not registered."
        echo -e "  ${W}Please contact the developer to purchase a license.${NC}"
        echo -e "  ${W}Telegram       :${NC} ${Y}T.me/SmartKing4Luv${NC}\n"
        echo -e "${R}────────────────────────────────────────────────────────${NC}"
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

while true; do
    clear
    
    OS_VER=$(source /etc/os-release && echo "$PRETTY_NAME")
    GEO_INFO=$(curl -s "http://ip-api.com/json/$SERVER_IP" 2>/dev/null)
    if echo "$GEO_INFO" | grep -q "success"; then
        CITY=$(echo "$GEO_INFO" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
        COUNTRY=$(echo "$GEO_INFO" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
        LOC_STR="$CITY, $COUNTRY"
    else
        LOC_STR="Unknown Location"
    fi
    CUR_DATE=$(date "+%Y-%m-%d")
    CUR_TIME=$(date "+%H:%M:%S")
    ACTIVE_USERS=$(who | awk '{print $1}' | sort -u | wc -l | tr -d ' \n\r')

    echo -e "${Y}────────────────────────────────────────────────────────${NC}"
    echo -e "         ${Y}SMARTKING4LUV ™ System Information${NC}"
    echo -e "${Y}────────────────────────────────────────────────────────${NC}"
    echo -e "  ${Y}System OS     :${W} $OS_VER${NC}"
    echo -e "  ${Y}Server IP     :${W} $SERVER_IP ($LOC_STR)${NC}"
    echo -e "  ${Y}Date / Time   :${W} $CUR_DATE | $CUR_TIME${NC}"
    echo -e "  ${Y}Active Users  :${W} $ACTIVE_USERS User(s) Online${NC}"
    echo -e "  ${Y}Developer     :${W} T.me/SmartKing4Luv${NC}"

    SSH_USERS=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l | tr -d ' \n\r')
    VMESS_USERS=$(grep -c "vmess" /etc/xray/config.json 2>/dev/null || echo "0" | tr -d ' \n\r')
    VLESS_USERS=$(grep -c "vless" /etc/xray/config.json 2>/dev/null || echo "0" | tr -d ' \n\r')
    TROJAN_USERS=$(grep -c "trojan" /etc/xray/config.json 2>/dev/null || echo "0" | tr -d ' \n\r')

    STS_SSH=$(chk_svc ssh)
    STS_NGINX=$(chk_svc nginx)
    STS_XRAY=$(chk_svc xray)
    STS_DROPBEAR=$(chk_svc dropbear)
    STS_WS=$(chk_svc ws-dropbear)

    # Perfect Aligned Protocol Box
    echo -e "${Y}┌──────────────────────────────────────────────────────┐${NC}"
    printf "${Y}│${NC}  ${Y}SSH:${W}%-2s  ${Y}VMESS:${W}%-2s  ${Y}VLESS:${W}%-2s  ${Y}TROJAN:${W}%-2s      ${Y}│${NC}\n" "$SSH_USERS" "$VMESS_USERS" "$VLESS_USERS" "$TROJAN_USERS"
    echo -e "${Y}└──────────────────────────────────────────────────────┘${NC}"

    # Perfect Aligned Services Box
    echo -e "${Y}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${Y}│${NC}   ${Y}SSH${NC} : ${STS_SSH}        ${Y}NGINX${NC} : ${STS_NGINX}         ${Y}XRAY${NC} : ${STS_XRAY}    ${Y}│${NC}"
    echo -e "${Y}│${NC}        ${Y}DROPBEAR${NC} : ${STS_DROPBEAR}        ${Y}SSH-WS${NC} : ${STS_WS}            ${Y}│${NC}"
    echo -e "${Y}└──────────────────────────────────────────────────────┘${NC}"

    echo -e "           ${Y}SMARTKING4LUV™ POWERFUL VPN MANAGER${NC}"
    echo -e "${Y}────────────────────────────────────────────────────────${NC}"
    echo -e ""
    
    echo -e "     ${Y}[ 1 ]${NC}  ${W}SSH & OpenVPN Manager${NC}"
    echo -e "     ${Y}[ 2 ]${NC}  ${W}VMess Manager${NC}"
    echo -e "     ${Y}[ 3 ]${NC}  ${W}VLESS Manager${NC}"
    echo -e "     ${Y}[ 4 ]${NC}  ${W}Trojan Manager${NC}"
    echo -e "     ${Y}[ 5 ]${NC}  ${W}Domain & SSL Manager${NC}"
    echo -e "     ${Y}[ 6 ]${NC}  ${W}HTTP Proxy Status (Port 8080)${NC}"
    echo -e "     ${Y}[ 7 ]${NC}  ${W}System Settings & Auto-Reboot${NC}"
    echo -e "     ${Y}[ 8 ]${NC}  ${W}System Backup Manager${NC}"
    echo -e "     ${Y}[ 9 ]${NC}  ${W}Exit Manager${NC}"
    echo -e ""
    echo -e "${Y}────────────────────────────────────────────────────────${NC}"
    
    echo -ne "  ${W}Select an Option ${Y}[ 1 - 9 ]${W} : ${NC}"
    read option
    
    case $option in
        1|01) [ -f /root/my-ssh-manager/ssh-manager.sh ] && /root/my-ssh-manager/ssh-manager.sh || { clear; echo -e "${W}[!] ssh-manager.sh missing.${NC}"; sleep 1; } ;;
        2|02) [ -f /root/my-ssh-manager/xray-manager.sh ] && /root/my-ssh-manager/xray-manager.sh || { clear; echo -e "${W}[!] xray-manager.sh missing.${NC}"; sleep 1; } ;;
        3|03) [ -f /root/my-ssh-manager/vless-manager.sh ] && /root/my-ssh-manager/vless-manager.sh || { clear; echo -e "${W}[!] vless-manager.sh missing.${NC}"; sleep 1; } ;;
        4|04) [ -f /root/my-ssh-manager/trojan-manager.sh ] && /root/my-ssh-manager/trojan-manager.sh || { clear; echo -e "${W}[!] trojan-manager.sh missing.${NC}"; sleep 1; } ;;
        5|05) /root/my-ssh-manager/domain-ssl.sh ;;
        6|06) /root/my-ssh-manager/http-proxy.sh ;;
        7|07) /root/my-ssh-manager/system-settings.sh ;;
        8|08) /root/my-ssh-manager/backup-manager.sh ;;
        9|09) clear; exit 0 ;;
        *) echo -e "\n${W}[!] Invalid option selected.${NC}"; sleep 1 ;;
    esac
done
