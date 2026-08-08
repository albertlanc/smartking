#!/bin/bash
BLUE='\e[1;34m'
NC='\e[0m'
clear
echo -e "${BLUE}──────────────────────────────────────────────${NC}"
echo -e "          HTTP PROXY STATUS (Port 8080)       "
echo -e "${BLUE}──────────────────────────────────────────────${NC}"
if systemctl is-active --quiet nginx; then 
    echo -e "  Service Status: \e[1;32m● ONLINE\e[0m"
else 
    echo -e "  Service Status: \e[1;31m● OFFLINE\e[0m"
fi
echo -e ""
read -p "Press enter to return..."
menu
