#!/bin/bash
# SMARTKING4LUV Concurrent Login Enforcer

LIMIT_DIR="/etc/smartking/limits"

if [ -d "$LIMIT_DIR" ]; then
    for user_file in "$LIMIT_DIR"/*; do
        [ -f "$user_file" ] || continue
        username=$(basename "$user_file")
        
        # Verify the user actually exists in the OS to prevent ghost-user errors
        if ! id "$username" &>/dev/null; then
            rm -f "$user_file"
            continue
        fi
        
        max_limit=$(cat "$user_file")
        
        # Ensure the limit is a valid integer to prevent bash syntax crashes
        if [[ ! "$max_limit" =~ ^[0-9]+$ ]]; then 
            continue 
        fi
        
        # Count active PIDs belonging to this user
        active_sessions=$(ps -u "$username" -o pid= 2>/dev/null | wc -l)
        
        if [ "$active_sessions" -gt "$max_limit" ]; then
            # Kill excess processes for this user to enforce the limit
            pkill -u "$username"
        fi
    done
fi

