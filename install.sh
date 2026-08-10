#!/bin/bash
# Prompt for Domain and Name Server during installation
clear
echo -e "\e[1;36m────────────────────────────────────────────────────────\e[0m"
echo -e "       \e[1;37mCONFIGURING DOMAIN & NAMESERVER SETTINGS\e[0m"
echo -e "\e[1;36m────────────────────────────────────────────────────────\e[0m"

mkdir -p /etc/xray

read -p "Enter your Domain (e.g., te.gregsmarty.co.uk): " DOMAIN
if [ -z "$DOMAIN" ]; then
    DOMAIN="te.gregsmarty.co.uk"
fi
echo "$DOMAIN" > /etc/xray/domain

read -p "Enter your NameServer (e.g., ns-$DOMAIN): " NS_DOMAIN
if [ -z "$NS_DOMAIN" ]; then
    NS_DOMAIN="ns-$DOMAIN"
fi
echo "$NS_DOMAIN" > /etc/xray/nsdomain

echo -e "\e[1;32m[+] Domain and NameServer saved successfully!\e[0m"
