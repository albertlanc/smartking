#!/bin/bash
GOLD='\e[1;33m'
PURPLE='\e[1;35m'
GREEN='\e[1;32m'
WHITE='\e[1;37m'
RED='\e[1;31m'
NC='\e[0m'

while true; do
    clear
    echo -e "${GOLD}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GOLD}║${PURPLE}           SYSTEM SETTINGS & AUTO-REBOOT              ${GOLD}║${NC}"
    echo -e "${GOLD}╚══════════════════════════════════════════════════════╝${NC}"
    echo -e "${WHITE}  [1] ${GOLD}•${NC} Set Daily Auto-Reboot Time"
    echo -e "${WHITE}  [2] ${GOLD}•${NC} Disable Auto-Reboot"
    echo -e "${WHITE}  [3] ${GOLD}•${NC} Update & Upgrade Server Packages"
    echo -e "${WHITE}  [4] ${GOLD}•${NC} Clear System Cache (Free up RAM)"
    echo -e "${WHITE}  [5] ${GOLD}•${NC} Return to Main Menu"
    echo -e "${GOLD}╚══════════════════════════════════════════════════════╝${NC}"
    read -p " Select Option [ 1 - 5 ]: " option

    case $option in
        1)
            echo -e "\n${GOLD}═══ Configure Daily Auto-Reboot ═══${NC}"
            read -p " Enter Time to Reboot (Format HH:MM, e.g., 03:00): " time_rb
            if [[ "$time_rb" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
                hr=$(echo $time_rb | cut -d: -f1)
                min=$(echo $time_rb | cut -d: -f2)
                # Suppress "no crontab" error on fresh systems
                crontab -l 2>/dev/null | grep -v "/sbin/reboot" > /tmp/cron_temp
                echo "$min $hr * * * /sbin/reboot" >> /tmp/cron_temp
                crontab /tmp/cron_temp
                rm -f /tmp/cron_temp
                echo -e "${GREEN}[+] Auto-Reboot successfully scheduled for $time_rb every day.${NC}"
            else
                echo -e "${RED}[!] Invalid time format. Please use HH:MM (e.g., 04:30).${NC}"
            fi
            ;;
        2)
            echo -e "\n${GOLD}═══ Disable Auto-Reboot ═══${NC}"
            crontab -l 2>/dev/null | grep -v "/sbin/reboot" > /tmp/cron_temp
            crontab /tmp/cron_temp
            rm -f /tmp/cron_temp
            echo -e "${GREEN}[+] Auto-Reboot has been disabled successfully.${NC}"
            ;;
        3)
            clear
            echo -e "${GOLD}═══ Updating Server Packages ═══${NC}"
            # Force non-interactive to prevent the menu from freezing on kernel upgrades
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -y && apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y
            apt-get autoremove -y && apt-get clean
            echo -e "\n${GREEN}[+] Server update complete!${NC}"
            ;;
        4)
            echo -e "\n${GOLD}═══ Clearing RAM Cache ═══${NC}"
            sync; echo 3 > /proc/sys/vm/drop_caches
            echo -e "${GREEN}[+] System cache cleared. RAM freed up!${NC}"
            ;;
        5)
            # Exit loop cleanly to return to the parent menu process
            break
            ;;
        *)
            echo -e "${RED}[!] Invalid option.${NC}"
            ;;
    esac

    echo ""
    read -n 1 -s -r -p "Press any key to return..."
done

