#!/bin/bash
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
GREEN='\e[1;32m'
RED='\e[1;31m'
NC='\e[0m'

# Check Whitelist
MY_IP=$(curl -s https://api.ipify.org || curl -s https://ipv4.icanhazip.com)
WHITELIST_URL="https://raw.githubusercontent.com/albertlanc/smartking/main/install/whitelist.txt?v=$(date +%s)"

if ! curl -s "$WHITELIST_URL" | grep -q "$MY_IP"; then
    echo -e "\n${RED}  [!] ACCESS DENIED: UNLICENSED SERVER${NC}"
    echo -e "  Your Server IP : ${GREEN}$MY_IP${NC} is not registered."
    echo -e "  Please contact the developer to purchase a license."
    echo -e "  Telegram       : T.me/SmartKing4Luv\n"
    exit 1
fi

# Helper function for service status
check_service() {
    if systemctl is-active --quiet "$1" 2>/dev/null; then
        echo -e "${GREEN}● ONLINE${NC}"
    else
        echo -e "${RED}● OFFLINE${NC}"
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
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│${NC}                      ${BLUE}SERVICES MATRIX${NC}                       ${BLUE}│${NC}"
echo -e "${BLUE}├────────────────────────────────────────────────────────────┤${NC}"
echo -e "${BLUE}│${NC}  ${MAGENTA}SSH Service${NC}   : $(check_service ssh)                               ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  ${MAGENTA}NGINX Proxy${NC}   : $(check_service nginx)                               ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  ${MAGENTA}XRAY Core${NC}     : $(check_service xray)                               ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  ${MAGENTA}Dropbear${NC}      : $(check_service dropbear)                               ${BLUE}│${NC}"
echo -e "${BLUE}│${NC}  ${MAGENTA}SSH-WS Proxy${NC}  : $(check_service ssh-ws)                               ${BLUE}│${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
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
