#!/bin/bash
# SMARTKING4LUV Concurrent Login Enforcer

LIMIT_DIR="/etc/smartking/limits"

if [ -d "$LIMIT_DIR" ]; then
    for user_file in "$LIMIT_DIR"/*; do
        [ -f "$user_file" ] || continue
        username=$(basename "$user_file")
        max_limit=$(cat "$user_file")
        
        # Check active processes/sessions for this user (SSH, WS, Dropbear, etc.)
        # Count active PIDs belonging to this user
        active_sessions=$(ps -u "$username" -o pid= | wc -l)
        
        if [ "$active_sessions" -gt "$max_limit" ]; then
            # Kill excess processes for this user to enforce the limit
            pkill -u "$username"
        fi
    done
fi
