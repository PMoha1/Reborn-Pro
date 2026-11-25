#!/usr/bin/env bash
# ==============================================================================
#  ██████╗ ███████╗██████╗  ██████╗ ██████╗ ███╗   ██╗
#  ██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗████╗  ██║
#  ██████╔╝█████╗  ██████╔╝██║   ██║██████╔╝██╔██╗ ██║
#  ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║
#  ██║  ██║███████╗██████╔╝╚██████╔╝██║  ██║██║ ╚████║
#  ╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
#  REBORN-PRO MOBILE: UNIFIED ANDROID ROOT & ROOTLESS GHOST ENGINE
#  Architected for Elite Mobile Red Teaming & MikroTik Hotspot Evasion
#  Author: Mohammed Yaqeen (PMoha1) | https://github.com/PMoha1
# ==============================================================================

set -o pipefail

# ANSI Colors
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_RED="\033[31m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_BLUE="\033[34m"
C_MAGENTA="\033[35m"
C_CYAN="\033[36m"
C_WHITE="\033[37m"

BASELINE_FILE="/data/local/tmp/.reborn_android_baseline.conf"
STATIC_STATE_FILE="/data/local/tmp/.reborn_android_static.state"

BANNER="
${C_CYAN}${C_BOLD}  ██████╗ ███████╗██████╗  ██████╗ ██████╗ ███╗   ██╗
  ██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗████╗  ██║
  ██████╔╝█████╗  ██████╔╝██║   ██║██████╔╝██╔██╗ ██║
  ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║
  ██║  ██║███████╗██████╔╝╚██████╔╝██║  ██║██║ ╚████║
  ╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝${C_RESET}
${C_MAGENTA}${C_BOLD}  — REBORN MOBILE v2.0: ROOT & ROOTLESS GHOST IDENTITY ENGINE —${C_RESET}
${C_DIM}  Architected by Mohammed Yaqeen (@PMoha1) | Pixel/Magisk/KernelSU/Shizuku${C_RESET}
"

# ------------------------------------------------------------------------------
# Execution Context & Privilege Auto-Detection
# ------------------------------------------------------------------------------
detect_environment() {
    if [[ -n "$PREFIX" && "$PREFIX" == *com.termux* ]]; then
        if [[ -f "/etc/debian_version" || -f "/etc/kali_version" || -n "$PROOT_TMP_DIR" ]]; then
            ENV_MODE="PROOT_CONTAINER"
        else
            ENV_MODE="TERMUX"
        fi
    elif [[ -f "/etc/debian_version" || -f "/etc/kali_version" || -n "$PROOT_TMP_DIR" ]]; then
        ENV_MODE="PROOT_CONTAINER"
    elif [[ -f "/system/bin/sh" && -z "$PREFIX" ]]; then
        ENV_MODE="ANDROID_NATIVE"
    else
        ENV_MODE="WORKSTATION_REMOTE"
    fi
}

adb_cmd() {
    if [[ -n "${ANDROID_SERIAL:-}" ]]; then
        adb -s "$ANDROID_SERIAL" "$@"
    else
        adb "$@"
    fi
}

b64_encode() {
    printf '%s' "$1" | base64 | tr -d '\r\n'
}

# Execute standard shell command on Android target (base64-safe)
exec_android_shell() {
    local cmd="$1"
    local b64
    b64=$(b64_encode "$cmd")

    case "$ENV_MODE" in
        "ANDROID_NATIVE")
            /system/bin/sh -c "$cmd"
            ;;
        "TERMUX"|"PROOT_CONTAINER")
            if [[ $EUID -eq 0 ]] && [[ "$ENV_MODE" == "TERMUX" ]]; then
                /system/bin/sh -c "$cmd"
            elif command -v su &>/dev/null && su -c "id" 2>/dev/null | grep -q "uid=0"; then
                printf '%s' "$b64" | su -c "base64 -d | /system/bin/sh"
            elif command -v rish &>/dev/null; then
                rish -c "$cmd"
            elif command -v adb &>/dev/null; then
                adb connect 127.0.0.1:5555 >/dev/null 2>&1 || true
                printf '%s' "$b64" | adb -s 127.0.0.1:5555 shell "base64 -d | /system/bin/sh" 2>/dev/null
            else
                echo -e "${C_RED}[!] Error: No su, rish (Shizuku), or ADB found in environment.${C_RESET}" >&2
                return 1
            fi
            ;;
        "WORKSTATION_REMOTE")
            if ! command -v adb &>/dev/null; then
                echo -e "${C_RED}[!] Error: adb not found on workstation.${C_RESET}" >&2
                return 1
            fi
            printf '%s' "$b64" | adb_cmd shell "base64 -d | /system/bin/sh"
            ;;
    esac
}

# Execute root (uid=0) command on Android target (base64-safe)
exec_android_root() {
    local cmd="$1"
    local b64
    b64=$(b64_encode "$cmd")

    case "$ENV_MODE" in
        "ANDROID_NATIVE")
            if [[ $(id -u) -eq 0 ]]; then
                /system/bin/sh -c "$cmd"
            else
                printf '%s' "$b64" | su -c "base64 -d | /system/bin/sh"
            fi
            ;;
        "TERMUX"|"PROOT_CONTAINER")
            if [[ $EUID -eq 0 ]] && [[ -x "/system/bin/sh" ]]; then
                /system/bin/sh -c "$cmd"
            elif command -v su &>/dev/null && su -c "id" 2>/dev/null | grep -q "uid=0"; then
                printf '%s' "$b64" | su -c "base64 -d | /system/bin/sh"
            elif command -v adb &>/dev/null; then
                adb connect 127.0.0.1:5555 >/dev/null 2>&1 || true
                printf '%s' "$b64" | adb -s 127.0.0.1:5555 shell "base64 -d | su -c /system/bin/sh" 2>/dev/null
            else
                return 1
            fi
            ;;
        "WORKSTATION_REMOTE")
            printf '%s' "$b64" | adb_cmd shell "base64 -d | su -c /system/bin/sh"
            ;;
    esac
}

detect_privileges() {
    ROOT_MODE=0
    ROOT_DESC="ROOTLESS (ADB / Shizuku)"

    if [[ "$ENV_MODE" == "WORKSTATION_REMOTE" ]]; then
        local dev_count
        dev_count=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {c++} END{print c+0}')
        if [[ "$dev_count" -eq 0 ]]; then
            echo -e "${C_RED}[!] No authorized ADB device detected. Connect device with USB Debugging enabled.${C_RESET}" >&2
            return 1
        fi
    fi

    local root_check
    root_check=$(exec_android_root "id -u" 2>/dev/null | tr -d '\r\n ')
    if [[ "$root_check" == "0" ]]; then
        ROOT_MODE=1
        local su_ver
        su_ver=$(exec_android_root "magisk -v 2>/dev/null || ksud -V 2>/dev/null || echo 'su uid=0'" | head -n 1 | tr -d '\r')
        ROOT_DESC="ROOT (uid=0 | ${su_ver})"
    fi
}

exec_privileged() {
    if [[ "$ROOT_MODE" -eq 1 ]]; then
        exec_android_root "$1"
    else
        exec_android_shell "$1"
    fi
}

# ------------------------------------------------------------------------------
# Generators & Personas
# ------------------------------------------------------------------------------
generate_mac() {
    local prefix="$1"
    if [[ -z "$prefix" ]]; then
        printf "02:%02x:%02x:%02x:%02x:%02x\n" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
    else
        printf "%s:%02x:%02x:%02x\n" "$prefix" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
    fi
}

random_win_hostname() {
    local chars="0123456789ABCDEF"
    local suffix=""
    for _ in 1 2 3 4 5 6 7; do
        suffix+="${chars:$((RANDOM % 16)):1}"
    done
    echo "DESKTOP-${suffix}"
}

random_android_hostname() {
    local chars="0123456789abcdef"
    local suffix=""
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        suffix+="${chars:$((RANDOM % 16)):1}"
    done
    echo "android-${suffix}"
}

select_random_persona() {
    local idx=$(( RANDOM % 8 ))
    case "$idx" in
        0) CHOSEN_NAME="iPhone-16-Pro" ;;
        1) CHOSEN_NAME="iPad-Air-M2" ;;
        2) CHOSEN_NAME="Galaxy-S24-Ultra" ;;
        3) CHOSEN_NAME="Pixel-9-Pro" ;;
        4) CHOSEN_NAME="MacBook-Air-M3" ;;
        5) CHOSEN_NAME="Lenovo-ThinkPad-X1" ;;
        6) CHOSEN_NAME="Dell-XPS-15" ;;
        7) CHOSEN_NAME="HP-Spectre-x360" ;;
    esac
    case "$CHOSEN_NAME" in
        *iPhone*|*iPad*|*MacBook*)
            CHOSEN_MAC=$(generate_mac "bc:d0:74")
            CHOSEN_TTL="${OVERRIDE_TTL:-64}"
            CHOSEN_DESC="Apple Ecosystem"
            ;;
        *Galaxy*|*Pixel*)
            CHOSEN_MAC=$(generate_mac "5c:e8:eb")
            CHOSEN_TTL="${OVERRIDE_TTL:-64}"
            CHOSEN_DESC="Android Flagship"
            ;;
        *)
            CHOSEN_MAC=$(generate_mac "00:1b:77")
            CHOSEN_TTL="${OVERRIDE_TTL:-128}"
            CHOSEN_DESC="Windows/PC Stealth"
            ;;
    esac
}

select_persona_interactive() {
    echo -e "\n${C_BOLD}${C_CYAN}Select Target Decoy Persona for Router & Network:${C_RESET}"
    echo -e "  ${C_GREEN}[1]${C_RESET} Apple iPhone 16 Pro       (TTL=64)"
    echo -e "  ${C_GREEN}[2]${C_RESET} Apple iPad Air M2         (TTL=64)"
    echo -e "  ${C_GREEN}[3]${C_RESET} Samsung Galaxy S24 Ultra  (TTL=64)"
    echo -e "  ${C_GREEN}[4]${C_RESET} Windows 11 Laptop         (DESKTOP-XXXX | TTL=128)"
    echo -e "  ${C_GREEN}[5]${C_RESET} HP LaserJet Pro Printer   (TTL=128)"
    echo -e "  ${C_GREEN}[6]${C_RESET} LG Smart TV (webOS)       (TTL=64)"
    echo -e "  ${C_GREEN}[7]${C_RESET} Pure Random Stealth       (android-xxxx | TTL=64)"
    echo -e "  ${C_GREEN}[8]${C_RESET} Custom Hostname           (Manual)"
    echo -ne "\n${C_YELLOW}Choose persona [1-8]: ${C_RESET}"
    read -r choice

    case "$choice" in
        1) CHOSEN_NAME="iPhone-16-Pro"; CHOSEN_MAC=$(generate_mac "bc:d0:74"); CHOSEN_TTL=64; CHOSEN_DESC="Apple iPhone" ;;
        2) CHOSEN_NAME="iPad-Air-M2"; CHOSEN_MAC=$(generate_mac "f0:18:98"); CHOSEN_TTL=64; CHOSEN_DESC="Apple iPad" ;;
        3) CHOSEN_NAME="Galaxy-S24-Ultra"; CHOSEN_MAC=$(generate_mac "5c:e8:eb"); CHOSEN_TTL=64; CHOSEN_DESC="Samsung Galaxy" ;;
        4) CHOSEN_NAME=$(random_win_hostname); CHOSEN_MAC=$(generate_mac "00:1b:77"); CHOSEN_TTL=128; CHOSEN_DESC="Windows 11 PC" ;;
        5) CHOSEN_NAME="HP-LaserJet-Pro"; CHOSEN_MAC=$(generate_mac "00:0e:7f"); CHOSEN_TTL=128; CHOSEN_DESC="HP Printer" ;;
        6) CHOSEN_NAME="LG-webOSTV"; CHOSEN_MAC=$(generate_mac "00:05:cd"); CHOSEN_TTL=64; CHOSEN_DESC="LG Smart TV" ;;
        7) CHOSEN_NAME=$(random_android_hostname); CHOSEN_MAC=$(generate_mac ""); CHOSEN_TTL=64; CHOSEN_DESC="Pure Random" ;;
        8)
            echo -ne "\n${C_YELLOW}Enter custom decoy hostname: ${C_RESET}"
            read -r custom_input
            CHOSEN_NAME="${custom_input:-Device-$(od -An -N3 -tx1 /dev/urandom | tr -d ' \n')}"
            CHOSEN_MAC=$(generate_mac "")
            CHOSEN_TTL="${OVERRIDE_TTL:-64}"
            CHOSEN_DESC="Custom Identity"
            ;;
        *)
            select_random_persona
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Baseline Save & Restore
# ------------------------------------------------------------------------------
save_baseline() {
    local exists
    exists=$(exec_privileged "[ -f '$BASELINE_FILE' ] && echo YES || echo NO" 2>/dev/null | tr -d '\r\n ')
    if [[ "$exists" == "YES" ]]; then
        return 0
    fi

    exec_privileged "
        orig_dev=\$(settings get global device_name 2>/dev/null)
        orig_bt=\$(settings get secure bluetooth_name 2>/dev/null)
        orig_host=\$(getprop net.hostname 2>/dev/null)
        orig_aid=\$(settings get secure android_id 2>/dev/null)
        orig_ttl=\$(cat /proc/sys/net/ipv4/ip_default_ttl 2>/dev/null || echo 64)
        orig_mac=\$(ip link show wlan0 2>/dev/null | awk '/link\/ether/{print \$2; exit}')
        cat <<EOF > '$BASELINE_FILE'
ORIGINAL_DEVICE_NAME=\"\${orig_dev}\"
ORIGINAL_BT_NAME=\"\${orig_bt}\"
ORIGINAL_NET_HOSTNAME=\"\${orig_host}\"
ORIGINAL_ANDROID_ID=\"\${orig_aid}\"
ORIGINAL_TTL=\"\${orig_ttl}\"
ORIGINAL_MAC=\"\${orig_mac}\"
EOF
    " >/dev/null 2>&1 || true
}

restore_baseline() {
    echo -e "$BANNER"
    local exists
    exists=$(exec_privileged "[ -f '$BASELINE_FILE' ] && echo YES || echo NO" 2>/dev/null | tr -d '\r\n ')
    if [[ "$exists" != "YES" ]]; then
        echo -e "${C_RED}[!] No saved baseline found at ${BASELINE_FILE}.${C_RESET}"
        return 1
    fi

    echo -e "${C_YELLOW}[*] Restoring original device baseline identity...${C_RESET}"
    exec_privileged "
        . '$BASELINE_FILE'
        [ -n \"\$ORIGINAL_DEVICE_NAME\" ] && [ \"\$ORIGINAL_DEVICE_NAME\" != \"null\" ] && settings put global device_name \"\$ORIGINAL_DEVICE_NAME\"
        if [ -n \"\$ORIGINAL_BT_NAME\" ] && [ \"\$ORIGINAL_BT_NAME\" != \"null\" ]; then
            settings put secure bluetooth_name \"\$ORIGINAL_BT_NAME\"
        else
            settings delete secure bluetooth_name 2>/dev/null || true
        fi
        [ -n \"\$ORIGINAL_ANDROID_ID\" ] && [ \"\$ORIGINAL_ANDROID_ID\" != \"null\" ] && settings put secure android_id \"\$ORIGINAL_ANDROID_ID\"
        if [ \$(id -u) -eq 0 ]; then
            if command -v resetprop >/dev/null 2>&1; then
                resetprop net.hostname \"\$ORIGINAL_NET_HOSTNAME\" 2>/dev/null || true
            fi
            [ -n \"\$ORIGINAL_NET_HOSTNAME\" ] && hostname \"\$ORIGINAL_NET_HOSTNAME\" 2>/dev/null || true
            [ -n \"\$ORIGINAL_TTL\" ] && echo \"\$ORIGINAL_TTL\" > /proc/sys/net/ipv4/ip_default_ttl 2>/dev/null || true
            [ -n \"\$ORIGINAL_MAC\" ] && ip link set dev wlan0 address \"\$ORIGINAL_MAC\" 2>/dev/null || true
            ip neigh flush all 2>/dev/null || true
        fi
    "
    echo -e "${C_GREEN}[✓] Original baseline identity restored.${C_RESET}"
}

# ------------------------------------------------------------------------------
# Live Network & Identity Telemetry
# ------------------------------------------------------------------------------
gather_telemetry() {
    local raw
    raw=$(exec_privileged '
        cur_ip=$(ip -4 addr show wlan0 2>/dev/null | awk "/inet /{print \$2; exit}")
        if [ -z "$cur_ip" ]; then
            cur_ip=$(dumpsys wifi 2>/dev/null | sed -n "s/.*WifiInfo:.*IP: \/\([^,]*\).*/\1/p" | head -n 1)
        fi
        cur_mac=$(ip link show wlan0 2>/dev/null | awk "/link\/ether/{print \$2; exit}")
        if [ -z "$cur_mac" ]; then
            cur_mac=$(cat /sys/class/net/wlan0/address 2>/dev/null)
        fi
        if [ -z "$cur_mac" ]; then
            cur_mac=$(dumpsys wifi 2>/dev/null | sed -n "s/.*WifiInfo:.*MAC: \([^,]*\).*/\1/p" | head -n 1)
        fi
        wifi_stat=$(cmd wifi status 2>/dev/null)
        cur_ssid=$(printf "%s\n" "$wifi_stat" | sed -n "s/.*Wifi is connected to \"\([^\"]*\)\".*/\1/p" | head -n 1)
        cur_netid=$(printf "%s\n" "$wifi_stat" | sed -n "s/.*Net ID: \([0-9]*\).*/\1/p" | head -n 1)
        dev_name=$(settings get global device_name 2>/dev/null)
        net_host=$(getprop net.hostname 2>/dev/null)
        aid=$(settings get secure android_id 2>/dev/null)
        ttl=$(cat /proc/sys/net/ipv4/ip_default_ttl 2>/dev/null || echo "64")
        portal="NONE"
        if dumpsys connectivity 2>/dev/null | grep -q "CAPTIVE_PORTAL"; then
            portal="CAPTIVE_PORTAL_DETECTED"
        elif [ -n "$cur_ip" ]; then
            portal="CONNECTED"
        fi
        printf "CUR_IP=%s\nCUR_MAC=%s\nCUR_SSID=%s\nCUR_NETID=%s\nDEV_NAME=%s\nNET_HOST=%s\nAID=%s\nTTL=%s\nPORTAL=%s\n" \
            "$cur_ip" "$cur_mac" "$cur_ssid" "$cur_netid" "$dev_name" "$net_host" "$aid" "$ttl" "$portal"
    ' 2>/dev/null)

    CUR_IP=""; CUR_MAC=""; CUR_SSID=""; CUR_NETID=""; DEV_NAME=""; NET_HOST=""; AID=""; CUR_TTL="64"; PORTAL_STATE="NONE"
    while IFS='=' read -r k v; do
        v="${v%$'\r'}"
        case "$k" in
            CUR_IP) CUR_IP="$v" ;;
            CUR_MAC) CUR_MAC="$v" ;;
            CUR_SSID) CUR_SSID="$v" ;;
            CUR_NETID) CUR_NETID="$v" ;;
            DEV_NAME) DEV_NAME="$v" ;;
            NET_HOST) NET_HOST="$v" ;;
            AID) AID="$v" ;;
            TTL) CUR_TTL="$v" ;;
            PORTAL) PORTAL_STATE="$v" ;;
        esac
    done <<< "$raw"
}

# ------------------------------------------------------------------------------
# Deep Mobile Browser & WebView Footprint Purge (Root)
# ------------------------------------------------------------------------------
clean_browser_footprints() {
    echo -e "${C_BLUE}[*] Purging mobile browser & WebView tracking footprints...${C_RESET}"
    if [[ "$ROOT_MODE" -eq 0 ]]; then
        echo -e "${C_YELLOW}⚠ Browser data purge requires Root (uid=0). Skipping deep wipe.${C_RESET}"
        return 0
    fi

    exec_android_root '
        for pkg in com.android.chrome com.chrome.beta org.torproject.torbrowser com.brave.browser org.mozilla.firefox; do
            if pm list packages "$pkg" 2>/dev/null | grep -q "$pkg"; then
                am force-stop "$pkg" 2>/dev/null || true
                rm -rf "/data/data/$pkg/cache/"* 2>/dev/null || true
                rm -rf "/data/data/$pkg/code_cache/"* 2>/dev/null || true
                rm -rf "/data/data/$pkg/app_chrome/Default/GPUCache/"* 2>/dev/null || true
                rm -rf "/data/data/$pkg/app_chrome/Default/Service Worker/"* 2>/dev/null || true
                rm -f  "/data/data/$pkg/app_chrome/Default/Network/Network Persistent State" 2>/dev/null || true
                rm -f  "/data/data/$pkg/app_chrome/Default/TransportSecurity" 2>/dev/null || true
                rm -f  "/data/data/$pkg/app_chrome/Default/Cookies"* 2>/dev/null || true
                rm -f  "/data/data/$pkg/app_chrome/Default/Network/Cookies"* 2>/dev/null || true
                echo "  + Purged footprints: $pkg"
            fi
        done
    '
    echo -e "${C_GREEN}[✓] Mobile browser caches, cookies, and HSTS state purged.${C_RESET}"
}

# ------------------------------------------------------------------------------
# Static IP Stealth Mode (Root Only)
# ------------------------------------------------------------------------------
toggle_static_stealth() {
    if [[ "$ROOT_MODE" -eq 0 ]]; then
        echo -e "${C_RED}[!] Static IP Stealth Mode requires Root (uid=0).${C_RESET}"
        return 1
    fi

    gather_telemetry
    if [[ -z "$CUR_IP" ]]; then
        echo -e "${C_RED}[!] Wi-Fi is not connected to any IPv4 network.${C_RESET}"
        return 1
    fi

    local is_static
    is_static=$(exec_android_root "[ -f '$STATIC_STATE_FILE' ] && echo YES || echo NO" | tr -d '\r\n ')
    if [[ "$is_static" == "YES" ]]; then
        echo -e "${C_YELLOW}[*] Reverting Static IP Stealth back to DHCP...${C_RESET}"
        exec_android_root "
            rm -f '$STATIC_STATE_FILE'
            cmd wifi set-wifi-enabled disabled
            sleep 2
            cmd wifi set-wifi-enabled enabled
        "
        sleep 6
        echo -e "${C_GREEN}[✓] Returned to DHCP mode.${C_RESET}"
        return 0
    fi

    local ip_only="${CUR_IP%%/*}"
    local prefix="${CUR_IP##*/}"
    [[ "$prefix" == "$CUR_IP" ]] && prefix="24"
    local subnet="${ip_only%.*}"
    local gw
    gw=$(exec_android_root "ip route show table wlan0 2>/dev/null | awk '/^default/{print \$3; exit}'" | tr -d '\r\n ')
    gw="${gw:-${subnet}.1}"
    local suggested="${subnet}.224"

    echo -e "\n${C_CYAN}=== Static IP Stealth Mode (Android Root) ===${C_RESET}"
    echo -e "  Current IP : ${C_WHITE}${CUR_IP}${C_RESET} | Gateway: ${C_YELLOW}${gw}${C_RESET}"
    echo -ne "  Enter stealth IP [${suggested}]: "
    read -r user_ip
    local final_ip="${user_ip:-$suggested}"

    exec_android_root "
        echo '${CUR_IP}' > '$STATIC_STATE_FILE'
        ip addr add '${final_ip}/${prefix}' dev wlan0 2>/dev/null || true
        ip addr del '${CUR_IP}' dev wlan0 2>/dev/null || true
        ip route replace default via '${gw}' dev wlan0 table wlan0 2>/dev/null || true
        ip route replace '${subnet}.0/${prefix}' dev wlan0 proto static scope link table wlan0 2>/dev/null || true
        ip neigh flush all 2>/dev/null || true
    "
    echo -e "${C_GREEN}[✓] Silent Static IP active: ${final_ip}/${prefix}${C_RESET}"
}

# ------------------------------------------------------------------------------
# Core Reborn Execution Logic (Root & Rootless Unified)
# ------------------------------------------------------------------------------
run_reborn() {
    save_baseline
    gather_telemetry

    local old_ip="${CUR_IP:-Disconnected}"
    local old_mac="${CUR_MAC:-Unknown}"
    local old_ssid="${CUR_SSID:-None}"

    if [[ -z "${CHOSEN_NAME:-}" ]]; then
        select_random_persona
    fi

    local new_aid
    new_aid=$(od -An -N8 -tx8 /dev/urandom 2>/dev/null | tr -d ' \n' || head -c 16 /dev/urandom | xxd -p)
    new_aid="${new_aid:0:16}"

    echo -e "$BANNER"
    echo -e "${C_YELLOW}${C_BOLD}[*] Mode Detected     :${C_WHITE} ${ENV_MODE}${C_RESET}"
    echo -e "${C_YELLOW}${C_BOLD}[*] Privilege Engine  :${C_GREEN} ${ROOT_DESC}${C_RESET}"
    echo -e "${C_CYAN}[+] Initiating Full Ghost Identity Rotation...${C_RESET}"
    echo "------------------------------------------------------------------"

    # 1. Enforce Dynamic MAC Randomization + Inject Decoy Hostname
    echo -e "${C_BLUE}[1/5] Injecting decoy identity & DHCP hostname: ${C_GREEN}${CHOSEN_NAME}${C_RESET}"
    exec_privileged "
        settings put global wifi_connected_mac_randomization_enabled 1
        settings put global device_name '$CHOSEN_NAME'
        settings put secure bluetooth_name '$CHOSEN_NAME'
        if [ \$(id -u) -eq 0 ]; then
            if command -v resetprop >/dev/null 2>&1; then
                resetprop net.hostname '$CHOSEN_NAME' 2>/dev/null || true
            else
                setprop net.hostname '$CHOSEN_NAME' 2>/dev/null || true
            fi
            hostname '$CHOSEN_NAME' 2>/dev/null || true
        fi
    "

    # 2. TCP/IP TTL Spoofing (Root Only)
    if [[ "$ROOT_MODE" -eq 1 ]]; then
        echo -e "${C_BLUE}[2/5] Spoofing TCP/IP Stack TTL = ${C_YELLOW}${CHOSEN_TTL}${C_BLUE} (${CHOSEN_DESC})...${C_RESET}"
        exec_android_root "echo '$CHOSEN_TTL' > /proc/sys/net/ipv4/ip_default_ttl 2>/dev/null || true"
    else
        echo -e "${C_DIM}[2/5] TTL spoofing skipped (requires Root).${C_RESET}"
    fi

    # 3. Cryptographic Android ID (SSAID) Rotation
    echo -e "${C_BLUE}[3/5] Rotating Android ID (SSAID): ${C_MAGENTA}${new_aid}${C_RESET}"
    exec_privileged "settings put secure android_id '$new_aid'"

    # 4. Optional Deep Browser Purge
    if [[ "${DO_BROWSER_CLEAN:-0}" -eq 1 && "$ROOT_MODE" -eq 1 ]]; then
        clean_browser_footprints
    fi

    # 5. True L2 MAC Rotation & Wi-Fi DHCP Renewal
    echo -e "${C_BLUE}[4/5] Rotating L2 MAC & renewing Wi-Fi DHCP lease...${C_RESET}"
    if [[ "$ROOT_MODE" -eq 1 ]]; then
        exec_android_root "
            XML='/data/misc/apexdata/com.android.wifi/WifiConfigStore.xml'
            wifi_stat=\$(cmd wifi status 2>/dev/null)
            cur_ssid=\$(printf '%s\n' \"\$wifi_stat\" | sed -n 's/.*Wifi is connected to \"\([^\"]*\)\".*/\1/p' | head -n 1)
            cur_netid=\$(printf '%s\n' \"\$wifi_stat\" | sed -n 's/.*Net ID: \([0-9]*\).*/\1/p' | head -n 1)

            ip neigh flush all 2>/dev/null || true

            if [ -n \"\$cur_ssid\" ] && [ -n \"\$cur_netid\" ] && [ -f \"\$XML\" ]; then
                # Extract security mode and PSK purely in root memory without echoing secrets
                net_info=\$(awk -v target=\"\$cur_ssid\" '
                    function unesc(s) {
                        gsub(/&quot;/, \"\\\"\", s);
                        gsub(/&apos;/, \"\x27\", s);
                        gsub(/&lt;/, \"<\", s);
                        gsub(/&gt;/, \">\", s);
                        gsub(/&amp;/, \"\\&\", s);
                        return s;
                    }
                    /<Network>/ { in_net=1; matched=0; cfg=\"\"; psk=\"\"; }
                    in_net && /<string name=\"ConfigKey\">/ {
                        val=\$0; sub(/.*<string name=\"ConfigKey\">/, \"\", val); sub(/<\/string>.*/, \"\", val);
                        cfg=unesc(val);
                    }
                    in_net && /<string name=\"SSID\">/ {
                        val=\$0; sub(/.*<string name=\"SSID\">/, \"\", val); sub(/<\/string>.*/, \"\", val);
                        s=unesc(val);
                        gsub(/^\"|\"$/, \"\", s);
                        if (s == target) matched=1;
                    }
                    in_net && /<string name=\"PreSharedKey\">/ {
                        val=\$0; sub(/.*<string name=\"PreSharedKey\">/, \"\", val); sub(/<\/string>.*/, \"\", val);
                        p=unesc(val);
                        gsub(/^\"|\"$/, \"\", p);
                        psk=p;
                    }
                    /<\/Network>/ {
                        if (matched) {
                            sec=\"unsupported\";
                            if (cfg ~ /NONE$/) sec=\"open\";
                            else if (cfg ~ /OWE$/) sec=\"owe\";
                            else if (cfg ~ /WPA_PSK$/) sec=\"wpa2\";
                            else if (cfg ~ /SAE$/) sec=\"wpa3\";
                            print sec \"\t\" psk;
                            exit;
                        }
                        in_net=0;
                    }
                ' \"\$XML\")

                sec_mode=\$(printf '%s' \"\$net_info\" | cut -f1)
                psk_val=\$(printf '%s' \"\$net_info\" | cut -f2-)

                if [ \"\$sec_mode\" = \"open\" ] || [ \"\$sec_mode\" = \"owe\" ]; then
                    cmd wifi forget-network \"\$cur_netid\" >/dev/null 2>&1 || true
                    sleep 1
                    cmd wifi connect-network \"\$cur_ssid\" \"\$sec_mode\" -r non_persistent >/dev/null 2>&1 || true
                elif { [ \"\$sec_mode\" = \"wpa2\" ] || [ \"\$sec_mode\" = \"wpa3\" ]; } && [ -n \"\$psk_val\" ]; then
                    cmd wifi forget-network \"\$cur_netid\" >/dev/null 2>&1 || true
                    sleep 1
                    cmd wifi connect-network \"\$cur_ssid\" \"\$sec_mode\" \"\$psk_val\" -r non_persistent >/dev/null 2>&1 || true
                else
                    # Enterprise/EAP safety guard: never forget credentials we cannot re-supply
                    cmd wifi set-wifi-enabled disabled >/dev/null 2>&1
                    sleep 2
                    cmd wifi set-wifi-enabled enabled >/dev/null 2>&1
                fi
                unset psk_val net_info
            else
                # Disconnected/DORMANT: update interface MAC directly without tearing down iface
                ip link set dev wlan0 address '$CHOSEN_MAC' 2>/dev/null || true
                cmd wifi set-wifi-enabled disabled >/dev/null 2>&1
                sleep 2
                cmd wifi set-wifi-enabled enabled >/dev/null 2>&1
            fi
        "
    else
        exec_android_shell "
            cmd wifi set-wifi-enabled disabled >/dev/null 2>&1
            sleep 2
            cmd wifi set-wifi-enabled enabled >/dev/null 2>&1
        "
    fi

    echo -e "${C_BLUE}[5/5] Awaiting association and DHCP lease acquisition (up to 15s)...${C_RESET}"
    local waited=0
    while [[ $waited -lt 15 ]]; do
        sleep 1
        waited=$((waited + 1))
        gather_telemetry
        if [[ -n "$CUR_IP" ]]; then
            break
        fi
    done

    if [[ "$ROOT_MODE" -eq 1 ]]; then
        exec_android_root "rm -f '$STATIC_STATE_FILE'" >/dev/null 2>&1 || true
    fi

    echo "------------------------------------------------------------------"
    echo -e "${C_GREEN}${C_BOLD}✓ [REBORN COMPLETED] Ghost Identity Active!${C_RESET}"
    echo -e "  ${C_BOLD}• Wi-Fi SSID       :${C_RESET} ${C_CYAN}${CUR_SSID:-$old_ssid}${C_RESET}"
    echo -e "  ${C_BOLD}• MAC Rotation     :${C_RESET} ${C_DIM}${old_mac}${C_RESET} -> ${C_YELLOW}${CUR_MAC:-Unavailable}${C_RESET}"
    echo -e "  ${C_BOLD}• IP Rotation      :${C_RESET} ${C_DIM}${old_ip}${C_RESET} -> ${C_GREEN}${CUR_IP:-Pending DHCP lease}${C_RESET}"
    echo -e "  ${C_BOLD}• Decoy Hostname   :${C_RESET} ${C_WHITE}${DEV_NAME}${C_RESET} (net.hostname=${NET_HOST:-unset})"
    echo -e "  ${C_BOLD}• TCP/IP TTL       :${C_RESET} ${C_YELLOW}${CUR_TTL}${C_RESET}"
    echo -e "  ${C_BOLD}• New Android ID   :${C_RESET} ${C_MAGENTA}${AID}${C_RESET}"
    echo -e "  ${C_BOLD}• Network State    :${C_RESET} ${C_CYAN}${PORTAL_STATE}${C_RESET}"
    echo "------------------------------------------------------------------"
}

# ------------------------------------------------------------------------------
# Status Dashboard
# ------------------------------------------------------------------------------
show_status() {
    detect_privileges || return 1
    gather_telemetry
    echo -e "$BANNER"
    echo -e "${C_CYAN}=== Mobile Ghost Identity Status Dashboard ===${C_RESET}"
    echo -e "  ${C_BOLD}• Environment      :${C_RESET} ${C_WHITE}${ENV_MODE}${C_RESET}"
    echo -e "  ${C_BOLD}• Privilege Engine :${C_RESET} ${C_GREEN}${ROOT_DESC}${C_RESET}"
    echo -e "  ${C_BOLD}• Wi-Fi SSID       :${C_RESET} ${C_CYAN}${CUR_SSID:-Disconnected}${C_RESET} (Net ID: ${CUR_NETID:-N/A})"
    echo -e "  ${C_BOLD}• Device Name      :${C_RESET} ${C_GREEN}${DEV_NAME:-Unknown}${C_RESET}"
    echo -e "  ${C_BOLD}• DHCP Hostname    :${C_RESET} ${C_WHITE}${NET_HOST:-unset}${C_RESET}"
    echo -e "  ${C_BOLD}• Android ID       :${C_RESET} ${C_MAGENTA}${AID:-Unknown}${C_RESET}"
    echo -e "  ${C_BOLD}• Current IP       :${C_RESET} ${C_GREEN}${CUR_IP:-Disconnected}${C_RESET}"
    echo -e "  ${C_BOLD}• Current MAC      :${C_RESET} ${C_YELLOW}${CUR_MAC:-Unknown}${C_RESET}"
    echo -e "  ${C_BOLD}• TCP/IP TTL       :${C_RESET} ${C_YELLOW}${CUR_TTL}${C_RESET}"
    echo -e "  ${C_BOLD}• Portal Status    :${C_RESET} ${C_CYAN}${PORTAL_STATE}${C_RESET}"
    echo "------------------------------------------------------------------"
}

# ------------------------------------------------------------------------------
# Interactive Tactical Menu
# ------------------------------------------------------------------------------
interactive_menu() {
    while true; do
        clear 2>/dev/null || true
        show_status || return 1
        echo -e "${C_BOLD}${C_WHITE}Tactical Operations:${C_RESET}"
        echo -e "  ${C_CYAN}[1]${C_RESET} Full Reborn (Choose Persona + MAC + IP + Hostname + TTL + Browser Purge)"
        echo -e "  ${C_CYAN}[2]${C_RESET} Quick Random Reborn (Instant Rotation)"
        echo -e "  ${C_CYAN}[3]${C_RESET} Purge Mobile Browser Footprints (Chrome / Tor / Brave / Firefox)"
        echo -e "  ${C_CYAN}[4]${C_RESET} Toggle Static IP Stealth Mode (Root)"
        echo -e "  ${C_CYAN}[5]${C_RESET} Restore Original Device Baseline"
        echo -e "  ${C_RED}[0]${C_RESET} Exit"
        echo -ne "\n${C_YELLOW}Select [0-5]: ${C_RESET}"
        read -r opt

        case "$opt" in
            1)
                select_persona_interactive
                DO_BROWSER_CLEAN=1
                run_reborn
                ;;
            2)
                CHOSEN_NAME=""
                DO_BROWSER_CLEAN=0
                run_reborn
                ;;
            3) clean_browser_footprints ;;
            4) toggle_static_stealth ;;
            5) restore_baseline ;;
            0) exit 0 ;;
            *) echo -e "${C_RED}Invalid option.${C_RESET}" ;;
        esac
        echo -ne "\n${C_DIM}Press Enter to continue...${C_RESET}"
        read -r
    done
}

# ------------------------------------------------------------------------------
# CLI Dispatcher
# ------------------------------------------------------------------------------
detect_environment
OVERRIDE_TTL=""
DO_BROWSER_CLEAN=0
CHOSEN_NAME=""

ACTION="${1:-reborn}"
case "$ACTION" in
    reborn|--reborn|-r|--quick|-q)
        detect_privileges || exit 1
        if [[ "$ACTION" == "reborn" || "$ACTION" == "--reborn" || "$ACTION" == "-r" ]]; then
            DO_BROWSER_CLEAN=1
        fi
        run_reborn
        ;;
    --name|-n)
        if [[ -z "${2:-}" ]]; then
            echo -e "${C_RED}Error: Missing hostname after $1${C_RESET}" >&2
            exit 1
        fi
        detect_privileges || exit 1
        CHOSEN_NAME="$2"
        case "$CHOSEN_NAME" in
            *DESKTOP*|*Windows*|*PC*|*HP*|*ThinkPad*|*Dell*)
                CHOSEN_MAC=$(generate_mac "00:1b:77")
                CHOSEN_TTL="${3:-128}"
                CHOSEN_DESC="PC/Windows Stealth"
                ;;
            *iPhone*|*iPad*|*Apple*|*Mac*)
                CHOSEN_MAC=$(generate_mac "bc:d0:74")
                CHOSEN_TTL="${3:-64}"
                CHOSEN_DESC="Apple Stealth"
                ;;
            *)
                CHOSEN_MAC=$(generate_mac "")
                CHOSEN_TTL="${3:-64}"
                CHOSEN_DESC="Custom Stealth"
                ;;
        esac
        DO_BROWSER_CLEAN=1
        run_reborn
        ;;
    menu|--menu|-m|-i)
        detect_privileges || exit 1
        interactive_menu
        ;;
    status|--status|-s)
        show_status
        ;;
    restore|--restore)
        detect_privileges || exit 1
        restore_baseline
        ;;
    --browser-clean|-b)
        detect_privileges || exit 1
        clean_browser_footprints
        ;;
    --static-stealth)
        detect_privileges || exit 1
        toggle_static_stealth
        ;;
    shell|--shell)
        shift
        exec_android_shell "$*"
        ;;
    root-shell|--root-shell)
        shift
        detect_privileges || exit 1
        exec_privileged "$*"
        ;;
    help|--help|-h)
        echo -e "$BANNER"
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  reborn, -r, -q       Full identity rotation (MAC, IP, Hostname, TTL, SSAID, Browser) [Default]"
        echo "  --name, -n <NAME>    Rotate identity using a custom decoy hostname"
        echo "  menu, -m             Launch interactive tactical menu"
        echo "  status, -s           Display live mobile identity, MAC, IP, TTL & Portal status"
        echo "  --browser-clean, -b  Purge mobile browser caches, cookies & HSTS state (Root)"
        echo "  --static-stealth     Toggle silent Static IP mode bypassing DHCP (Root)"
        echo "  restore, --restore   Restore original saved baseline identity"
        echo "  shell <cmd>          Execute command via Android shell"
        echo "  root-shell <cmd>     Execute command with Root (uid=0)"
        echo "  help, -h             Show this help message"
        ;;
    *)
        detect_privileges || exit 1
        DO_BROWSER_CLEAN=1
        run_reborn
        ;;
esac
