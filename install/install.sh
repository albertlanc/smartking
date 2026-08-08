#!/bin/bash
BLUE='\e[1;34m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
NC='\e[0m'

echo -e "${BLUE}──────────────────────────────────────────────${NC}"
echo -e "${CYAN}     SMARTKING4LUV ™ VPN MANAGER SETUP        ${NC}"
echo -e "${BLUE}──────────────────────────────────────────────${NC}"

echo -e "  ${WHITE}[1/5] Updating System & Installing Dependencies...${NC}"
apt-get update -y >/dev/null 2>&1
apt-get install -y curl wget unzip zip jq nginx >/dev/null 2>&1

echo -e "  ${WHITE}[2/5] Applying BBR Turbo Speed Tweaks...${NC}"
if [ -f "bbr-setup.sh" ]; then
    chmod +x bbr-setup.sh
    ./bbr-setup.sh >/dev/null 2>&1
fi

echo -e "  ${WHITE}[3/5] Setting up Management Directory...${NC}"
mkdir -p /root/my-ssh-manager

echo -e "  ${WHITE}[4/5] Organizing System Files...${NC}"
# Copy all manager scripts into /root/my-ssh-manager/
cp -f *.sh /root/my-ssh-manager/ 2>/dev/null
chmod +x /root/my-ssh-manager/*.sh 2>/dev/null

echo -e "  ${WHITE}[5/5] Finalizing Menu Shortcut...${NC}"
# Copy menu.sh to /usr/local/bin/menu regardless of starting location
if [ -f "menu.sh" ]; then
    cp -f menu.sh /usr/local/bin/menu
elif [ -f "/root/my-ssh-manager/menu.sh" ]; then
    cp -f /root/my-ssh-manager/menu.sh /usr/local/bin/menu
else
    wget -qO /usr/local/bin/menu "https://raw.githubusercontent.com/albertlanc/smartking/main/install/menu.sh"
fi

chmod +x /usr/local/bin/menu

echo -e "\n  ${CYAN}Installation Complete!${NC}"
echo -e "  Type ${WHITE}menu${NC} to launch your dashboard.\n"
echo -e "${BLUE}──────────────────────────────────────────────${NC}"
