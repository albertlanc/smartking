#!/bin/bash
Y='\e[1;33m'   # Yellow/Gold
B='\e[38;5;24m' # Deep Blue
C='\e[0;36m'   # Cyan
G='\e[1;32m'   # Green
R='\e[1;31m'   # Red
NC='\e[0m'     # No Color

clear
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e "             ${Y}HTTP PROXY STATUS (PORT 8080)${NC}"
echo -e "${B}────────────────────────────────────────────────────────${NC}"
echo -e ""

# Check if port 8080 is listening
if netstat -tulpen 2>/dev/null | grep -q ":8080 "; then
    # Extract the name of the service running on 8080
    SVC=$(netstat -tulpen 2>/dev/null | grep ":8080 " | awk '{print $9}' | cut -d'/' -f2 | head -n 1)
    if [ -z "$SVC" ]; then SVC="Unknown/Proxy"; fi
    
    echo -e "  ${C}Proxy Service : ${G}ONLINE ($SVC)${NC}"
    echo -e "  ${C}Port          : ${G}8080${NC}"
    
    # Count established connections to port 8080
    CONN=$(netstat -anp 2>/dev/null | grep ":8080 " | grep ESTABLISHED | wc -l)
    echo -e "  ${C}Live Users    : ${G}$CONN Connection(s)${NC}"
else
    echo -e "  ${C}Proxy Service : ${R}OFFLINE${NC}"
    echo -e "  ${C}Port          : ${R}8080${NC}"
    echo -e "  ${C}Live Users    : ${R}0 Connection(s)${NC}"
fi

echo -e ""
echo -e "${B}────────────────────────────────────────────────────────${NC}"
read -n 1 -s -r -p "$(echo -e "${G}Press any key to return to Main Menu...${NC}")"
/root/my-ssh-manager/menu.sh
