#!/bin/bash

# ============================================================
#    AUTO UPLOAD EGG - PTERODACTYL PANEL (REMOTE VERSION)
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Daftar URL Egg (Bisa ditambah sesuai kebutuhan)
URLS=(
    "https://raw.githubusercontent.com/Paell-stunY/auto-egg/refs/heads/main/egg/Egg_feellzStore.json"
    "https://raw.githubusercontent.com/Paell-stunY/auto-egg/refs/heads/main/egg/egg-s-a--m-p--windows.json"
    "https://raw.githubusercontent.com/Paell-stunY/auto-egg/refs/heads/main/egg/egg-samp.json"
)

clear
echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║      AUTO UPLOAD EGG - REMOTE REPOSITORY     ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# --- CEK DEPENDENSI ---
for dep in curl jq; do
    if ! command -v "$dep" &>/dev/null; then
        echo -e "${YELLOW}[INFO]${NC} Menginstall dependensi: $dep ..."
        apt-get install -y "$dep" -qq 2>/dev/null || yum install -y "$dep" -q 2>/dev/null || { echo -e "${RED}[ERROR]${NC} Gagal install '$dep'."; exit 1; }
    fi
done

# --- INPUT USER ---
read -rp "$(echo -e "${CYAN}PANEL_URL${NC} (https://panel.xyz) : ")" PANEL_URL
PANEL_URL="${PANEL_URL%/}"
read -rp "$(echo -e "${CYAN}API_KEY${NC}   (ptla_...)         : ")" API_KEY
read -rp "$(echo -e "${CYAN}NEST_ID${NC}   (default: 1)       : ")" NEST_ID
NEST_ID="${NEST_ID:-1}"

echo -e "\n${BOLD}Menyiapkan upload untuk ${#URLS[@]} egg dari GitHub...${NC}\n"

SUCCESS=0
FAILED=0
TOTAL=${#URLS[@]}

for i in "${!URLS[@]}"; do
    URL="${URLS[$i]}"
    FILENAME=$(basename "$URL")
    NUM=$((i + 1))

    echo -e "${YELLOW}[${NUM}/${TOTAL}]${NC} Mendownload & Mengupload: ${CYAN}${FILENAME}${NC}"

    # Mengambil konten JSON ke memori dan langsung POST
    # Gunakan --data-binary untuk menjaga struktur JSON agar tidak rusak
    RESPONSE=$(curl -s -L "$URL")
    
    if [[ -z "$RESPONSE" ]]; then
        echo -e "        ${RED}[GAGAL]${NC} Tidak bisa mengambil file dari GitHub."
        ((FAILED++))
        continue
    fi

    HTTP_CODE=$(curl -s -o /tmp/_egg_resp.json -w "%{http_code}" \
        -X POST "${PANEL_URL}/api/application/nests/${NEST_ID}/eggs/import" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d "$RESPONSE")

    if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "201" ]]; then
        EGG_ID=$(jq -r '.attributes.id // "?"' /tmp/_egg_resp.json 2>/dev/null)
        echo -e "        ${GREEN}[SUKSES]${NC} Egg ID: ${EGG_ID}"
        ((SUCCESS++))
    else
        ERR=$(jq -r '.errors[0].detail // .message // "Unknown error"' /tmp/_egg_resp.json 2>/dev/null)
        echo -e "        ${RED}[GAGAL]${NC} HTTP ${HTTP_CODE} — ${ERR}"
        ((FAILED++))
    fi
    sleep 1
done

# --- RINGKASAN ---
echo -e "\n${CYAN}════════════════════════════════════${NC}"
echo -e "  Sukses : ${GREEN}${SUCCESS}${NC}"
echo -e "  Gagal  : ${RED}${FAILED}${NC}"
echo -e "  Total  : ${TOTAL}"
echo -e "${CYAN}════════════════════════════════════${NC}\n"

rm -f /tmp/_egg_resp.json
