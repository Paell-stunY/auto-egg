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

# Daftar URL Egg GitHub
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
        apt-get update -y -qq && apt-get install -y "$dep" -qq 2>/dev/null || yum install -y "$dep" -q 2>/dev/null
    fi
done

# --- INPUT USER ---
echo -e "${BOLD}Isi konfigurasi panel kamu:${NC}\n"

read -rp "$(echo -e "${CYAN}PANEL_URL${NC} (contoh: https://panel.domain.com) : ")" PANEL_URL
# Hapus trailing slash jika ada
PANEL_URL="${PANEL_URL%/}"

read -rp "$(echo -e "${CYAN}API_KEY${NC}   (ptla_...) : ")" API_KEY
while [[ -z "$API_KEY" ]]; do
    echo -e "${RED}[!] API_KEY tidak boleh kosong.${NC}"
    read -rp "$(echo -e "${CYAN}API_KEY${NC} : ")" API_KEY
done

read -rp "$(echo -e "${CYAN}NEST_ID${NC}   (default: 1) : ")" NEST_ID
NEST_ID="${NEST_ID:-1}"

echo -e "\n${YELLOW}────────────────────────────────────────${NC}"
echo -e " Mengupload ${#URLS[@]} Egg ke Nest ID: ${NEST_ID}"
echo -e "${YELLOW}────────────────────────────────────────${NC}\n"

SUCCESS=0
FAILED=0
TOTAL=${#URLS[@]}

for i in "${!URLS[@]}"; do
    URL="${URLS[$i]}"
    FILENAME=$(basename "$URL")
    NUM=$((i + 1))

    echo -e "${YELLOW}[${NUM}/${TOTAL}]${NC} Mendownload & Mengupload: ${CYAN}${FILENAME}${NC}"

    # 1. Download file JSON dari GitHub
    # Pakai -L karena GitHub sering redirect
    CONTENT=$(curl -s -L "$URL")
    
    if [[ -z "$CONTENT" ]]; then
        echo -e "        ${RED}[GAGAL]${NC} File kosong atau tidak bisa didownload."
        ((FAILED++))
        continue
    fi

    # 2. Upload ke API Pterodactyl
    # NOTE: Endpoint diganti ke /eggs (tanpa /import) karena banyak versi panel menolak POST ke /import
    RESPONSE_FILE="/tmp/_egg_resp.json"
    HTTP_CODE=$(curl -s -L -o "$RESPONSE_FILE" -w "%{http_code}" \
        -X POST "${PANEL_URL}/api/application/nests/${NEST_ID}/eggs" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d "$CONTENT")

    if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "201" ]]; then
        EGG_ID=$(jq -r '.attributes.id // "?"' "$RESPONSE_FILE" 2>/dev/null)
        echo -e "        ${GREEN}[SUKSES]${NC} Egg ID: ${EGG_ID}"
        ((SUCCESS++))
    else
        # Ambil detail error jika ada
        ERR_MSG=$(jq -r '.errors[0].detail // .message // "Error tidak diketahui"' "$RESPONSE_FILE" 2>/dev/null)
        echo -e "        ${RED}[GAGAL]${NC} HTTP ${HTTP_CODE} — ${ERR_MSG}"
        
        # Tips khusus kalau masih 405
        if [[ "$HTTP_CODE" == "405" ]]; then
            echo -e "        ${YELLOW}Tips: Cek apakah NEST_ID ${NEST_ID} benar-benar ada di panel.${NC}"
        fi
        ((FAILED++))
    fi
    sleep 1
done

# --- RINGKASAN ---
echo ""
echo -e "${CYAN}════════════════════════════════════${NC}"
echo -e "  ${BOLD}Hasil Akhir:${NC}"
echo -e "  ${GREEN}Sukses : ${SUCCESS}${NC}"
echo -e "  ${RED}Gagal  : ${FAILED}${NC}"
echo -e "  Total  : ${TOTAL}"
echo -e "${CYAN}════════════════════════════════════${NC}\n"

rm -f /tmp/_egg_resp.json
