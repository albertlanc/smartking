#!/bin/bash
Y='\e[1;33m'   # Yellow/Gold
B='\e[38;5;24m' # Deep Blue
C='\e[0;36m'   # Cyan
G='\e[1;32m'   # Green
R='\e[1;31m'   # Red
NC='\e[0m'     # No Color

XRAY_CONF="/etc/xray/config.json"
DB_DIR="/etc/smartking/vless"
mkdir -p "$DB_DIR"
touch "$DB_DIR/users.db"
HOST="te.gregsmarty.co.uk"

clear
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e "                 ${Y}XRAY VLESS MANAGER${NC}"
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e ""
echo -e "    ${C}[01]${G} Create VLESS Account${NC}"
echo -e "    ${C}[02]${G} Generate Trial Account${NC}"
echo -e "    ${C}[03]${G} Create Timed VLESS (Mins)${NC}"
echo -e "    ${C}[04]${G} Extend VLESS Account${NC}"
echo -e "    ${C}[05]${G} Delete VLESS Account${NC}"
echo -e "    ${C}[06]${G} Check User Login${NC}"
echo -e "    ${C}[07]${G} List All VLESS Members${NC}"
echo -e "    ${C}[08]${G} Clean Expired Users${NC}"
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
        echo -e "               ${Y}ADD VLESS ACCOUNT${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        read -p " Username   : " user
        
        if grep -qw "^vless:$user" "$DB_DIR/users.db"; then
            echo -e "\n${R}[!] VLESS User '$user' already exists.${NC}"
        else
            read -p " Expired    : " days
            [[ -z "$days" ]] && days=30
            
            uuid=$(xray uuid)
            exp_date=$(TZ="Africa/Lagos" date -d "+$days days" +"%b %d, %Y")
            sys_exp=$(TZ="Africa/Lagos" date -d "+$days days" +"%Y-%m-%d")
            
            jq '.inbounds |= map(if .protocol == "vless" then .settings.clients += [{"id": "'$uuid'", "level": 0, "email": "'$user'"}] else . end)' $XRAY_CONF > /tmp/xray.json && mv /tmp/xray.json $XRAY_CONF
            cp /etc/xray/config.json /usr/local/etc/xray/config.json
            systemctl restart xray
            
            echo "vless:$user:$uuid:$sys_exp" >> "$DB_DIR/users.db"
            MYIP=$(curl -sS ipv4.icanhazip.com)
            
            v_tls="vless://${uuid}@${HOST}:443?encryption=none&security=tls&type=ws&path=%2Fvless&sni=${HOST}#${user}-TLS"
            v_upg="vless://${uuid}@${HOST}:443?encryption=none&security=none&type=ws&path=%2Fvless#${user}-Upgrade"
            v_notls="vless://${uuid}@${HOST}:80?encryption=none&security=none&type=ws&path=%2Fvless#${user}-NoTLS"
            
            clear
            echo -e "${C}Time Reboot VPS     = Not Set${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "           ${Y}SMARTKING4LUV VPN MANAGER${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}Use Core      :${G} Xray-Core 2023${NC}"
            echo -e "${C}IP-VPS        :${G} $MYIP${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "        ${Y}THANKS FOR USING SMARTKING4LUV AUTOSCRIPT${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "               ${Y}VLESS ACCOUNT CREATED${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}Remarks       :${G} $user${NC}"
            echo -e "${C}Domain        :${G} $HOST${NC}"
            echo -e "${C}User ID       :${G} $uuid${NC}"
            echo -e "${C}Expired On    :${G} $exp_date${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}LINK VLESS TLS (Cloudflare/Standard) :${NC}"
            echo -e "${G}${v_tls}${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}LINK HTTP-UPGRADE (CloudFront Bypass) :${NC}"
            echo -e "${G}${v_upg}${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}LINK NO-TLS (Port 80) :${NC}"
            echo -e "${G}${v_notls}${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
        fi
        ;;
    2|02)
        clear
        trial_user="TRIAL-V-$(tr -dc a-z0-9 </dev/urandom | head -c 4)"
        uuid=$(xray uuid)
        exp_date="24 Hours (Trial)"
        sys_exp=$(TZ="Africa/Lagos" date -d "+1 day" +"%Y-%m-%d")
        
        jq '.inbounds |= map(if .protocol == "vless" then .settings.clients += [{"id": "'$uuid'", "level": 0, "email": "'$trial_user'"}] else . end)' $XRAY_CONF > /tmp/xray.json && mv /tmp/xray.json $XRAY_CONF
        cp /etc/xray/config.json /usr/local/etc/xray/config.json
        systemctl restart xray
        
        echo "vless:$trial_user:$uuid:$sys_exp" >> "$DB_DIR/users.db"
        MYIP=$(curl -sS ipv4.icanhazip.com)
        
        v_tls="vless://${uuid}@${HOST}:443?encryption=none&security=tls&type=ws&path=%2Fvless&sni=${HOST}#${trial_user}-TLS"
        v_upg="vless://${uuid}@${HOST}:443?encryption=none&security=none&type=ws&path=%2Fvless#${trial_user}-Upgrade"
        v_notls="vless://${uuid}@${HOST}:80?encryption=none&security=none&type=ws&path=%2Fvless#${trial_user}-NoTLS"
        
        clear
        echo -e "${C}Time Reboot VPS     = Not Set${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "           ${Y}SMARTKING4LUV VPN MANAGER${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}Use Core      :${G} Xray-Core 2023${NC}"
        echo -e "${C}IP-VPS        :${G} $MYIP${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "        ${Y}THANKS FOR USING SMARTKING4LUV AUTOSCRIPT${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "               ${Y}VLESS TRIAL ACCOUNT CREATED${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}Remarks       :${G} $trial_user${NC}"
        echo -e "${C}Domain        :${G} $HOST${NC}"
        echo -e "${C}User ID       :${G} $uuid${NC}"
        echo -e "${C}Expired On    :${G} $exp_date${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}LINK VLESS TLS :${NC}"
        echo -e "${G}${v_tls}${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}LINK HTTP-UPGRADE (CloudFront Bypass) :${NC}"
        echo -e "${G}${v_upg}${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}LINK NO-TLS :${NC}"
        echo -e "${G}${v_notls}${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        ;;
    3|03)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "             ${Y}CREATE TIMED VLESS ACCOUNT${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        read -p " Username   : " user
        read -p " Minutes    : " minutes
        [[ -z "$minutes" ]] && minutes=10
        
        uuid=$(xray uuid)
        exp_time=$(TZ="UTC" date -d "+$minutes minutes" +"%H:%M UTC")
        MYIP=$(curl -sS ipv4.icanhazip.com)
        
        jq '.inbounds |= map(if .protocol == "vless" then .settings.clients += [{"id": "'$uuid'", "level": 0, "email": "'$user'"}] else . end)' $XRAY_CONF > /tmp/xray.json && mv /tmp/xray.json $XRAY_CONF
        cp /etc/xray/config.json /usr/local/etc/xray/config.json
        systemctl restart xray
        
        echo "jq '.inbounds |= map(if .protocol == \"vless\" then .settings.clients |= map(select(.email != \"$user\")) else . end)' $XRAY_CONF > /tmp/xray.json && mv /tmp/xray.json $XRAY_CONF && cp /etc/xray/config.json /usr/local/etc/xray/config.json && systemctl restart xray" | at now + $minutes minutes 2>/dev/null
        
        v_tls="vless://${uuid}@${HOST}:443?encryption=none&security=tls&type=ws&path=%2Fvless&sni=${HOST}#${user}-Timed"
        v_upg="vless://${uuid}@${HOST}:443?encryption=none&security=none&type=ws&path=%2Fvless#${user}-Upgrade"
        v_notls="vless://${uuid}@${HOST}:80?encryption=none&security=none&type=ws&path=%2Fvless#${user}-NoTLS"
        
        clear
        echo -e "${C}Time Reboot VPS     = Not Set${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "           ${Y}SMARTKING4LUV VPN MANAGER${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}Use Core      :${G} Xray-Core 2023${NC}"
        echo -e "${C}IP-VPS        :${G} $MYIP${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "        ${Y}THANKS FOR USING SMARTKING4LUV AUTOSCRIPT${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "               ${Y}PREMIUM TIMED VLESS ACCOUNT${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}Remarks       :${G} $user${NC}"
        echo -e "${C}Domain        :${G} $HOST${NC}"
        echo -e "${C}User ID       :${G} $uuid${NC}"
        echo -e "${C}Valid For     :${G} $minutes Minutes${NC}"
        echo -e "${C}Expires At    :${G} $exp_time${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}LINK VLESS TLS :${NC}"
        echo -e "${G}${v_tls}${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}LINK HTTP-UPGRADE :${NC}"
        echo -e "${G}${v_upg}${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}LINK NO-TLS :${NC}"
        echo -e "${G}${v_notls}${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${R}⚠️ ACCOUNT WILL SELF-DESTRUCT IN $minutes MINUTES.${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        ;;
    4|04)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                  ${Y}RENEW VLESS USER${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}NO   USER            EXPIRES${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        
        i=1
        declare -A user_map
        while IFS=':' read -r proto user uuid exp; do
            [ -z "$user" ] && continue
            user_map[$i]="$user"
            printf "${G}%-4s ${C}%-15s ${G}%s${NC}\n" "$i." "$user" "$exp"
            ((i++))
        done < "$DB_DIR/users.db"
        
        echo -e "${C}0.   Back to Menu${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        read -p " Select Number or Username : " choice
        
        if [[ "$choice" == "0" ]]; then
            /root/my-ssh-manager/vless-manager.sh
            exit 0
        elif [[ -n "${user_map[$choice]}" ]]; then
            username="${user_map[$choice]}"
        else
            username="$choice"
        fi
        
        if grep -qw "^vless:$username" "$DB_DIR/users.db"; then
            read -p " Additional Days : " days
            [[ -z "$days" ]] && days=30
            current_exp=$(grep "^vless:$username" "$DB_DIR/users.db" | awk -F: '{print $4}')
            
            base_date=$(date +%s)
            if [[ "$current_exp" > "$(date +%Y-%m-%d)" ]]; then
                base_date=$(date -d "$current_exp" +%s)
            fi
            new_exp=$(TZ="Africa/Lagos" date -d "@$base_date +$days days" +"%Y-%m-%d")
            
            sed -i "s/^vless:$username:.*/vless:$username:$(grep "^vless:$username" "$DB_DIR/users.db" | awk -F: '{print $3}'):$new_exp/" "$DB_DIR/users.db"
            echo -e "\n${G}[+] VLESS account '$username' successfully renewed until $new_exp.${NC}"
        else
            echo -e "\n${R}[!] User '$username' not found.${NC}"
        fi
        ;;
    5|05)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                ${Y}DELETE VLESS ACCOUNT${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}NO   USER            EXPIRES${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        
        i=1
        declare -A user_map
        while IFS=':' read -r proto user uuid exp; do
            [ -z "$user" ] && continue
            user_map[$i]="$user"
            printf "${G}%-4s ${C}%-15s ${G}%s${NC}\n" "$i." "$user" "$exp"
            ((i++))
        done < "$DB_DIR/users.db"
        
        echo -e "${C}0.   Back to Menu${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        read -p " Select Number or Username : " choice
        
        if [[ "$choice" == "0" ]]; then
            /root/my-ssh-manager/vless-manager.sh
            exit 0
        elif [[ -n "${user_map[$choice]}" ]]; then
            username="${user_map[$choice]}"
        else
            username="$choice"
        fi
        
        jq '.inbounds |= map(if .protocol == "vless" then .settings.clients |= map(select(.email != "'$username'")) else . end)' $XRAY_CONF > /tmp/xray.json && mv /tmp/xray.json $XRAY_CONF
        cp /etc/xray/config.json /usr/local/etc/xray/config.json
        systemctl restart xray
        sed -i "/^vless:$username:/d" "$DB_DIR/users.db"
        echo -e "\n${G}[+] VLESS account '$username' deleted successfully.${NC}"
        ;;
    6|06)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                 ${Y}VLESS USER ACTIVITY${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}TIME      IP ADDRESS          USER${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        if [ -f /var/log/xray/access.log ]; then
            tail -n 10 /var/log/xray/access.log | grep "/vless" | awk '{print $2, $3, $7}' | awk -F'/' '{print $1, $2, $3}' | awk '{printf "%-9s %-19s %s\n", $1, $2, $3}'
        else
            echo -e "${R}Access log not found.${NC}"
        fi
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${G}* Showing last 10 connections${NC}"
        ;;
    7|07)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                   ${Y}VLESS USER LIST${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}USERNAME         EXP DATE        STATUS${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        
        curr_epoch=$(date +%s)
        while IFS=':' read -r proto user uuid exp; do
            [ -z "$user" ] && continue
            exp_epoch=$(date -d "$exp" +%s 2>/dev/null || echo "$curr_epoch")
            if [ "$curr_epoch" -gt "$exp_epoch" ]; then
                status="${R}Expired${NC}"
            else
                status="${G}Active${NC}"
            fi
            printf "${G}%-16s ${C}%-15s ${G}%b${NC}\n" "$user" "$exp" "$status"
        done < "$DB_DIR/users.db"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        ;;
    8|08)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "               ${Y}CLEAN EXPIRED USERS${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${G}Cleaning expired accounts...${NC}"
        
        curr_epoch=$(date +%s)
        cleaned=0
        while IFS=':' read -r proto user uuid exp; do
            [ -z "$user" ] && continue
            exp_epoch=$(date -d "$exp" +%s 2>/dev/null || echo "0")
            if (( exp_epoch > 0 && curr_epoch > exp_epoch )); then
                jq '.inbounds |= map(if .protocol == "vless" then .settings.clients |= map(select(.email != "'$user'")) else . end)' $XRAY_CONF > /tmp/xray.json && mv /tmp/xray.json $XRAY_CONF
                sed -i "/^vless:$user:/d" "$DB_DIR/users.db"
                ((cleaned++))
            fi
        done < "$DB_DIR/users.db"
        cp /etc/xray/config.json /usr/local/etc/xray/config.json
        systemctl restart xray
        
        echo -e "${G}Cleanup Complete!${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
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
read -n 1 -s -r -p "Press any key to back on menu..."
/root/my-ssh-manager/vless-manager.sh
