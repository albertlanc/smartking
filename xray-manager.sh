
#!/bin/bash
Y='\e[1;33m'
B='\e[38;5;24m'
C='\e[0;36m'
G='\e[1;32m'
R='\e[1;31m'
NC='\e[0m'

XRAY_CONF="/etc/xray/config.json"
DB_DIR="/etc/smartking/xray"
mkdir -p "$DB_DIR"
touch "$DB_DIR/users.db"
HOST="lance.gregsmarty.co.uk"

# Self-Healing Dependency Check
for pkg in jq at; do
    if ! command -v $pkg &> /dev/null; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y $pkg > /dev/null 2>&1
    fi
done
systemctl enable --now atd >/dev/null 2>&1

clear
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e "                 ${Y}XRAY VMESS MANAGER${NC}"
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e ""
echo -e "    ${C}[01]${G} Create VMess Account${NC}"
echo -e "    ${C}[02]${G} Create Trial Account${NC}"
echo -e "    ${C}[03]${G} Create Timed VMess (Mins)${NC}"
echo -e "    ${C}[04]${G} Extend VMess Account${NC}"
echo -e "    ${C}[05]${G} Delete VMess Account${NC}"
echo -e "    ${C}[06]${G} Check User Login${NC}"
echo -e "    ${C}[07]${G} List VMess Members${NC}"
echo -e "    ${C}[08]${G} Clean Expired Users (Manual)${NC}"
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
        echo -e "               ${Y}ADD VMESS ACCOUNT${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        read -p " Username   : " user
        
        if grep -qw "^vmess:$user" "$DB_DIR/users.db"; then
            echo -e "\n${R}[!] VMess User '$user' already exists.${NC}"
        else
            read -p " Expired    : " days
            [[ -z "$days" ]] && days=30
            
            uuid=$(xray uuid)
            exp_date=$(TZ="Africa/Lagos" date -d "+$days days" +"%b %d, %Y")
            sys_exp=$(TZ="Africa/Lagos" date -d "+$days days" +"%Y-%m-%d")
            
            jq '.inbounds |= map(if .protocol == "vmess" then .settings.clients += [{"id": "'$uuid'", "alterId": 0, "email": "'$user'"}] else . end)' "$XRAY_CONF" > /tmp/xray.json && mv /tmp/xray.json "$XRAY_CONF"
            systemctl restart xray
            
            echo "vmess:$user:$uuid:$sys_exp" >> "$DB_DIR/users.db"
            MYIP=$(curl -sS ipv4.icanhazip.com || echo "UNKNOWN")
            
            t_json="{\"v\":\"2\",\"ps\":\"${user}-TLS\",\"add\":\"${HOST}\",\"port\":\"443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${HOST}\",\"tls\":\"tls\",\"sni\":\"${HOST}\"}"
            u_json="{\"v\":\"2\",\"ps\":\"${user}-Upgrade\",\"add\":\"${HOST}\",\"port\":\"443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${HOST}\",\"tls\":\"tls\"}"
            n_json="{\"v\":\"2\",\"ps\":\"${user}-NoTLS\",\"add\":\"${HOST}\",\"port\":\"80\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${HOST}\",\"tls\":\"none\"}"
            
            t_b64=$(echo -n "$t_json" | base64 -w 0)
            u_b64=$(echo -n "$u_json" | base64 -w 0)
            n_b64=$(echo -n "$n_json" | base64 -w 0)
            
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
            echo -e "               ${Y}VMESS ACCOUNT CREATED${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}Remarks       :${G} $user${NC}"
            echo -e "${C}Domain        :${G} $HOST${NC}"
            echo -e "${C}User ID       :${G} $uuid${NC}"
            echo -e "${C}Expired On    :${G} $exp_date${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}LINK TLS (Cloudflare/Standard) :${NC}"
            echo -e "${G}vmess://${t_b64}${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}LINK HTTP-UPGRADE (CloudFront Bypass) :${NC}"
            echo -e "${G}vmess://${u_b64}${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}LINK NO-TLS (Port 80) :${NC}"
            echo -e "${G}vmess://${n_b64}${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
        fi
        ;;
    2|02)
        clear
        trial_user="TRIAL-$(tr -dc a-z0-9 </dev/urandom | head -c 4)"
        uuid=$(xray uuid)
        exp_date="24 Hours (Trial)"
        sys_exp=$(TZ="Africa/Lagos" date -d "+1 day" +"%Y-%m-%d")
        
        jq '.inbounds |= map(if .protocol == "vmess" then .settings.clients += [{"id": "'$uuid'", "alterId": 0, "email": "'$trial_user'"}] else . end)' "$XRAY_CONF" > /tmp/xray.json && mv /tmp/xray.json "$XRAY_CONF"
        systemctl restart xray
        
        echo "vmess:$trial_user:$uuid:$sys_exp" >> "$DB_DIR/users.db"
        MYIP=$(curl -sS ipv4.icanhazip.com || echo "UNKNOWN")
        
        t_json="{\"v\":\"2\",\"ps\":\"${trial_user}-TLS\",\"add\":\"${HOST}\",\"port\":\"443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${HOST}\",\"tls\":\"tls\",\"sni\":\"${HOST}\"}"
        u_json="{\"v\":\"2\",\"ps\":\"${trial_user}-Upgrade\",\"add\":\"${HOST}\",\"port\":\"443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${HOST}\",\"tls\":\"tls\"}"
        n_json="{\"v\":\"2\",\"ps\":\"${trial_user}-NoTLS\",\"add\":\"${HOST}\",\"port\":\"80\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${HOST}\",\"tls\":\"none\"}"
        
        t_b64=$(echo -n "$t_json" | base64 -w 0)
        u_b64=$(echo -n "$u_json" | base64 -w 0)
        n_b64=$(echo -n "$n_json" | base64 -w 0)
        
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
        echo -e "               ${Y}TRIAL ACCOUNT CREATED${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}Remarks       :${G} $trial_user${NC}"
        echo -e "${C}Domain        :${G} $HOST${NC}"
        echo -e "${C}User ID       :${G} $uuid${NC}"
        echo -e "${C}Expired On    :${G} $exp_date${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}LINK TLS :${NC}"
        echo -e "${G}vmess://${t_b64}${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}LINK HTTP-UPGRADE (CloudFront Bypass) :${NC}"
        echo -e "${G}vmess://${u_b64}${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}LINK NO-TLS :${NC}"
        echo -e "${G}vmess://${n_b64}${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        ;;
    3|03)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "             ${Y}CREATE TIMED VMESS ACCOUNT${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        read -p " Username   : " user
        read -p " Minutes    : " minutes
        [[ -z "$minutes" ]] && minutes=10
        
        uuid=$(xray uuid)
        exp_time=$(TZ="UTC" date -d "+$minutes minutes" +"%H:%M UTC")
        MYIP=$(curl -sS ipv4.icanhazip.com || echo "UNKNOWN")
        
        jq '.inbounds |= map(if .protocol == "vmess" then .settings.clients += [{"id": "'$uuid'", "alterId": 0, "email": "'$user'"}] else . end)' "$XRAY_CONF" > /tmp/xray.json && mv /tmp/xray.json "$XRAY_CONF"
        systemctl restart xray
        
        # ROOT CAUSE FIX: Delete from JSON config, delete from users.db, and restart xray safely in the background
        echo "jq '.inbounds |= map(if .protocol == \"vmess\" then .settings.clients |= map(select(.email != \"$user\")) else . end)' \"$XRAY_CONF\" > /tmp/xray.json && mv /tmp/xray.json \"$XRAY_CONF\" && sed -i '/^vmess:$user:/d' \"$DB_DIR/users.db\" && systemctl restart xray" | at now + $minutes minutes 2>/dev/null
        
        t_json="{\"v\":\"2\",\"ps\":\"${user}-TLS\",\"add\":\"${HOST}\",\"port\":\"443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${HOST}\",\"tls\":\"tls\",\"sni\":\"${HOST}\"}"
        u_json="{\"v\":\"2\",\"ps\":\"${user}-Upgrade\",\"add\":\"${HOST}\",\"port\":\"443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${HOST}\",\"tls\":\"tls\"}"
        n_json="{\"v\":\"2\",\"ps\":\"${user}-NoTLS\",\"add\":\"${HOST}\",\"port\":\"80\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${HOST}\",\"tls\":\"none\"}"
        
        t_b64=$(echo -n "$t_json" | base64 -w 0)
        u_b64=$(echo -n "$u_json" | base64 -w 0)
        n_b64=$(echo -n "$n_json" | base64 -w 0)
        
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
        echo -e "               ${Y}PREMIUM TIMED VMESS ACCOUNT${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}Remarks       :${G} $user${NC}"
        echo -e "${C}Domain        :${G} $HOST${NC}"
        echo -e "${C}User ID       :${G} $uuid${NC}"
        echo -e "${C}Valid For     :${G} $minutes Minutes${NC}"
        echo -e "${C}Expires At    :${G} $exp_time${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}LINK TLS (Cloudflare/Standard) :${NC}"
        echo -e "${G}vmess://${t_b64}${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}LINK HTTP-UPGRADE (CloudFront Bypass) :${NC}"
        echo -e "${G}vmess://${u_b64}${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}LINK NO-TLS (Port 80) :${NC}"
        echo -e "${G}vmess://${n_b64}${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${R}⚠️ ACCOUNT WILL SELF-DESTRUCT IN $minutes MINUTES.${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        ;;
    4|04)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                  ${Y}RENEW VMESS USER${NC}"
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
            /root/my-ssh-manager/xray-manager.sh
            exit 0
        elif [[ -n "${user_map[$choice]}" ]]; then
            username="${user_map[$choice]}"
        else
            username="$choice"
        fi
        
        if grep -qw "^vmess:$username" "$DB_DIR/users.db"; then
            read -p " Additional Days : " days
            [[ -z "$days" ]] && days=30
            current_exp=$(grep "^vmess:$username" "$DB_DIR/users.db" | awk -F: '{print $4}')
            
            base_date=$(date +%s)
            if [[ "$current_exp" > "$(date +%Y-%m-%d)" ]]; then
                base_date=$(date -d "$current_exp" +%s)
            fi
            new_exp=$(TZ="Africa/Lagos" date -d "@$base_date +$days days" +"%Y-%m-%d")
            
            sed -i "s/^vmess:$username:.*/vmess:$username:$(grep "^vmess:$username" "$DB_DIR/users.db" | awk -F: '{print $3}'):$new_exp/" "$DB_DIR/users.db"
            echo -e "\n${G}[+] VMess account '$username' successfully renewed until $new_exp.${NC}"
        else
            echo -e "\n${R}[!] User '$username' not found.${NC}"
        fi
        ;;
    5|05)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                ${Y}DELETE VMESS ACCOUNT${NC}"
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
            /root/my-ssh-manager/xray-manager.sh
            exit 0
        elif [[ -n "${user_map[$choice]}" ]]; then
            username="${user_map[$choice]}"
        else
            username="$choice"
        fi
        
        jq '.inbounds |= map(if .protocol == "vmess" then .settings.clients |= map(select(.email != "'$username'")) else . end)' "$XRAY_CONF" > /tmp/xray.json && mv /tmp/xray.json "$XRAY_CONF"
        systemctl restart xray
        sed -i "/^vmess:$username:/d" "$DB_DIR/users.db"
        echo -e "\n${G}[+] VMess account '$username' deleted successfully.${NC}"
        ;;
    6|06)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                 ${Y}VMESS USER ACTIVITY${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${C}TIME      IP ADDRESS          USER${NC}"
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        if [ -f /var/log/xray/access.log ]; then
            tail -n 10 /var/log/xray/access.log | grep "/vmess" | awk '{print $2, $3, $7}' | awk -F'/' '{print $1, $2, $3}' | awk '{printf "%-9s %-19s %s\n", $1, $2, $3}'
        else
            echo -e "${R}Access log not found.${NC}"
        fi
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "${G}* Showing last 10 connections${NC}"
        ;;
    7|07)
        clear
        echo -e "${B}────────────────────────────────────────────────────────${NC}"
        echo -e "                   ${Y}VMESS USER LIST${NC}"
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
                jq '.inbounds |= map(if .protocol == "vmess" then .settings.clients |= map(select(.email != "'$user'")) else . end)' "$XRAY_CONF" > /tmp/xray.json && mv /tmp/xray.json "$XRAY_CONF"
                sed -i "/^vmess:$user:/d" "$DB_DIR/users.db"
                ((cleaned++))
            fi
        done < "$DB_DIR/users.db"
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
read -n 1 -s -r -p "Press any key to return..."
/root/my-ssh-manager/xray-manager.sh
