#!/bin/bash
Y='\e[1;33m'   # Yellow/Gold
B='\e[38;5;24m' # Deep Blue
C='\e[0;36m'   # Cyan
G='\e[1;32m'   # Green
R='\e[1;31m'   # Red
NC='\e[0m'     # No Color

CONF="/root/my-ssh-manager/tg_backup.conf"
BACKUP_SCRIPT="/root/my-ssh-manager/backup-manager.sh"

# Load Telegram Credentials
if [ -f "$CONF" ]; then
    source "$CONF"
fi

# Function to perform the backup
perform_backup() {
    if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
        echo -e "${R}Telegram credentials not set! Please set them in Option 7.${NC}"
        return 1
    fi
    echo -e "${C}Creating backup archive...${NC}"
    FILE_NAME="Backup_$(date +%Y-%m-%d_%H-%M).zip"
    
    # Zip up Xray, SlowDNS, Smartking databases, and SSH Manager structural files
    zip -r /root/$FILE_NAME /etc/xray /etc/slowdns /etc/smartking /root/my-ssh-manager > /dev/null 2>&1
    
    echo -e "${Y}Sending to Telegram Vault...${NC}"
    curl -s -F document=@"/root/$FILE_NAME" "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" -F chat_id="${CHAT_ID}" -F caption="✅ System Backup: $(date)" > /dev/null
    
    rm -f /root/$FILE_NAME
    echo -e "${G}Backup sent to Telegram successfully!${NC}"
}

# Auto-execute block for cron jobs
if [ "$1" == "--cron" ]; then
    perform_backup
    exit 0
fi

# Check Auto-Backup Status
if crontab -l 2>/dev/null | grep -q "backup-manager.sh --cron"; then
    STAT="${G}[ON]${NC}"
else
    STAT="${R}[OFF]${NC}"
fi

clear
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e "                 ${Y}SYSTEM BACKUP MANAGER${NC}"
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e "${C}Auto-Backup Status: ${STAT}${NC}"
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e "    ${C}[01]${G} Run Manual Backup Now${NC}"
echo -e "    ${C}[02]${G} Set Auto-Backup (Every 12 Hours)${NC}"
echo -e "    ${C}[03]${G} Set Auto-Backup (Every 24 Hours)${NC}"
echo -e "    ${C}[04]${G} Set Auto-Backup (Smart Sync + 12h)${NC}"
echo -e "    ${C}[05]${G} Set Auto-Backup (Smart Sync + 24h)${NC}"
echo -e "    ${C}[06]${G} Turn OFF Auto-Backup${NC}"
echo -e "    ${C}[07]${G} Reset Telegram Credentials${NC}"
echo -e "    ${C}[08]${G} View Current Telegram Credentials${NC}"
echo -e "    ${Y}[09] Restore From Backup${NC}"
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e "    ${R}[00]${G} Back to Main Menu${NC}"
echo -e ""
read -p "$(echo -e "${G}Select menu : ${NC}")" opt

case $opt in
    1|01)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                 ${Y}MANUAL BACKUP${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        perform_backup
        ;;
    2|02)
        (crontab -l 2>/dev/null | grep -v "backup-manager.sh --cron"; echo "0 */12 * * * $BACKUP_SCRIPT --cron") | crontab -
        echo -e "\n${G}[+] Auto-Backup set to Every 12 Hours.${NC}"
        ;;
    3|03)
        (crontab -l 2>/dev/null | grep -v "backup-manager.sh --cron"; echo "0 0 * * * $BACKUP_SCRIPT --cron") | crontab -
        echo -e "\n${G}[+] Auto-Backup set to Every 24 Hours.${NC}"
        ;;
    4|04)
        (crontab -l 2>/dev/null | grep -v "backup-manager.sh --cron"; echo "30 */12 * * * $BACKUP_SCRIPT --cron") | crontab -
        echo -e "\n${G}[+] Smart Sync Backup set to Every 12 Hours.${NC}"
        ;;
    5|05)
        (crontab -l 2>/dev/null | grep -v "backup-manager.sh --cron"; echo "30 2 * * * $BACKUP_SCRIPT --cron") | crontab -
        echo -e "\n${G}[+] Smart Sync Backup set to Every 24 Hours.${NC}"
        ;;
    6|06)
        (crontab -l 2>/dev/null | grep -v "backup-manager.sh --cron") | crontab -
        echo -e "\n${G}[+] Auto-Backup has been turned OFF.${NC}"
        ;;
    7|07)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "               ${Y}TELEGRAM CREDENTIALS${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        read -p " Enter Telegram Bot Token : " in_bot
        read -p " Enter Telegram Chat ID   : " in_chat
        echo "BOT_TOKEN=\"$in_bot\"" > $CONF
        echo "CHAT_ID=\"$in_chat\"" >> $CONF
        echo -e "\n${G}[+] Credentials Saved! Your backups will now go to Telegram.${NC}"
        ;;
    8|08)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "             ${Y}CURRENT TELEGRAM CREDENTIALS${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        if [ -f "$CONF" ]; then
            cat "$CONF" | sed 's/^/  /g'
        else
            echo -e "  ${R}No credentials found. Setup via Option 07.${NC}"
        fi
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        ;;
    9|09)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                 ${Y}RESTORE FROM BACKUP${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}To restore, upload your Backup Zip file to your /root/ folder${NC}"
        echo -e "${C}and rename the file strictly to: ${G}restore.zip${NC}"
        echo -e ""
        read -p " Type 'yes' to proceed with extraction: " conf_res
        if [ "$conf_res" == "yes" ]; then
            if [ -f "/root/restore.zip" ]; then
                echo -e "\n${Y}Extracting backup over existing files...${NC}"
                unzip -o /root/restore.zip -d / > /dev/null 2>&1
                echo -e "${G}Restarting core services...${NC}"
                systemctl restart xray nginx >/dev/null 2>&1
                echo -e "${G}[+] System Restored Successfully!${NC}"
            else
                echo -e "\n${R}[!] restore.zip not found in /root/ directory.${NC}"
            fi
        else
            echo -e "\n${Y}Restore cancelled.${NC}"
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
/root/my-ssh-manager/backup-manager.sh
