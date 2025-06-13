#!/bin/bash

set -e

usage() {
    echo "Usage: $0 -h <host> -u <user> [-p <password>] [-k <ssh_key>]"
    echo "  -h <host>       Nexus switch hostname or IP"
    echo "  -u <user>       SSH username"
    echo "  -p <password>   SSH password (if not using key)"
    echo "  -k <ssh_key>    Path to SSH private key (optional)"
    exit 1
}

while getopts ":h:u:p:k:" opt; do
  case $opt in
    h) HOST="$OPTARG" ;;
    u) USER="$OPTARG" ;;
    p) PASSWORD="$OPTARG" ;;
    k) SSH_KEY="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$HOST" || -z "$USER" ]]; then
    usage
fi

REMOTE_CMD="show running-config"

if [[ -n "$SSH_KEY" ]]; then
    # SSH key authentication
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$USER@$HOST" "$REMOTE_CMD"
elif [[ -n "$PASSWORD" ]]; then
    # Password authentication (requires sshpass)
    if ! command -v sshpass >/dev/null 2>&1; then
        echo "Error: sshpass is required for password authentication." >&2
        exit 2
    fi
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$HOST" "$REMOTE_CMD"
else
    # Try SSH agent or default key
    ssh -o StrictHostKeyChecking=no "$USER@$HOST" "$REMOTE_CMD"
fi
