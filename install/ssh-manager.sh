
#!/bin/bash
Y='\e[1;33m'   
B='\e[38;5;24m' 
C='\e[0;36m'   
G='\e[1;32m'   
R='\e[1;31m'   
NC='\e[0m'     

# Self-Healing Dependency Check for Timed Accounts
if ! command -v at &> /dev/null; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y at > /dev/null 2>&1
    systemctl enable --now atd >/dev/null 2>&1
fi

NS_DOMAIN=$(cat /etc/slowdns/nsdomain 2>/dev/null || echo "Not Configured")
PUB_KEY=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "Not Configured")
LIMIT_DIR="/etc/smartking/limits"
mkdir -p "$LIMIT_DIR"
HOST="te.gregsmarty.co.uk"

while true; do
    clear
    echo -e "${B}────────────────────────────────────────────────────────${NC}"
    echo -e "           ${Y}SSH & OPENVPN CONNECTION MANAGER${NC}"
    echo -e "${B}────────────────────────────────────────────────────────${NC}"
    echo -e ""
    echo -e "    ${C}[01]${G} Create SSH Account${NC}"
    echo -e "    ${C}[02]${G} Generate Trial SSH${NC}"
    echo -e "    ${C}[03]${G} Create Timed SSH (Mins)${NC}"
    echo -e "    ${C}[04]${G} Renew SSH Account${NC}"
    echo -e "    ${C}[05]${G} Delete SSH Account${NC}"
    echo -e "    ${C}[06]${G} Check User Login${NC}"
    echo -e "    ${C}[07]${G} List Member SSH${NC}"
    echo -e "    ${C}[08]${G} Delete Expired Users${NC}"
    echo -e "    ${C}[09]${G} Setup Autokill${NC}"
    echo -e "    ${C}[10]${G} Check Multi-Login${NC}"
    echo -e "    ${C}[11]${G} Security & Lock Manager${NC}"
    echo -e "    ${C}[12]${G} Show OpenVPN Config${NC}"
    echo -e "    ${C}[13]${G} Modify User Login Limit${NC}"
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
            echo -e "               ${Y}CREATE SSH ACCOUNT${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            read -p " Username   : " username
            if id "$username" &>/dev/null; then
                echo -e "\n${R}[!] User '$username' already exists.${NC}"
            else
                read -p " Password   : " password
                read -p " Max Login  : " max_login
                read -p " Expired(Days): " days
                [[ -z "$max_login" ]] && max_login=2
                [[ -z "$days" ]] && days=30
                
                exp_date=$(TZ="Africa/Lagos" date -d "+$days days" +"%b %d, %Y")
                sys_exp=$(TZ="Africa/Lagos" date -d "+$days days" +"%Y-%m-%d")
                
                useradd -e "$sys_exp" -s /bin/false -M "$username"
                echo "$username:$password" | chpasswd
                echo "$max_login" > "$LIMIT_DIR/$username"
                
                MYIP=$(curl -sS ipv4.icanhazip.com || echo "UNKNOWN")
                clear
                echo -e "           ${Y}PREMIUM SSH WS ACCOUNT${NC}"
                echo -e "${B}────────────────────────────────────────────────────────${NC}"
                echo -e "${C}Username      :${G} $username${NC}"
                echo -e "${C}Password      :${G} $password${NC}"
                echo -e "${C}Max Login     :${G} $max_login Connection(s)${NC}"
                echo -e "${C}Expired On    :${G} $exp_date${NC}"
                echo -e "${B}────────────────────────────────────────────────────────${NC}"
                echo -e "             ${Y}SERVER INFORMATION${NC}"
                echo -e "${B}────────────────────────────────────────────────────────${NC}"
                echo -e "${C}IP            :${G} $MYIP${NC}"
                echo -e "${C}Host          :${G} $HOST${NC}"
                echo -e "${C}Nameserver    :${G} $NS_DOMAIN${NC}"
                echo -e "${C}PubKey        :${G} $PUB_KEY${NC}"
                echo -e "${C}OpenSSH       :${G} 22${NC}"
                echo -e "${C}SSH-WS        :${G} 80${NC}"
                echo -e "${C}Custom SSH    :${G} 8880${NC}"
                echo -e "${C}SSH-SSL-WS    :${G} 444${NC}"
                echo -e "${C}Dropbear      :${G} 109, 143${NC}"
                echo -e "${C}SSL/TLS       :${G} 443, 444${NC}"
                echo -e "${C}UDPGW         :${G} 7100-7300${NC}"
                echo -e "${C}SOCKS5        :${G} 1080${NC}"
                echo -e "${C}OVPN TCP      :${G} 1194${NC}"
                echo -e "${B}────────────────────────────────────────────────────────${NC}"
                echo -e "${C}SSH-80        :${G} $HOST:80@$username:$password${NC}"
                echo -e "${C}SSH-8880      :${G} $HOST:8880@$username:$password${NC}"
                echo -e "${C}SSH-443       :${G} $HOST:443@$username:$password${NC}"
                echo -e "${C}SOCKS5        :${G} $HOST:1080@$username:$password${NC}"
                echo -e "${C}HTTP Proxy    :${G} $HOST:8080@$username:$password${NC}"
                echo -e "${B}────────────────────────────────────────────────────────${NC}"
            fi
            ;;
        2|02)
            clear
            trial_user="trial$(tr -dc 0-9 </dev/urandom | head -c 4)"
            trial_pass="pass$(tr -dc 0-9 </dev/urandom | head -c 4)"
            
            exp_date=$(TZ="Africa/Lagos" date -d "+1 day" +"%b %d, %Y")
            sys_exp=$(TZ="Africa/Lagos" date -d "+1 day" +"%Y-%m-%d")
            max_login=1
            
            useradd -e "$sys_exp" -s /bin/false -M "$trial_user"
            echo "$trial_user:$trial_pass" | chpasswd
            echo "$max_login" > "$LIMIT_DIR/$trial_user"
            
            MYIP=$(curl -sS ipv4.icanhazip.com || echo "UNKNOWN")
            clear
            echo -e "           ${Y}PREMIUM TRIAL ACCOUNT${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}Username      :${G} $trial_user${NC}"
            echo -e "${C}Password      :${G} $trial_pass${NC}"
            echo -e "${C}Max Login     :${G} $max_login Connection(s)${NC}"
            echo -e "${C}Expired On    :${G} $exp_date${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}IP            :${G} $MYIP${NC}"
            echo -e "${C}Host          :${G} $HOST${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            ;;
        3|03)
            clear
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "             ${Y}CREATE TIMED SSH ACCOUNT${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            read -p " Username   : " username
            if id "$username" &>/dev/null; then
                echo -e "\n${R}[!] User '$username' already exists.${NC}"
            else
                read -p " Password   : " password
                read -p " Max Login  : " max_login
                read -p " Minutes    : " minutes
                [[ -z "$max_login" ]] && max_login=1
                [[ -z "$minutes" ]] && minutes=10
                
                useradd -s /bin/false -M "$username"
                echo "$username:$password" | chpasswd
                echo "$max_login" > "$LIMIT_DIR/$username"
                
                echo "pkill -u $username ; userdel -f $username ; rm -f $LIMIT_DIR/$username" | at now + $minutes minutes 2>/dev/null
                
                exp_time=$(TZ="UTC" date -d "+$minutes minutes" +"%H:%M UTC (Today)")
                MYIP=$(curl -sS ipv4.icanhazip.com || echo "UNKNOWN")
                
                clear
                echo -e "           ${Y}PREMIUM TIMED SSH ACCOUNT${NC}"
                echo -e "${B}────────────────────────────────────────────────────────${NC}"
                echo -e "${C}Username      :${G} $username${NC}"
                echo -e "${C}Password      :${G} $password${NC}"
                echo -e "${C}Max Login     :${G} $max_login Connection(s)${NC}"
                echo -e "${C}Valid For     :${G} $minutes Minutes${NC}"
                echo -e "${C}Expires At    :${R} $exp_time${NC}"
                echo -e "${B}────────────────────────────────────────────────────────${NC}"
                echo -e "${Y} ⚠️ ACCOUNT WILL SELF-DESTRUCT IN $minutes MINUTES.${NC}"
            fi
            ;;
        4|04)
            clear
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "             ${Y}RENEW SSH ACCOUNT${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}NO   USER            EXPIRES${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            
            i=1
            declare -A user_map
            while read -r user; do
                exp=$(chage -l "$user" | grep "Account expires" | awk -F': ' '{print $2}')
                user_map[$i]="$user"
                printf "${G}%-4s ${C}%-15s ${G}%s${NC}\n" "$i." "$user" "$exp"
                ((i++))
            done < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)
            
            echo -e "${C}0.   Back to Menu${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            read -p " Select Number or Username : " choice
            
            if [[ "$choice" == "0" || "$choice" == "00" ]]; then
                break
            elif [[ -n "${user_map[$choice]}" ]]; then
                username="${user_map[$choice]}"
            else
                username="$choice"
            fi
            
            if id "$username" &>/dev/null; then
                read -p " Additional Days to Add: " days
                [[ -z "$days" ]] && days=30
                sys_exp=$(TZ="Africa/Lagos" date -d "+$days days" +"%Y-%m-%d")
                chage -E "$sys_exp" "$username"
                echo -e "\n${G}[+] Account '$username' renewed successfully until $sys_exp.${NC}"
            else
                echo -e "\n${R}[!] User '$username' not found.${NC}"
            fi
            ;;
        5|05)
            clear
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "             ${Y}DELETE SSH ACCOUNT${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}NO   USER            EXPIRES${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            
            i=1
            declare -A user_map
            while read -r user; do
                exp=$(chage -l "$user" | grep "Account expires" | awk -F': ' '{print $2}')
                user_map[$i]="$user"
                printf "${G}%-4s ${C}%-15s ${G}%s${NC}\n" "$i." "$user" "$exp"
                ((i++))
            done < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)
            
            echo -e "${C}0.   Back to Menu${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            read -p " Select Number or Username : " choice
            
            if [[ "$choice" == "0" || "$choice" == "00" ]]; then
                break
            elif [[ -n "${user_map[$choice]}" ]]; then
                username="${user_map[$choice]}"
            else
                username="$choice"
            fi
            
            if id "$username" &>/dev/null; then
                pkill -u "$username"
                userdel -f "$username"
                rm -f "$LIMIT_DIR/$username"
                echo -e "\n${G}[+] Account '$username' deleted successfully.${NC}"
            else
                echo -e "\n${R}[!] User '$username' not found.${NC}"
            fi
            ;;
        6|06)
            clear
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "             ${Y}CHECK ACTIVE USER LOGIN${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}Scanning for active SSH & Dropbear connections...${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}USERNAME         PID             IP ADDRESS${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            
            active_found=0
            while read -r user pid ip; do
                if [[ -n "$user" && "$user" != "USER" ]]; then
                    printf "${G}%-16s ${C}%-15s ${G}%s${NC}\n" "$user" "$pid" "$ip"
                    active_found=1
                fi
            done < <(ps -eo user,pid,args | grep -E 'sshd:|dropbear' | grep -v grep | awk '{
                user=$1; pid=$2; ip="Local/Unknown";
                for(i=3; i<=NF; i++) {
                    if($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) ip=$i;
                }
                print user, pid, ip;
            }')
            
            if [ "$active_found" -eq 0 ]; then
                echo -e "${R}No active users found.${NC}"
            fi
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            ;;
        7|07)
            clear
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "                  ${Y}LIST MEMBER SSH${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}USERNAME         EXP DATE        STATUS${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            
            total_users=0
            current_epoch=$(date +%s)
            
            while read -r user; do
                exp_raw=$(chage -l "$user" | grep "Account expires" | awk -F': ' '{print $2}')
                if [[ "$exp_raw" == "never" ]]; then
                    exp_date="NEVER"
                    status="${G}ACTIVE${NC}"
                else
                    exp_epoch=$(date -d "$exp_raw" +%s 2>/dev/null || echo "$current_epoch")
                    exp_date=$(date -d "$exp_raw" +"%d-%b-%Y" 2>/dev/null || echo "$exp_raw")
                    if [ "$current_epoch" -gt "$exp_epoch" ]; then
                        status="${R}EXPIRED${NC}"
                    else
                        status="${G}ACTIVE${NC}"
                    fi
                fi
                printf "${C}%-16s ${G}%-15s %b\n" "$user" "$exp_date" "$status"
                ((total_users++))
            done < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)
            
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}TOTAL USERS : ${G}$total_users${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            ;;
        8|08)
            clear
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "               ${Y}DELETE EXPIRED USERS${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "${C}Scanning for expired accounts...${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            
            current_epoch=$(date +%s)
            deleted_count=0
            
            while read -r user; do
                exp_raw=$(chage -l "$user" | grep "Account expires" | awk -F': ' '{print $2}')
                if [[ "$exp_raw" != "never" && -n "$exp_raw" ]]; then
                    exp_epoch=$(date -d "$exp_raw" +%s 2>/dev/null || echo "0")
                    if (( exp_epoch > 0 && current_epoch > exp_epoch )); then
                        echo -e "${C}User : ${R}$user ${C}[EXPIRED]${NC}"
                        pkill -u "$user" 2>/dev/null
                        userdel -f "$user" 2>/dev/null
                        rm -f "$LIMIT_DIR/$user"
                        echo -e "${G}Status: DELETED SUCCESSFULLY${NC}"
                        echo -e "${B}────────────────────────────────────────────────────────${NC}"
                        ((deleted_count++))
                    fi
                fi
            done < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)
            
            if [ "$deleted_count" -eq 0 ]; then
                echo -e "${R}No expired users found.${NC}"
            else
                echo -e "${C}Total Deleted: ${G}$deleted_count users.${NC}"
            fi
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            ;;
        9|09)
            clear
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "               ${Y}AUTOKILL SETUP (SSH)${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            
            if crontab -l 2>/dev/null | grep -q "limit-checker.sh"; then
                ak_status="${G}ACTIVE${NC}"
            else
                ak_status="${R}OFF${NC}"
            fi
            
            echo -e "${C}Current Status: ${ak_status}${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "    ${C}[1]${G} AutoKill Every 3 Minutes (Strict)${NC}"
            echo -e "    ${C}[2]${G} AutoKill Every 5 Minutes${NC}"
            echo -e "    ${C}[3]${G} AutoKill Every 10 Minutes${NC}"
            echo -e "    ${C}[4]${G} Turn Off AutoKill${NC}"
            echo -e "    ${C}[x]${G} Back to Menu${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            read -p " Select Option : " ak_opt
            
            case $ak_opt in
                1)
                    crontab -l 2>/dev/null | grep -v "limit-checker.sh" > /tmp/cron_temp
                    echo "*/3 * * * * /root/my-ssh-manager/limit-checker.sh" >> /tmp/cron_temp
                    crontab /tmp/cron_temp
                    rm -f /tmp/cron_temp
                    echo -e "\n${G}[+] AutoKill set to every 3 minutes.${NC}"
                    ;;
                2)
                    crontab -l 2>/dev/null | grep -v "limit-checker.sh" > /tmp/cron_temp
                    echo "*/5 * * * * /root/my-ssh-manager/limit-checker.sh" >> /tmp/cron_temp
                    crontab /tmp/cron_temp
                    rm -f /tmp/cron_temp
                    echo -e "\n${G}[+] AutoKill set to every 5 minutes.${NC}"
                    ;;
                3)
                    crontab -l 2>/dev/null | grep -v "limit-checker.sh" > /tmp/cron_temp
                    echo "*/10 * * * * /root/my-ssh-manager/limit-checker.sh" >> /tmp/cron_temp
                    crontab /tmp/cron_temp
                    rm -f /tmp/cron_temp
                    echo -e "\n${G}[+] AutoKill set to every 10 minutes.${NC}"
                    ;;
                4)
                    crontab -l 2>/dev/null | grep -v "limit-checker.sh" > /tmp/cron_temp
                    crontab /tmp/cron_temp
                    rm -f /tmp/cron_temp
                    echo -e "\n${R}[+] AutoKill turned off.${NC}"
                    ;;
                *)
                    echo -e "\n${Y}Returning to menu...${NC}"
                    ;;
            esac
            ;;
        10|10)
            clear
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            echo -e "               ${Y}CHECK MULTI-LOGIN (SSH)${NC}"
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            
            while read -r user; do
                limit=$(cat "$LIMIT_DIR/$user" 2>/dev/null || echo "2")
                active=$(ps -u "$user" -o pid= 2>/dev/null | wc -l)
                
                if [ "$active" -gt 0 ]; then
                    if [ "$active" -le "$limit" ]; then
                        echo -e "${C}> ${G}[SAFE]${C} User: ${G}$user${C} is online. Active Logins: ${G}$active${C} | Limit: ${R}$limit${NC}"
                    else
                        echo -e "${C}> ${R}[VIOLATION]${C} User: ${R}$user${C} exceeded limit! Active: ${R}$active${C} | Limit: ${G}$limit${NC}"
                    fi
                fi
            done < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)
            
            echo -e "${B}────────────────────────────────────────────────────────${NC}"
            ;;
        11|11)
            # Shortened for brevity - implement nested lock logic
            echo -e "${G}Security manager accessed.${NC}"
            ;;
        12|12)
            # Shortened for brevity
            echo -e "${G}OpenVPN config view.${NC}"
            ;;
        13|13)
            # Shortened for brevity
            echo -e "${G}Login limit modifier.${NC}"
            ;;
        0|00)
            break
            ;;
        *)
            echo -e "\n${R}[!] Invalid option.${NC}"
            ;;
    esac

    echo ""
    read -n 1 -s -r -p "Press any key to back on menu..."
done
