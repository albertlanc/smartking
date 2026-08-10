#!/bin/bash
Y='\e[1;33m'   
B='\e[38;5;24m' 
C='\e[0;36m'   
G='\e[1;32m'   
R='\e[1;31m'   
NC='\e[0m'     

CONF="/root/my-ssh-manager/tg_backup.conf"
BACKUP_SCRIPT="/root/my-ssh-manager/backup-manager.sh"

if [ -f "$CONF" ]; then
    source "$CONF"
fi

perform_backup() {
    if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
        echo -e "${R}Telegram credentials not set! Please set them in Option 7.${NC}"
        return 1
    fi
    echo -e "${C}Creating backup archive...${NC}"
    FILE_NAME="Backup_$(date +%Y-%m-%d_%H-%M).zip"
    
    zip -r /root/$FILE_NAME /etc/xray /etc/slowdns /etc/smartking /root/my-ssh-manager > /dev/null 2>&1
    
    echo -e "${Y}Sending to Telegram Vault...${NC}"
    curl -s -F document=@"/root/$FILE_NAME" "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" -F chat_id="${CHAT_ID}" -F caption="✅ System Backup: $(date)" > /dev/null
    
    rm -f /root/$FILE_NAME
    echo -e "${G}Backup sent to Telegram successfully!${NC}"
}

if [ "$1" == "--cron" ]; then
    perform_backup
    exit 0
fi

while true; do
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
        6|06)
            (crontab -l 2>/dev/null | grep -v "backup-manager.sh --cron") | crontab -
            echo -e "\n${G}[+] Auto-Backup has been turned OFF.${NC}"
            ;;
        0|00)
            break
            ;;
        *)
            echo -e "\n${R}[!] Invalid option.${NC}"
            ;;
    esac

    echo ""
    read -n 1 -s -r -p "Press any key to return..."
done

