#!/usr/bin/env bash
# ==============================================================================
#  ██████╗ ███████╗██████╗  ██████╗ ██████╗ ███╗   ██╗
#  ██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗████╗  ██║
#  ██████╔╝█████╗  ██████╔╝██║   ██║██████╔╝██╔██╗ ██║
#  ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║
#  ██║  ██║███████╗██████╔╝╚██████╔╝██║  ██║██║ ╚████║
#  ╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
#  REBORN-PRO: ANDROID ROOTLESS & PRoot EVASION ENGINE
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

BANNER="
${C_CYAN}${C_BOLD}  ██████╗ ███████╗██████╗  ██████╗ ██████╗ ███╗   ██╗
  ██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗████╗  ██║
  ██████╔╝█████╗  ██████╔╝██║   ██║██████╔╝██╔██╗ ██║
  ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║
  ██║  ██║███████╗██████╔╝╚██████╔╝██║  ██║██║ ╚████║
  ╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝${C_RESET}
${C_MAGENTA}${C_BOLD}  — REBORN MOBILE: ANDROID ROOTLESS & PROOT EVASION ENGINE —${C_RESET}
${C_DIM}  Architected by Mohammed Yaqeen (@PMoha1) | Knox 0x0 Safe & No-Root${C_RESET}
"

# ------------------------------------------------------------------------------
# Execution Context Auto-Detection
# ------------------------------------------------------------------------------
detect_environment() {
    if [[ -f "/etc/debian_version" || -f "/etc/kali_version" || -n "$PROOT_TMP_DIR" ]]; then
        ENV_MODE="PROOT_CONTAINER"
    elif [[ -n "$PREFIX" && "$PREFIX" == *com.termux* ]]; then
        ENV_MODE="TERMUX"
    elif [[ -f "/system/bin/sh" && -z "$PREFIX" ]]; then
        ENV_MODE="ANDROID_NATIVE"
    else
        ENV_MODE="WORKSTATION_REMOTE"
    fi
}

detect_environment

# ------------------------------------------------------------------------------
# ADB Execution Wrapper
# ------------------------------------------------------------------------------
exec_android_shell() {
    local cmd="$1"
    case "$ENV_MODE" in
        "ANDROID_NATIVE")
            /system/bin/sh -c "$cmd"
            ;;
        "TERMUX"|"PROOT_CONTAINER")
            # First attempt local loopback ADB
            if command -v adb &>/dev/null; then
                adb connect 127.0.0.1:5555 >/dev/null 2>&1 || true
                adb -s 127.0.0.1:5555 shell "$cmd" 2>/dev/null
            elif command -v rish &>/dev/null; then
                rish -c "$cmd"
            else
                echo -e "${C_RED}[!] Error: Neither ADB nor Shizuku (rish) found in environment.${C_RESET}"
                return 1
            fi
            ;;
        "WORKSTATION_REMOTE")
            adb shell "$cmd"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Core Reborn Execution Logic
# ------------------------------------------------------------------------------
run_reborn() {
    echo -e "$BANNER"
    echo -e "${C_YELLOW}${C_BOLD}[*] Mode Detected: ${C_WHITE}${ENV_MODE}${C_RESET}"
    echo -e "${C_CYAN}[+] Initiating Hardware MAC, Identity & Fingerprint Rotation...${C_RESET}"
    echo "------------------------------------------------------"

    # 1. Enforce Connected MAC Randomization
    echo -e "${C_BLUE}[1/5] Enforcing dynamic MAC randomization in Android Global Settings...${C_RESET}"
    exec_android_shell "settings put global wifi_connected_mac_randomization_enabled 1"

    # 2. Random Decoy Hostname Selection
    local personas=("iPhone-15-Pro" "iPad-Pro-M2" "Galaxy-S24-Ultra" "Pixel-8-Pro" "MacBook-Air" "Lenovo-ThinkPad-X1" "Dell-XPS-15" "HP-Spectre-x360")
    local rand_idx=$(( RANDOM % ${#personas[@]} ))
    local chosen_persona="${personas[$rand_idx]}"

    echo -e "${C_BLUE}[2/5] Injecting decoy device identity: ${C_GREEN}${chosen_persona}${C_RESET}"
    exec_android_shell "settings put global device_name '$chosen_persona'"
    exec_android_shell "settings put secure bluetooth_name '$chosen_persona'"

    # 3. Cryptographic Android ID (SSAID) Rotation
    local new_aid
    new_aid=$(od -An -N8 -tx8 /dev/urandom 2>/dev/null | tr -d ' \n' || head -c 16 /dev/urandom | xxd -p)
    echo -e "${C_BLUE}[3/5] Rotating Android ID (SSAID): ${C_MAGENTA}${new_aid}${C_RESET}"
    exec_android_shell "settings put secure android_id '$new_aid'"

    # 4. Flush Network / ARP Tables & Reset Wi-Fi Interface
    echo -e "${C_BLUE}[4/5] Recycling Wi-Fi subsystem to trigger DHCP release & renew...${C_RESET}"
    exec_android_shell "cmd wifi set-wifi-enabled disabled"
    sleep 2
    exec_android_shell "cmd wifi set-wifi-enabled enabled"

    # 5. Await Link Negotiation & Fetch New Credentials
    echo -e "${C_BLUE}[5/5] Awaiting association and DHCP lease acquisition (5s)...${C_RESET}"
    sleep 5

    # Flush container ARP cache if in PRoot/Termux
    ip neigh flush all 2>/dev/null || true

    local new_ip
    new_ip=$(exec_android_shell "ip -f inet addr show wlan0 2>/dev/null | grep inet | awk '{print \$2}'")
    local new_mac
    new_mac=$(exec_android_shell "ip link show wlan0 2>/dev/null | grep link/ether | awk '{print \$2}'")

    echo "------------------------------------------------------"
    echo -e "${C_GREEN}${C_BOLD}✓ [REBORN COMPLETED] New Ghost Identity Active!${C_RESET}"
    echo -e "  ${C_BOLD}• New IP Address   :${C_RESET} ${C_WHITE}${new_ip:-Pending DHCP lease}${C_RESET}"
    echo -e "  ${C_BOLD}• New MAC Address  :${C_RESET} ${C_YELLOW}${new_mac:-Randomized dynamically}${C_RESET}"
    echo -e "  ${C_BOLD}• Decoy Hostname   :${C_RESET} ${C_CYAN}${chosen_persona}${C_RESET}"
    echo -e "  ${C_BOLD}• New Android ID   :${C_RESET} ${C_MAGENTA}${new_aid}${C_RESET}"
    echo "------------------------------------------------------"
}

# ------------------------------------------------------------------------------
# Status Dashboard
# ------------------------------------------------------------------------------
show_status() {
    echo -e "$BANNER"
    echo -e "${C_CYAN}=== Mobile Identity Status Dashboard ===${C_RESET}"
    echo -e "  ${C_BOLD}• Environment      :${C_RESET} ${C_WHITE}${ENV_MODE}${C_RESET}"
    
    local dev_name
    dev_name=$(exec_android_shell "settings get global device_name" 2>/dev/null || echo "Unknown")
    local aid
    aid=$(exec_android_shell "settings get secure android_id" 2>/dev/null || echo "Unknown")
    local cur_ip
    cur_ip=$(exec_android_shell "ip -f inet addr show wlan0 2>/dev/null | grep inet | awk '{print \$2}'" || echo "Disconnected")
    local cur_mac
    cur_mac=$(exec_android_shell "ip link show wlan0 2>/dev/null | grep link/ether | awk '{print \$2}'" || echo "Unknown")

    echo -e "  ${C_BOLD}• Device Name      :${C_RESET} ${C_GREEN}${dev_name}${C_RESET}"
    echo -e "  ${C_BOLD}• Android ID       :${C_RESET} ${C_MAGENTA}${aid}${C_RESET}"
    echo -e "  ${C_BOLD}• Current IP       :${C_RESET} ${C_WHITE}${cur_ip}${C_RESET}"
    echo -e "  ${C_BOLD}• Current MAC      :${C_RESET} ${C_YELLOW}${cur_mac}${C_RESET}"
    echo "------------------------------------------------------"
}

# ------------------------------------------------------------------------------
# CLI Dispatcher
# ------------------------------------------------------------------------------
case "${1:-reborn}" in
    reborn|--reborn|-r)
        run_reborn
        ;;
    status|--status|-s)
        show_status
        ;;
    shell|--shell)
        shift
        exec_android_shell "$@"
        ;;
    help|--help|-h)
        echo -e "$BANNER"
        echo -e "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  reborn, -r     Rotate hardware MAC, Android ID, and acquire new DHCP IP (Default)"
        echo "  status, -s     Display current mobile identity, IP, and MAC status"
        echo "  shell <cmd>    Execute arbitrary Android shell command via ADB loopback"
        echo "  help, -h       Show this guidance message"
        ;;
    *)
        run_reborn
        ;;
esac
