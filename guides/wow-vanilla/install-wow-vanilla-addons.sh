#!/bin/bash
# Dad's MMO Lab — Vanilla WoW Addon Installer
# Downloads and installs popular 1.12.1 addons into your WoW client


GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
GOLD='\033[38;5;220m'

echo ""
printf "${GOLD} ══════════════════════════════════════════════════════════════════════════════════${NC}\n"
printf "   ${DIM}Dad's MMO Lab${NC}  ✦  ${DIM}Vanilla WoW Addon Installer${NC}\n"
printf "${GOLD} ══════════════════════════════════════════════════════════════════════════════════${NC}\n"
echo ""

# ── Find or ask for client path ─────────────────────────────────
if [ -n "$1" ]; then
    WOW_DIR="$1"
else
    echo -e "  ${BOLD}Where is your WoW Vanilla client?${NC}"
    echo -e "  ${DIM}(the folder containing WoW.exe and Data/)${NC}"
    echo ""
    read -rp "  Path: " WOW_DIR
fi

WOW_DIR="${WOW_DIR/#\~/$HOME}"

if [ ! -d "$WOW_DIR" ]; then
    echo -e "  ${RED}❌ Directory not found: $WOW_DIR${NC}"
    exit 1
fi

ADDONS_DIR="$WOW_DIR/Interface/AddOns"
mkdir -p "$ADDONS_DIR"

echo ""
echo -e "  ${GREEN}✅ AddOns directory: $ADDONS_DIR${NC}"
echo ""

# ── Addon list ──────────────────────────────────────────────────
declare -A ADDONS
ADDONS=(
    ["pfQuest"]="https://github.com/shagu/pfQuest/archive/refs/heads/master.zip"
    ["pfUI"]="https://github.com/shagu/pfUI/archive/refs/heads/master.zip"
    ["ShaguTweaks"]="https://github.com/shagu/ShaguTweaks/archive/refs/heads/master.zip"
    ["ShaguPlates"]="https://github.com/shagu/ShaguPlates/archive/refs/heads/master.zip"
    ["LazyPig"]="https://github.com/diaFRAGma/LazyPig/archive/refs/heads/master.zip"
    ["aux-addon"]="https://github.com/shirsig/aux-addon-vanilla/archive/refs/heads/master.zip"
    ["ClassicSnowFall"]="https://github.com/Road-block/ClassicSnowFall/archive/refs/heads/master.zip"
    ["Mangosbot"]="https://github.com/celguar/mangosbot-addon/archive/refs/heads/master.zip"
    ["EngBags"]="https://github.com/davidonete/mangosbot-EngBags/archive/refs/heads/master.zip"
    ["ShaguController"]="https://github.com/spartalos/ShaguController/archive/refs/heads/master.zip"
)

ADDON_DESC=(
    "pfQuest          — quest markers on map and minimap"
    "pfUI             — full UI overhaul (bars, frames, bags, chat)"
    "ShaguTweaks      — fast loot, auto-sell grays, smooth scrolling"
    "ShaguPlates      — enemy nameplates with health/cast bars"
    "LazyPig          — auto-repair, auto-dismount, skip gossip"
    "aux-addon        — better auction house interface"
    "ClassicSnowFall  — abilities fire on key press"
    "Mangosbot        — GUI panel to control Playerbots (/bot)"
    "EngBags          — view and manage bot inventory"
    "ShaguController  — Steam Deck gamepad UI (21 skills, interact, mount)"
)

printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "  ${BOLD}Addons to install:${NC}"
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo ""
for desc in "${ADDON_DESC[@]}"; do
    echo -e "  ${DIM}•${NC} $desc"
done
echo ""

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

INSTALLED=0
SKIPPED=0
FAILED=0

for NAME in "${!ADDONS[@]}"; do
    URL="${ADDONS[$NAME]}"

    if [ -d "$ADDONS_DIR/$NAME" ]; then
        echo -e "  ${YELLOW}⏭  $NAME${NC} — already installed, skipping (delete to reinstall)"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    printf "  ${DIM}⬇  Downloading $NAME...${NC}"

    if curl -sL "$URL" -o "$TMPDIR/$NAME.zip" 2>/dev/null; then
        unzip -qo "$TMPDIR/$NAME.zip" -d "$TMPDIR/$NAME-extract" 2>/dev/null

        EXTRACTED_DIR=$(find "$TMPDIR/$NAME-extract" -mindepth 1 -maxdepth 1 -type d | head -1)

        if [ -n "$EXTRACTED_DIR" ]; then
            mv "$EXTRACTED_DIR" "$ADDONS_DIR/$NAME"
            echo -e "\r  ${GREEN}✅ $NAME${NC}                              "
            INSTALLED=$((INSTALLED + 1))
        else
            echo -e "\r  ${RED}❌ $NAME — extract failed${NC}              "
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "\r  ${RED}❌ $NAME — download failed${NC}              "
        FAILED=$((FAILED + 1))
    fi
done

echo ""
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "  ${GREEN}${BOLD}Done!${NC}  Installed: $INSTALLED  Skipped: $SKIPPED  Failed: $FAILED"
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo ""
echo -e "  ${DIM}Launch WoW and check AddOns button on the character select screen.${NC}"
echo -e "  ${DIM}To remove an addon, delete its folder from:${NC}"
echo -e "  ${DIM}$ADDONS_DIR${NC}"
echo ""
