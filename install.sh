#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

URLS=(
    "https://raw.githubusercontent.com/Paell-stunY/auto-egg/refs/heads/main/egg/Egg_feellzStore.json"
    "https://raw.githubusercontent.com/Paell-stunY/auto-egg/refs/heads/main/egg/egg-s-a--m-p--windows.json"
    "https://raw.githubusercontent.com/Paell-stunY/auto-egg/refs/heads/main/egg/egg-samp.json"
)

# Hardcode buat ngetes biar gak capek input
PANEL_URL="https://vpsv2.sampgavriel.dpdns.org"
API_KEY="ptla_6Yz7GdW3IO0jWe4pL2HOAOgCA6ESyRI0MQNGH59i3ae"
NEST_ID="5"

echo -e "${CYAN}--- PTERODACTYL EGG UPLOADER (ULTRA FIX) ---${NC}"

for i in "${!URLS[@]}"; do
    URL="${URLS[$i]}"
    FILENAME=$(basename "$URL")
    echo -e "\n${YELLOW}[$((i+1))/${#URLS[@]}] Mengunggah: ${FILENAME}${NC}"

    # Download file
    CONTENT=$(curl -s -L "$URL")

    # Kuncinya ada di endpoint yang pakai garis miring di akhir (/) 
    # dan flag --location-trusted
    RESPONSE_FILE="/tmp/final_resp.json"
    HTTP_CODE=$(curl -s -L --location-trusted -o "$RESPONSE_FILE" -w "%{http_code}" \
        -X POST "${PANEL_URL}/api/application/nests/${NEST_ID}/eggs/import" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d "$CONTENT")

    if [[ "$HTTP_CODE" == "201" || "$HTTP_CODE" == "200" || "$HTTP_CODE" == "204" ]]; then
        echo -e "${GREEN}        [BERHASIL] Egg masuk!${NC}"
    else
        # Jika gagal 405 lagi, kita paksa coba endpoint satunya PAKE SLASH AKHIR
        if [[ "$HTTP_CODE" == "405" ]]; then
            echo -e "${YELLOW}        [RETRY] Mencoba endpoint alternatif dengan slash...${NC}"
            HTTP_CODE=$(curl -s -L --location-trusted -o "$RESPONSE_FILE" -w "%{http_code}" \
                -X POST "${PANEL_URL}/api/application/nests/${NEST_ID}/eggs/" \
                -H "Authorization: Bearer ${API_KEY}" \
                -H "Accept: application/json" \
                -H "Content-Type: application/json" \
                -d "$CONTENT")
        fi

        if [[ "$HTTP_CODE" == "201" || "$HTTP_CODE" == "200" ]]; then
            echo -e "${GREEN}        [BERHASIL] Egg masuk via alternatif!${NC}"
        else
            echo -e "${RED}        [GAGAL] HTTP $HTTP_CODE${NC}"
            echo -n "        Pesan Error: "
            jq -r '.errors[0].detail // .message' "$RESPONSE_FILE" 2>/dev/null || cat "$RESPONSE_FILE"
        fi
    fi
done
