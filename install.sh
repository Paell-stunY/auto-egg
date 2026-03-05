#!/bin/bash

# ============================================================
#   AUTO UPLOAD EGG - PTERODACTYL PANEL
#   github.com/username/repo
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║     AUTO UPLOAD EGG - PTERODACTYL PANEL      ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── CEK DEPENDENSI ─────────────────────────────────────────
for dep in curl jq; do
    if ! command -v "$dep" &>/dev/null; then
        echo -e "${YELLOW}[INFO]${NC} Menginstall dependensi: $dep ..."
        apt-get install -y "$dep" -qq 2>/dev/null || \
        yum install -y "$dep" -q 2>/dev/null || \
        { echo -e "${RED}[ERROR]${NC} Gagal install '$dep'. Install manual dulu."; exit 1; }
    fi
done

# ─── INPUT DARI USER ────────────────────────────────────────
echo -e "${BOLD}Isi konfigurasi berikut:${NC}\n"

# PANEL URL
read -rp "$(echo -e "${CYAN}PANEL_URL${NC} (contoh: https://panel.domain.com) : ")" PANEL_URL
while [[ -z "$PANEL_URL" ]]; do
    echo -e "${RED}[!] PANEL_URL tidak boleh kosong.${NC}"
    read -rp "$(echo -e "${CYAN}PANEL_URL${NC} : ")" PANEL_URL
done
PANEL_URL="${PANEL_URL%/}"

# API KEY
read -rp "$(echo -e "${CYAN}API_KEY${NC}   (ptla_...) : ")" API_KEY
while [[ -z "$API_KEY" ]]; do
    echo -e "${RED}[!] API_KEY tidak boleh kosong.${NC}"
    read -rp "$(echo -e "${CYAN}API_KEY${NC}   (ptla_...) : ")" API_KEY
done

# NEST ID
read -rp "$(echo -e "${CYAN}NEST_ID${NC}   (default: 1) : ")" NEST_ID
NEST_ID="${NEST_ID:-1}"

echo ""
echo -e "${YELLOW}────────────────────────────────────────${NC}"
echo -e " Panel URL : ${CYAN}${PANEL_URL}${NC}"
echo -e " API Key   : ${CYAN}${API_KEY:0:10}**********${NC}"
echo -e " Nest ID   : ${CYAN}${NEST_ID}${NC}"
echo -e "${YELLOW}────────────────────────────────────────${NC}\n"

read -rp "$(echo -e "Lanjutkan upload? ${BOLD}[y/N]${NC} : ")" CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "\n${RED}Dibatalkan.${NC}"
    exit 0
fi

# ─── AMBIL SEMUA EGG DARI FOLDER ./egg/ ─────────────────────
EGG_DIR="$(dirname "$0")/egg"

if [[ ! -d "$EGG_DIR" ]]; then
    echo -e "\n${RED}[ERROR]${NC} Folder 'egg/' tidak ditemukan di direktori ini."
    exit 1
fi

mapfile -t EGG_FILES < <(find "$EGG_DIR" -maxdepth 1 -name "*.json" | sort)

if [[ ${#EGG_FILES[@]} -eq 0 ]]; then
    echo -e "\n${RED}[ERROR]${NC} Tidak ada file .json di dalam folder egg/"
    exit 1
fi

echo -e "\n${BOLD}Ditemukan ${#EGG_FILES[@]} egg:${NC}"
for f in "${EGG_FILES[@]}"; do
    echo -e "  ${GREEN}•${NC} $(basename "$f")"
done
echo ""

# ─── UPLOAD SATU PER SATU ───────────────────────────────────
SUCCESS=0
FAILED=0
TOTAL=${#EGG_FILES[@]}

for i in "${!EGG_FILES[@]}"; do
    FILE="${EGG_FILES[$i]}"
    BASENAME=$(basename "$FILE")
    NUM=$((i + 1))

    echo -e "${YELLOW}[${NUM}/${TOTAL}]${NC} Mengupload: ${CYAN}${BASENAME}${NC}"

    HTTP_CODE=$(curl -s -o /tmp/_egg_resp.json -w "%{http_code}" \
        -X POST \
        "${PANEL_URL}/api/application/nests/${NEST_ID}/eggs/import" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d @"${FILE}")

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

# ─── RINGKASAN ───────────────────────────────────────────────
echo ""
echo -e "${CYAN}════════════════════════════════════${NC}"
echo -e "  ${BOLD}Selesai!${NC}"
echo -e "  ${GREEN}Sukses : ${SUCCESS}${NC}"
echo -e "  ${RED}Gagal  : ${FAILED}${NC}"
echo -e "  Total  : ${TOTAL}"
echo -e "${CYAN}════════════════════════════════════${NC}\n"

rm -f /tmp/_egg_resp.json
exit 0
