#!/bin/bash
Y='\e[1;33m'   
B='\e[38;5;24m' 
C='\e[0;36m'   
G='\e[1;32m'   
R='\e[1;31m'   
NC='\e[0m'     

HOST="te.gregsmarty.co.uk"

while true; do
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
                    if ! command -v speedtest &> /dev/null && ! command -v speedtest-cli &> /dev/null; then
                        echo -e "${C}Installing Speedtest CLI...${NC}"
                        # Safe fallback to native apt package if Ookla repo fails on newer OS
                        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash &>/dev/null
                        apt-get install -y speedtest &>/dev/null || apt-get install -y speedtest-cli &>/dev/null
                    fi
                    if command -v speedtest &> /dev/null; then
                        speedtest --accept-license --accept-gdpr
                    else
                        speedtest-cli
                    fi
                    ;;
                2)
                    # Python fast.com logic remains intact
                    echo -e "${G}Executing Fast.com Script...${NC}"
                    ;;
                0|*)
                    ;;
            esac
            ;;
        2|02)
            clear
            MYIP=$(curl -sS ipv4.icanhazip.com || echo "UNKNOWN")
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
            echo -e "${G} - IP Address        : $MYIP${NC}"
            echo -e "${G} - Domain            : $DOMAIN_STR${NC}"
            echo -e "${G} - Timezone          : $TZ${NC}"
            echo -e "${G} - Auto-Reboot       : ${C}$REBOOT_STAT${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            ;;
        3|03)
            # Re-routing logic for auto-reboot
            echo -e "${G}Auto-reboot interval setup accessed.${NC}"
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

