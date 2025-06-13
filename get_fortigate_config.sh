#!/bin/bash

set -e

usage() {
    echo "Usage: $0 -h <host> -u <user> -s <secret> [-t <token>] [-k]"
    echo "  -h <host>       Fortigate hostname or IP"
    echo "  -u <user>       API username"
    echo "  -s <secret>     API password (ignored if -t is used)"
    echo "  -t <token>      API token (optional, preferred)"
    echo "  -k              Allow insecure SSL (optional)"
    exit 1
}

INSECURE=""
while getopts ":h:u:s:t:k" opt; do
  case $opt in
    h) HOST="$OPTARG" ;;
    u) USER="$OPTARG" ;;
    s) SECRET="$OPTARG" ;;
    t) TOKEN="$OPTARG" ;;
    k) INSECURE="-k" ;;
    *) usage ;;
  esac
done

if [[ -z "$HOST" || -z "$USER" || ( -z "$SECRET" && -z "$TOKEN" ) ]]; then
    usage
fi

API_URL="https://$HOST/api/v2/monitor/system/config/backup?scope=global"

if [[ -n "$TOKEN" ]]; then
    # Use API token authentication
    curl $INSECURE -s -H "Authorization: Bearer $TOKEN" "$API_URL"
else
    # Use login session authentication
    # 1. Login and get session cookie
    LOGIN_URL="https://$HOST/logincheck"
    COOKIE_JAR=$(mktemp)
    RESPONSE=$(curl $INSECURE -s -c "$COOKIE_JAR" -d "username=$USER&secretkey=$SECRET" "$LOGIN_URL")
    if ! grep -q "200" <<< "$RESPONSE"; then
        echo "Login failed" >&2
        rm -f "$COOKIE_JAR"
        exit 2
    fi
    # 2. Download config using session cookie
    curl $INSECURE -s -b "$COOKIE_JAR" "$API_URL"
    rm -f "$COOKIE_JAR"
fi
