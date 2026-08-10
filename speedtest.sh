#!/bin/bash
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
NC='\e[0m'
clear
echo -e "${BLUE}──────────────────────────────────────────────${NC}"
echo -e "             ${MAGENTA}SYSTEM SPEEDTEST${NC}                 "
echo -e "${BLUE}──────────────────────────────────────────────${NC}"
echo -e "  [1] Run Ookla Speedtest"
echo -e "  [2] Run Fast.com Speedtest"
echo -e "  [0] Back to Menu"
echo -e "${BLUE}──────────────────────────────────────────────${NC}"
read -p " Select Option : " st_opt

case $st_opt in
    1) 
        clear
        echo -e "${BLUE}──────────────────────────────────────────────${NC}"
        echo -e "           RUNNING OOKLA SPEEDTEST            "
        echo -e "${BLUE}──────────────────────────────────────────────${NC}"
        if command -v speedtest-cli &> /dev/null; then
            speedtest-cli --bytes
        else
            echo "Error: speedtest-cli is not installed."
        fi
        ;;
    2) 
        clear
        echo -e "${BLUE}──────────────────────────────────────────────${NC}"
        echo -e "          RUNNING FAST.COM SPEEDTEST          "
        echo -e "${BLUE}──────────────────────────────────────────────${NC}"
        if command -v fast &> /dev/null; then
            fast
        else
            echo "Error: fast is not installed."
        fi
        ;;
    0) menu ;;
    *) echo "Invalid Option"; sleep 1; bash speedtest.sh ;;
esac

echo ""
read -p "Press enter to return..."
menu
