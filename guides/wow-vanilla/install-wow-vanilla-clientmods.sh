#!/bin/bash
# Dad's MMO Lab — Vanilla WoW Client Mod Installer
# Downloads VanillaFixes + WOW-Interact for interact keybind support
# These DLLs run through Wine/Proton on Linux (Steam Deck compatible)

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
GOLD='\033[38;5;220m'

echo ""
printf "${GOLD} ══════════════════════════════════════════════════════════════════════════════════${NC}\n"
printf "   ${DIM}Dad's MMO Lab${NC}  ✦  ${DIM}Vanilla WoW Client Mod Installer${NC}\n"
printf "${GOLD} ══════════════════════════════════════════════════════════════════════════════════${NC}\n"
echo ""

echo -e "  ${BOLD}What this installs:${NC}"
echo -e "  ${DIM}•${NC} VanillaFixes   — DLL loader for WoW 1.12.1 client mods"
echo -e "  ${DIM}•${NC} WOW-Interact   — adds INTERACTWITHNEAREST keybind (loot/talk/open)"
echo ""
echo -e "  ${DIM}These run through Wine/Proton on Linux and Steam Deck.${NC}"
echo -e "  ${DIM}After install, launch WoW via VanillaFixes.exe instead of WoW.exe.${NC}"
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

if [ ! -f "$WOW_DIR/WoW.exe" ]; then
    echo -e "  ${YELLOW}⚠  WoW.exe not found in $WOW_DIR — are you sure this is the right folder?${NC}"
    read -rp "  Continue anyway? [y/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy] ]]; then
        exit 1
    fi
fi

echo -e "  ${GREEN}✅ Client directory: $WOW_DIR${NC}"
echo ""

FORCE=false
if [[ "$2" == "--force" ]] || [[ "$1" == "--force" ]]; then
    FORCE=true
fi

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# ── Download VanillaFixes ──────────────────────────────────────
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "  ${BOLD}VanillaFixes${NC}"
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo ""

if [ -f "$WOW_DIR/VanillaFixes.exe" ] && [ "$FORCE" = false ]; then
    echo -e "  ${YELLOW}⏭  VanillaFixes.exe already exists, skipping (use --force to reinstall)${NC}"
else
    printf "  ${DIM}⬇  Fetching latest VanillaFixes release...${NC}"

    RELEASE_JSON=$(curl -sL "https://api.github.com/repos/hannesmann/vanillafixes/releases/latest" 2>/dev/null)

    if [ -z "$RELEASE_JSON" ]; then
        echo -e "\r  ${RED}❌ Failed to fetch VanillaFixes release info${NC}              "
        exit 1
    fi

    # find the non-DXVK zip (the one without "dxvk" in the name)
    DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep -o '"browser_download_url": *"[^"]*"' | grep -v -i dxvk | head -1 | sed 's/"browser_download_url": *"//;s/"$//')

    if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "\r  ${RED}❌ Could not find VanillaFixes download URL${NC}              "
        exit 1
    fi

    TAG=$(echo "$RELEASE_JSON" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/"tag_name": *"//;s/"$//')
    echo -e "\r  ${DIM}⬇  Downloading VanillaFixes ${TAG}...${NC}                    "

    if curl -sL "$DOWNLOAD_URL" -o "$TMPDIR/vanillafixes.zip" 2>/dev/null; then
        unzip -qo "$TMPDIR/vanillafixes.zip" -d "$TMPDIR/vanillafixes-extract" 2>/dev/null

        # copy all extracted files into WoW directory
        EXTRACTED_DIR=$(find "$TMPDIR/vanillafixes-extract" -mindepth 1 -maxdepth 1 -type d | head -1)
        if [ -z "$EXTRACTED_DIR" ]; then
            EXTRACTED_DIR="$TMPDIR/vanillafixes-extract"
        fi

        cp -f "$EXTRACTED_DIR"/*.exe "$WOW_DIR/" 2>/dev/null
        cp -f "$EXTRACTED_DIR"/*.dll "$WOW_DIR/" 2>/dev/null
        cp -f "$EXTRACTED_DIR"/*.txt "$WOW_DIR/" 2>/dev/null

        if [ -f "$WOW_DIR/VanillaFixes.exe" ]; then
            echo -e "  ${GREEN}✅ VanillaFixes ${TAG} installed${NC}"
        else
            echo -e "  ${RED}❌ VanillaFixes — files not found after extraction${NC}"
            exit 1
        fi
    else
        echo -e "\r  ${RED}❌ VanillaFixes — download failed${NC}              "
        exit 1
    fi
fi

echo ""

# ── Download WOW-Interact ─────────────────────────────────────
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "  ${BOLD}WOW-Interact${NC}"
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo ""

if [ -f "$WOW_DIR/Interact.dll" ] && [ "$FORCE" = false ]; then
    echo -e "  ${YELLOW}⏭  Interact.dll already exists, skipping (use --force to reinstall)${NC}"
else
    printf "  ${DIM}⬇  Fetching latest WOW-Interact release...${NC}"

    INTERACT_JSON=$(curl -sL "https://api.github.com/repos/logger945/WOW-Interact/releases/latest" 2>/dev/null)

    if [ -z "$INTERACT_JSON" ]; then
        echo -e "\r  ${RED}❌ Failed to fetch WOW-Interact release info${NC}              "
        exit 1
    fi

    INTERACT_URL=$(echo "$INTERACT_JSON" | grep -o '"browser_download_url": *"[^"]*"' | head -1 | sed 's/"browser_download_url": *"//;s/"$//')

    if [ -z "$INTERACT_URL" ]; then
        echo -e "\r  ${RED}❌ Could not find WOW-Interact download URL${NC}              "
        exit 1
    fi

    INTERACT_TAG=$(echo "$INTERACT_JSON" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/"tag_name": *"//;s/"$//')
    echo -e "\r  ${DIM}⬇  Downloading WOW-Interact ${INTERACT_TAG}...${NC}                    "

    # could be a zip or a direct dll — handle both
    INTERACT_FILE="$TMPDIR/interact-download"
    if curl -sL "$INTERACT_URL" -o "$INTERACT_FILE" 2>/dev/null; then
        FILETYPE=$(file -b "$INTERACT_FILE" 2>/dev/null)
        if echo "$FILETYPE" | grep -qi "zip"; then
            unzip -qo "$INTERACT_FILE" -d "$TMPDIR/interact-extract" 2>/dev/null
            FOUND_DLL=$(find "$TMPDIR/interact-extract" -name "Interact.dll" -o -name "interact.dll" | head -1)
            if [ -n "$FOUND_DLL" ]; then
                cp -f "$FOUND_DLL" "$WOW_DIR/Interact.dll"
            else
                echo -e "\r  ${RED}❌ WOW-Interact — Interact.dll not found in archive${NC}              "
                exit 1
            fi
        elif echo "$FILETYPE" | grep -qi "PE32\|DLL\|executable"; then
            cp -f "$INTERACT_FILE" "$WOW_DIR/Interact.dll"
        else
            # try treating it as a zip anyway
            unzip -qo "$INTERACT_FILE" -d "$TMPDIR/interact-extract" 2>/dev/null
            FOUND_DLL=$(find "$TMPDIR/interact-extract" -name "Interact.dll" -o -name "interact.dll" 2>/dev/null | head -1)
            if [ -n "$FOUND_DLL" ]; then
                cp -f "$FOUND_DLL" "$WOW_DIR/Interact.dll"
            else
                cp -f "$INTERACT_FILE" "$WOW_DIR/Interact.dll"
            fi
        fi

        if [ -f "$WOW_DIR/Interact.dll" ]; then
            echo -e "  ${GREEN}✅ WOW-Interact ${INTERACT_TAG} installed${NC}"
        else
            echo -e "  ${RED}❌ WOW-Interact — install failed${NC}"
            exit 1
        fi
    else
        echo -e "\r  ${RED}❌ WOW-Interact — download failed${NC}              "
        exit 1
    fi
fi

echo ""

# ── Configure dlls.txt ─────────────────────────────────────────
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "  ${BOLD}Configuring dlls.txt${NC}"
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo ""

DLLS_FILE="$WOW_DIR/dlls.txt"

if [ ! -f "$DLLS_FILE" ]; then
    echo "Interact.dll" > "$DLLS_FILE"
    echo -e "  ${GREEN}✅ Created dlls.txt with Interact.dll${NC}"
elif ! grep -q "Interact.dll" "$DLLS_FILE"; then
    echo "Interact.dll" >> "$DLLS_FILE"
    echo -e "  ${GREEN}✅ Added Interact.dll to dlls.txt${NC}"
else
    echo -e "  ${YELLOW}⏭  Interact.dll already in dlls.txt${NC}"
fi

echo ""

# ── Verify ─────────────────────────────────────────────────────
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "  ${BOLD}Verification${NC}"
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo ""

ALL_OK=true
for FILE in VanillaFixes.exe Interact.dll dlls.txt; do
    if [ -f "$WOW_DIR/$FILE" ]; then
        echo -e "  ${GREEN}✅${NC} $FILE"
    else
        echo -e "  ${RED}❌${NC} $FILE — missing"
        ALL_OK=false
    fi
done

echo ""

if [ "$ALL_OK" = true ]; then
    printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    echo -e "  ${GREEN}${BOLD}Done!${NC} Client mods installed successfully."
    printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    echo ""
    echo -e "  ${BOLD}How to launch:${NC}"
    echo -e "  ${DIM}Instead of running WoW.exe, launch VanillaFixes.exe${NC}"
    echo -e "  ${DIM}On Steam Deck / Linux, set the launch command to:${NC}"
    echo ""
    echo -e "  ${BOLD}wine VanillaFixes.exe${NC}"
    echo ""
    echo -e "  ${DIM}Or in Steam, set the launch options for WoW to:${NC}"
    echo -e "  ${DIM}WINEDLLOVERRIDES=\"\" %command%/../VanillaFixes.exe${NC}"
    echo ""
    echo -e "  ${DIM}The interact keybind (INTERACTWITHNEAREST) is now available.${NC}"
    echo -e "  ${DIM}ShaguController binds it to the V key (R4 back grip on Steam Deck).${NC}"
    echo ""
else
    echo -e "  ${RED}${BOLD}Some files are missing — check errors above.${NC}"
    exit 1
fi
