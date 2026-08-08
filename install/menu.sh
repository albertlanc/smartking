#!/bin/bash
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
GREEN='\e[1;32m'
RED='\e[1;31m'
NC='\e[0m'

MY_IP=$(curl -s https://api.ipify.org || curl -s https://ipv4.icanhazip.com)
WHITELIST_URL="https://raw.githubusercontent.com/albertlanc/smartking/main/install/whitelist.txt?v=$(date +%s)"

if ! curl -s "$WHITELIST_URL" | grep -q "$MY_IP"; then
    echo -e "\n${RED}  [!] ACCESS DENIED: UNLICENSED SERVER${NC}"
    echo -e "  Your Server IP : ${GREEN}$MY_IP${NC} is not registered."
    exit 1
fi

check_service() {
    if systemctl is-active --quiet "$1" 2>/dev/null; then
        printf "${GREEN}● ONLINE ${NC}"
    else
        printf "${RED}● OFFLINE${NC}"
    fi
}

OS_VER=$(lsb_release -ds 2>/dev/null || cat /etc/issue | head -n1)
DATE_NOW=$(date +"%Y-%m-%d %H:%M:%S")
ONLINE_USERS=$(who | wc -l)

clear
echo -e "  ${BLUE}SMARTKING4LUV ™ System Information${NC}"
echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"
echo -e "  ${MAGENTA}OS      :${NC} $OS_VER"
echo -e "  ${MAGENTA}IP      :${NC} $MY_IP"
echo -e "  ${MAGENTA}Time    :${NC} $DATE_NOW"
echo -e "  ${MAGENTA}Users   :${NC} $ONLINE_USERS Online"
echo -e "  ${MAGENTA}Dev     :${NC} T.me/SmartKing4Luv"
echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"
echo -e ""
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│${NC}                      ${BLUE}SERVICES MATRIX${NC}                       ${BLUE}│${NC}"
echo -e "${BLUE}├────────────────────────────────────────────────────────────┤${NC}"
echo -e "${BLUE}│${NC}  ${MAGENTA}SSH Service${NC}   : $(check_service ssh)                               ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  ${MAGENTA}NGINX Proxy${NC}   : $(check_service nginx)                               ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  ${MAGENTA}XRAY Core${NC}     : $(check_service xray)                               ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  ${MAGENTA}Dropbear${NC}      : $(check_service dropbear)                               ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  ${MAGENTA}SSH-WS Proxy${NC}  : $(check_service ssh-ws)                               ${BLUE}│${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo -e ""
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│${NC}                         ${BLUE}MAIN MENU${NC}                          ${BLUE}│${NC}"
echo -e "${BLUE}├────────────────────────────────────────────────────────────┤${NC}"
echo -e "${BLUE}│${NC}  [ ${BLUE}1${NC} ]  SSH & OpenVPN Manager                               ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  [ ${BLUE}2${NC} ]  VMess Manager                                       ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  [ ${BLUE}3${NC} ]  VLESS Manager                                       ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  [ ${BLUE}4${NC} ]  Trojan Manager                                      ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  [ ${BLUE}5${NC} ]  Domain & SSL Manager                                ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  [ ${BLUE}6${NC} ]  HTTP Proxy Status (Port 8080)                       ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  [ ${BLUE}7${NC} ]  System Settings & Auto-Reboot                       ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  [ ${BLUE}8${NC} ]  System Backup Manager                               ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  [ ${BLUE}9${NC} ]  Exit Manager                                        ${BLUE}│${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo -e ""
read -p "Select an Option [ 1 - 9 ] : " option

case $option in
    1) bash /root/my-ssh-manager/ssh-manager.sh ;;
    2) bash /root/my-ssh-manager/vmess-manager.sh ;;
    3) bash /root/my-ssh-manager/vless-manager.sh ;;
    4) bash /root/my-ssh-manager/trojan-manager.sh ;;
    5) bash /root/my-ssh-manager/domain-ssl.sh ;;
    6) bash /root/my-ssh-manager/proxy-status.sh ;;
    7) bash /root/my-ssh-manager/system-settings.sh ;;
    8) bash /root/my-ssh-manager/backup-manager.sh ;;
    9) clear; exit 0 ;;
    *) echo -e "${RED}Invalid option!${NC}"; sleep 1; menu ;;
esac
