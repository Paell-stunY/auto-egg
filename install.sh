#!/bin/bash

# ============================================================
#    AUTO UPLOAD EGG - PTERODACTYL PANEL (FIXED ENDPOINT)
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

URLS=(
    "https://raw.githubusercontent.com/Paell-stunY/auto-egg/refs/heads/main/egg/Egg_feellzStore.json"
    "https://raw.githubusercontent.com/Paell-stunY/auto-egg/refs/heads/main/egg/egg-s-a--m-p--windows.json"
    "https://raw.githubusercontent.com/Paell-stunY/auto-egg/refs/heads/main/egg/egg-samp.json"
)

clear
echo -e "${CYAN}--- PTERODACTYL EGG AUTO UPLOADER ---${NC}"

# --- INPUT USER ---
read -rp "PANEL URL (contoh: https://panel.kamu.com): " PANEL_URL
PANEL_URL="${PANEL_URL%/}"
read -rp "API KEY (ptla_...): " API_KEY
read -rp "NEST ID (contoh: 5): " NEST_ID
NEST_ID="${NEST_ID:-1}"

SUCCESS=0
FAILED=0

echo -e "\n${BOLD}Memulai Proses...${NC}\n"

for i in "${!URLS[@]}"; do
    URL="${URLS[$i]}"
    FILENAME=$(basename "$URL")
    
    echo -e "${YELLOW}[$((i+1))/${#URLS[@]}]${NC} Processing: ${CYAN}${FILENAME}${NC}"

    # Step 1: Download JSON
    CONTENT=$(curl -s -L "$URL")

    # Step 2: Upload ke API
    # Kita coba endpoint /import dengan header yang lebih lengkap
    RESPONSE_FILE="/tmp/resp.json"
    HTTP_CODE=$(curl -s -L -o "$RESPONSE_FILE" -w "%{http_code}" \
        -X POST "${PANEL_URL}/api/application/nests/${NEST_ID}/eggs/import" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d "$CONTENT")

    if [[ "$HTTP_CODE" == "201" || "$HTTP_CODE" == "200" || "$HTTP_CODE" == "204" ]]; then
        echo -e "        ${GREEN}[SUKSES]${NC}"
        ((SUCCESS++))
    elif [[ "$HTTP_CODE" == "405" ]]; then
        # Jika 405, kita coba fallback ke endpoint tanpa /import
        echo -e "        ${YELLOW}[INFO]${NC} 405 detected, trying alternative endpoint..."
        HTTP_CODE=$(curl -s -L -o "$RESPONSE_FILE" -w "%{http_code}" \
            -X POST "${PANEL_URL}/api/application/nests/${NEST_ID}/eggs" \
            -H "Authorization: Bearer ${API_KEY}" \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -d "$CONTENT")
        
        if [[ "$HTTP_CODE" == "201" || "$HTTP_CODE" == "200" ]]; then
             echo -e "        ${GREEN}[SUKSES]${NC} (via alternative)"
             ((SUCCESS++))
        else
             ERR=$(jq -r '.errors[0].detail // .message' "$RESPONSE_FILE" 2>/dev/null)
             echo -e "        ${RED}[GAGAL]${NC} HTTP ${HTTP_CODE} - ${ERR}"
             ((FAILED++))
        fi
    else
        ERR=$(jq -r '.errors[0].detail // .message' "$RESPONSE_FILE" 2>/dev/null)
        echo -e "        ${RED}[GAGAL]${NC} HTTP ${HTTP_CODE} - ${ERR}"
        ((FAILED++))
    fi
    sleep 1
done

echo -e "\n${CYAN}Selesai! Sukses: $SUCCESS | Gagal: $FAILED${NC}"
