#!/usr/bin/env bash
# ==============================================================================
#  ██████╗ ███████╗██████╗  ██████╗ ██████╗ ███╗   ██╗
#  ██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗████╗  ██║
#  ██████╔╝█████╗  ██████╔╝██║   ██║██████╔╝██╔██╗ ██║
#  ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║
#  ██║  ██║███████╗██████╔╝╚██████╔╝██║  ██║██║ ╚████║
#  ╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
#  GHOST IDENTITY & FINGERPRINT ERASER FOR LINUX / ARCH / CACHYOS
# ==============================================================================

set -o pipefail

# ------------------------------------------------------------------------------
# OS Detection (Linux / Windows WSL / Termux)
# ------------------------------------------------------------------------------
detect_os() {
    OS_TYPE="Linux"
    if [[ -n "$PREFIX" && "$PREFIX" == *com.termux* ]]; then
        OS_TYPE="Termux"
    elif [[ -n "$WINDIR" || -n "$WSL_DISTRO_NAME" ]]; then
        OS_TYPE="Windows"
    fi
}
detect_os


# Colors
C_RESET="\e[0m"
C_BOLD="\e[1m"
C_DIM="\e[2m"
C_RED="\e[31m"
C_GREEN="\e[32m"
C_YELLOW="\e[33m"
C_BLUE="\e[34m"
C_MAGENTA="\e[35m"
C_CYAN="\e[36m"
C_WHITE="\e[37m"

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
if [[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]]; then
    TARGET_HOME="${HOME:-/root}"
fi
CONFIG_DIR="${TARGET_HOME}/.config/reborn"
BASELINE_FILE="${CONFIG_DIR}/original_baseline.conf"
NM_CONF_FILE="/etc/NetworkManager/conf.d/90-mac-randomization.conf"

mkdir -p "$CONFIG_DIR" 2>/dev/null || true

# ------------------------------------------------------------------------------
# Helper: Check Root / Sudo
# ------------------------------------------------------------------------------
run_root() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

launch_default_browser() {
    local target_url="${1:-}"
    local b_cmd=""

    if command -v google-chrome &>/dev/null; then
        b_cmd="google-chrome"
    elif command -v google-chrome-stable &>/dev/null; then
        b_cmd="google-chrome-stable"
    elif command -v chromium &>/dev/null; then
        b_cmd="chromium"
    elif command -v chromium-browser &>/dev/null; then
        b_cmd="chromium-browser"
    elif command -v firefox-esr &>/dev/null; then
        b_cmd="firefox-esr"
    elif command -v firefox &>/dev/null; then
        b_cmd="firefox"
    elif command -v brave &>/dev/null; then
        b_cmd="brave"
    elif command -v x-www-browser &>/dev/null; then
        b_cmd="x-www-browser"
    fi

    if [[ -z "$b_cmd" ]]; then
        echo -e "${C_RED}❌ لم يتم العثور على أي متصفح مثبت في النظام!${C_RESET}"
        return 1
    fi

    export DISPLAY="${DISPLAY:-:0}"

    # Launch cleanly without root sandbox crashes
    if [[ "$EUID" -eq 0 ]]; then
        if [[ -n "$SUDO_USER" && "$SUDO_USER" != "root" ]]; then
            local user_xauth="${TARGET_HOME}/.Xauthority"
            if [[ -f "$user_xauth" ]]; then
                export XAUTHORITY="$user_xauth"
            fi
            nohup sudo -u "$SUDO_USER" DISPLAY="$DISPLAY" XAUTHORITY="${XAUTHORITY:-$user_xauth}" "$b_cmd" ${target_url:+"$target_url"} >/dev/null 2>&1 &
        else
            local root_flags=""
            if [[ "$b_cmd" == *"chrome"* || "$b_cmd" == *"chromium"* || "$b_cmd" == *"brave"* ]]; then
                root_flags="--no-sandbox --test-type"
            fi
            nohup "$b_cmd" $root_flags ${target_url:+"$target_url"} >/dev/null 2>&1 &
        fi
    else
        nohup "$b_cmd" ${target_url:+"$target_url"} >/dev/null 2>&1 &
    fi
}

set_ttl() {
    local ttl_val="$1"
    run_root sysctl -w "net.ipv4.ip_default_ttl=${ttl_val}" >/dev/null 2>&1 || true
}

# ------------------------------------------------------------------------------
# Helper: Fix Browser Singleton Locks (Crucial after hostname changes)
# ------------------------------------------------------------------------------
fix_browser_locks() {
    # 1. Kill any zombie browser processes holding locks
    pkill -9 -f "chrome" 2>/dev/null || true
    pkill -9 -f "chromium" 2>/dev/null || true
    pkill -9 -f "firefox" 2>/dev/null || true
    sleep 0.3

    # 2. Destroy Chromium / Chrome Singleton locks and sockets across user and root configs
    local config_dirs=("${TARGET_HOME}/.config" "/root/.config")
    for cfg in "${config_dirs[@]}"; do
        rm -f "$cfg"/google-chrome/Singleton* 2>/dev/null || true
        rm -f "$cfg"/google-chrome/*/Singleton* 2>/dev/null || true
        rm -f "$cfg"/chromium/Singleton* 2>/dev/null || true
        rm -f "$cfg"/chromium/*/Singleton* 2>/dev/null || true
        rm -f "$cfg"/BraveSoftware/Brave-Browser/Singleton* 2>/dev/null || true
        rm -f "$cfg"/microsoft-edge/Singleton* 2>/dev/null || true
    done

    # 3. Clean temporary lock sockets in /tmp
    rm -rf /tmp/com.google.Chrome.* /tmp/.com.google.Chrome.* 2>/dev/null || true
    rm -rf /tmp/.org.chromium.Chromium.* /tmp/org.chromium.Chromium.* 2>/dev/null || true

    # 4. Clean Firefox locks
    rm -f "${TARGET_HOME}/.mozilla/firefox/"*/*.lock 2>/dev/null || true
    rm -f "${TARGET_HOME}/.mozilla/firefox/"*/.parentlock 2>/dev/null || true
    rm -f /root/.mozilla/firefox/*/*.lock 2>/dev/null || true
    rm -f /root/.mozilla/firefox/*/.parentlock 2>/dev/null || true

    # 5. Fix permissions if root ran before (restore ownership to desktop user)
    if [[ -n "$TARGET_USER" && "$TARGET_USER" != "root" && "$EUID" -eq 0 ]]; then
        chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.config/google-chrome" 2>/dev/null || true
        chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.config/chromium" 2>/dev/null || true
        chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.mozilla" 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# Detect Active Network Interface & Connection
# ------------------------------------------------------------------------------
detect_network() {
    ACTIVE_DEV=$(nmcli -t -f DEVICE,TYPE,STATE dev status 2>/dev/null | grep ":wifi:connected" | head -n 1 | cut -d: -f1 || true)
    if [[ -z "$ACTIVE_DEV" ]]; then
        ACTIVE_DEV=$(nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | grep ":wifi$" | head -n 1 | cut -d: -f1 || true)
    fi
    if [[ -z "$ACTIVE_DEV" ]]; then
        ACTIVE_DEV=$(nmcli -t -f DEVICE,TYPE,STATE dev status 2>/dev/null | grep ":ethernet:connected" | head -n 1 | cut -d: -f1 || true)
    fi

    if [[ -n "$ACTIVE_DEV" ]]; then
        ACTIVE_CON=$(nmcli -t -f NAME,DEVICE con show --active 2>/dev/null | grep ":${ACTIVE_DEV}$" | head -n 1 | cut -d: -f1 || true)
        CURRENT_MAC=$(cat "/sys/class/net/${ACTIVE_DEV}/address" 2>/dev/null || echo "Unknown")
        CURRENT_IP=$(ip -4 addr show "$ACTIVE_DEV" 2>/dev/null | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -n 1 || echo "None")
    else
        ACTIVE_CON=""
        CURRENT_MAC="Unknown"
        CURRENT_IP="None"
    fi

    CURRENT_HOSTNAME=$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "Unknown")
    CURRENT_MACHINE_ID=$(cat /etc/machine-id 2>/dev/null || echo "Unknown")
}

# ------------------------------------------------------------------------------
# Save Baseline Identity (First Run Only)
# ------------------------------------------------------------------------------
save_baseline() {
    if [[ ! -f "$BASELINE_FILE" ]]; then
        detect_network
        local perm_mac="$CURRENT_MAC"
        if [[ -n "$ACTIVE_DEV" ]] && command -v ethtool &>/dev/null; then
            local ethtool_mac
            ethtool_mac=$(ethtool -P "$ACTIVE_DEV" 2>/dev/null | awk "{print \$3}" || true)
            if [[ -n "$ethtool_mac" && "$ethtool_mac" != "00:00:00:00:00:00" ]]; then
                perm_mac="$ethtool_mac"
            fi
        fi

        cat <<EOF > "$BASELINE_FILE"
ORIGINAL_HOSTNAME="${CURRENT_HOSTNAME}"
ORIGINAL_HARDWARE_MAC="${perm_mac}"
ORIGINAL_MACHINE_ID="${CURRENT_MACHINE_ID}"
ORIGINAL_DEV="${ACTIVE_DEV}"
ORIGINAL_CON="${ACTIVE_CON}"
SAVED_AT="$(date "+%Y-%m-%d %H:%M:%S")"
EOF
        chown "${TARGET_USER}:${TARGET_USER}" "$BASELINE_FILE" 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# Generate Valid MAC with Vendor OUI or Random
# ------------------------------------------------------------------------------
generate_mac() {
    local prefix="$1"
    if [[ -z "$prefix" ]]; then
        printf "02:%02x:%02x:%02x:%02x:%02x\n" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
    else
        printf "%s:%02x:%02x:%02x\n" "$prefix" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
    fi
}

# ------------------------------------------------------------------------------
# Random Hostname Generators
# ------------------------------------------------------------------------------
random_win_hostname() {
    local chars="0123456789ABCDEF"
    local suffix=""
    for i in {1..7}; do
        suffix+="${chars:$((RANDOM % 16)):1}"
    done
    echo "DESKTOP-${suffix}"
}

random_android_hostname() {
    local chars="0123456789abcdef"
    local suffix=""
    for i in {1..10}; do
        suffix+="${chars:$((RANDOM % 16)):1}"
    done
    echo "android-${suffix}"
}

# ------------------------------------------------------------------------------
# Apply Network Identity (MAC + Hostname + DHCP Spoofing + IP Renewal)
# ------------------------------------------------------------------------------
apply_network_identity() {
    local new_name="$1"
    local new_mac="$2"
    local persona_desc="$3"

    echo -e "\n${C_CYAN}═════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_MAGENTA}⚡ جارٍ تطبيق الهوية الجديدة على الشبكة: ${C_YELLOW}${new_name}${C_RESET} (${persona_desc})"
    echo -e "${C_CYAN}═════════════════════════════════════════════════════════════════${C_RESET}"

    detect_network

    # 1. Update System Hostname
    echo -e "${C_BLUE}▸ [1/5] تغيير اسم مضيف النظام (System Hostname)...${C_RESET}"
    run_root hostnamectl set-hostname "$new_name"

    # 1.1 Adjust TTL (OS Fingerprint Evasion for MikroTik / NAC)
    case "$persona_desc" in
        *Windows*)
            echo -e "${C_BLUE}▸ [1.5/5] مطابقة قيمة TTL إلى 128 (محاكاة بصمة ويندوز الصادرة لتمويه ميكروتك)...${C_RESET}"
            set_ttl 128
            ;;
        *Apple*|*iPhone*|*iPad*|*Android*|*Samsung*)
            echo -e "${C_BLUE}▸ [1.5/5] مطابقة قيمة TTL إلى 64 (محاكاة بصمة الهاتف/التابلت)...${C_RESET}"
            set_ttl 64
            ;;
        *)
            echo -e "${C_BLUE}▸ [1.5/5] مطابقة قيمة TTL إلى 128 (Windows Stealth Default)...${C_RESET}"
            set_ttl 128
            ;;
    esac

    # Update /etc/hosts to keep sudo & local resolution instant
    echo -e "${C_BLUE}▸ [2/5] تحديث ملف المضيفين (/etc/hosts)...${C_RESET}"
    if grep -qE "^127\.0\.0\.1\s+localhost" /etc/hosts; then
        run_root sed -i -E "s/^127\.0\.0\.1\s+localhost.*/127.0.0.1 localhost ${new_name}/" /etc/hosts 2>/dev/null || true
    else
        echo "127.0.0.1 localhost ${new_name}" | run_root tee -a /etc/hosts >/dev/null
    fi

    # Immediately clear browser SingletonLocks because hostname changed
    fix_browser_locks

    # 2. Configure NetworkManager
    if [[ -n "$ACTIVE_CON" ]]; then
        echo -e "${C_BLUE}▸ [3/5] حقن الماك الجديد (${C_GREEN}${new_mac}${C_BLUE}) في اتصال (${C_YELLOW}${ACTIVE_CON}${C_BLUE})...${C_RESET}"
        nmcli con mod "$ACTIVE_CON" 802-11-wireless.cloned-mac-address "$new_mac" 2>/dev/null ||         nmcli con mod "$ACTIVE_CON" wifi.cloned-mac-address "$new_mac" 2>/dev/null || true

        echo -e "${C_BLUE}▸ [4/5] حقن اسم التمويه في طلب الـ DHCP وتفعيل حماية IPv6...${C_RESET}"
        nmcli con mod "$ACTIVE_CON" ipv4.dhcp-hostname "$new_name"
        nmcli con mod "$ACTIVE_CON" ipv4.dhcp-send-hostname yes
        nmcli con mod "$ACTIVE_CON" ipv4.dhcp-client-id "mac"
        nmcli con mod "$ACTIVE_CON" ipv6.dhcp-send-hostname yes
        nmcli con mod "$ACTIVE_CON" ipv6.dhcp-hostname "$new_name"
        nmcli con mod "$ACTIVE_CON" ipv6.ip6-privacy 2
        nmcli con mod "$ACTIVE_CON" ipv6.addr-gen-mode stable-privacy

        # 3. Disable mDNS and LLMNR local broadcasts
        if [[ -n "$ACTIVE_DEV" ]]; then
            run_root resolvectl mdns "$ACTIVE_DEV" no 2>/dev/null || true
            run_root resolvectl llmnr "$ACTIVE_DEV" no 2>/dev/null || true
        fi

        # 4. Flush Caches
        echo -e "${C_BLUE}▸ [5/5] تفريغ كاش الـ DNS وجدول الـ ARP وإعادة الاتصال بالراوتر...${C_RESET}"
        run_root resolvectl flush-caches 2>/dev/null || true
        run_root ip neigh flush all 2>/dev/null || true

        # Reconnect to apply and force router DHCP server to assign new IP
        echo -e "${C_YELLOW}⟳ جارٍ تجديد الاتصال بالراوتر لسحب IP جديد تماماً...${C_RESET}"
        nmcli con up "$ACTIVE_CON" >/dev/null 2>&1 || true
        sleep 2
    else
        echo -e "${C_YELLOW}⚠ لم يتم العثور على اتصال نشط حالياً، تم تحديث اسم النظام فقط.${C_RESET}"
    fi

    # Verification
    detect_network
    echo -e "\n${C_GREEN}${C_BOLD}✔ تم بنجاح! النتيجة الظاهرة للراوتر الآن:${C_RESET}"
    echo -e "  • اسم الجهاز في الراوتر: ${C_BOLD}${C_WHITE}${CURRENT_HOSTNAME}${C_RESET}"
    echo -e "  • عنوان الماك (MAC):     ${C_BOLD}${C_YELLOW}${CURRENT_MAC}${C_RESET}"
    echo -e "  • عنوان الآي بي الجديد: ${C_BOLD}${C_GREEN}${CURRENT_IP}${C_RESET}"
    echo -e "  • كرت الشبكة المستخدم:   ${C_CYAN}${ACTIVE_DEV}${C_RESET} (شبكة: ${ACTIVE_CON})"
}

# ------------------------------------------------------------------------------
# Reset Linux Machine ID (Deep OS Fingerprint)
# ------------------------------------------------------------------------------
reset_machine_id() {
    echo -e "\n${C_MAGENTA}▸ تصفير وتوليد معرف النظام العالمي (Machine-ID)...${C_RESET}"
    local old_id
    old_id=$(cat /etc/machine-id 2>/dev/null || echo "None")
    local new_id
    new_id=$(openssl rand -hex 16)
    
    echo "$new_id" | run_root tee /etc/machine-id >/dev/null
    if [[ -L /var/lib/dbus/machine-id || -f /var/lib/dbus/machine-id ]]; then
        run_root ln -sf /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true
    fi
    run_root systemd-machine-id-setup --commit 2>/dev/null || true

    echo -e "  • المعرف القديم: ${C_RED}${old_id}${C_RESET}"
    echo -e "  • المعرف الجديد: ${C_GREEN}${new_id}${C_RESET}"
    echo -e "${C_GREEN}✔ تم محو بصمة النظام العميقة بنجاح.${C_RESET}"
}

# ------------------------------------------------------------------------------
# Clean Browser & App Footprints
# ------------------------------------------------------------------------------
clean_browser_footprints() {
    echo -e "\n${C_MAGENTA}▸ تطهير بصمات المتصفح والتطبيقات...${C_RESET}"

    # Close active browsers if running
    for b_proc in chrome google-chrome chromium firefox firefox-esr brave; do
        if pgrep -x "$b_proc" >/dev/null 2>&1 || pgrep -f "$b_proc" >/dev/null 2>&1; then
            echo -e "${C_YELLOW}⚠ إغلاق المتصفح ($b_proc) لتفريغ البصمات والأقفال...${C_RESET}"
            pkill -15 -x "$b_proc" 2>/dev/null || true
            sleep 0.5
            pkill -9 -x "$b_proc" 2>/dev/null || true
        fi
    done

    # Purge Singleton Locks to guarantee Chrome will open under new hostname
    fix_browser_locks

    local chrome_dir="${TARGET_HOME}/.config/google-chrome"
    local chrome_cache="${TARGET_HOME}/.cache/google-chrome"
    local ff_dir="${TARGET_HOME}/.mozilla/firefox"
    local ff_cache="${TARGET_HOME}/.cache/mozilla/firefox"

    # 1. Purge Crash Reports & Telemetry UUIDs
    if [[ -d "${chrome_dir}/Crash Reports" ]]; then
        rm -rf "${chrome_dir}/Crash Reports"/* 2>/dev/null || true
        echo -e "  ${C_GREEN}✔${C_RESET} تم حذف ملفات تتبع Crash Reports و Client UUIDs."
    fi
    rm -f "${chrome_dir}"/CrashpadMetrics* 2>/dev/null || true

    # 2. Clean Web Caches, Code Cache, GPU Cache
    if [[ -d "$chrome_cache" ]]; then
        rm -rf "$chrome_cache"/* 2>/dev/null || true
        echo -e "  ${C_GREEN}✔${C_RESET} تم مسح Web Cache و Code Cache بالكامل."
    fi

    if [[ -d "${chrome_dir}/Default" ]]; then
        rm -rf "${chrome_dir}/Default/GPUCache"/* 2>/dev/null || true
        rm -rf "${chrome_dir}/Default/Service Worker"/* 2>/dev/null || true
        rm -f "${chrome_dir}/Default/Network/Network Persistent State" 2>/dev/null || true
        rm -f "${chrome_dir}/Default/TransportSecurity" 2>/dev/null || true
        echo -e "  ${C_GREEN}✔${C_RESET} تم حذف كاشات الـ GPU ومخلفات HSTS Supercookies."
    fi

    # 3. Clean Firefox profile caches if present
    if [[ -d "$ff_dir" ]]; then
        rm -rf "$ff_cache"/* 2>/dev/null || true
        find "$ff_dir" -name "sessionstore.jsonlz4" -delete 2>/dev/null || true
        find "$ff_dir" -name "recovery.jsonlz4" -delete 2>/dev/null || true
        echo -e "  ${C_GREEN}✔${C_RESET} تم تفريغ كاشات وجلسات متصفح فيرفوكس (Firefox)."
    fi

    # 4. Clean Thumbnail & Shader caches
    rm -rf "${TARGET_HOME}/.cache/thumbnails"/* 2>/dev/null || true
    rm -rf "${TARGET_HOME}/.cache/mesa_shader_cache"/* 2>/dev/null || true
    rm -f "${TARGET_HOME}/.local/share/recently-used.xbel" 2>/dev/null || true

    # Final lock cleanup
    fix_browser_locks

    echo -e "${C_GREEN}✔ تم تطهير بصمات المتصفح وفك جميع أقفال الجلسات بنجاح.${C_RESET}"
}

# ------------------------------------------------------------------------------
# Launch Ephemeral Ghost Browser in RAM
# ------------------------------------------------------------------------------
launch_ghost_chrome() {
    local tmp_profile
    tmp_profile=$(mktemp -d /tmp/ghost-chrome-XXXXXX)
    echo -e "\n${C_CYAN}👻 جارٍ إطلاق متصفح شبحي معزول 100% في الذاكرة العشوائية (RAM)...${C_RESET}"
    echo -e "   المسار المؤقت: ${C_DIM}${tmp_profile}${C_RESET}"
    echo -e "   ${C_GREEN}• صفر كوكيز سابقة | صفر بصمات | عزل تام | ينحذف كلياً عند الإغلاق.${C_RESET}"

    nohup google-chrome \
        --user-data-dir="$tmp_profile" \
        --no-first-run \
        --no-default-browser-check \
        --disable-sync \
        --disable-breakpad \
        --disable-metrics \
        --disable-component-update \
        --disable-features=OptimizationGuideModelDownloading,OptimizationHints,MediaRouter \
        --incognito \
        "https://browserleaks.com/ip" >/dev/null 2>&1 &

    echo -e "${C_GREEN}✔ تم تشغيل المتصفح الشبحي بنجاح.${C_RESET}"
}

# ------------------------------------------------------------------------------
# Toggle Permanent MAC Randomization (NetworkManager global config)
# ------------------------------------------------------------------------------
toggle_permanent_rand() {
    if [[ -f "$NM_CONF_FILE" ]]; then
        echo -e "\n${C_YELLOW}⚠ التمويه الدائم التلقائي مفعّل حالياً. هل تريد إلغاء تفعيله؟ [y/N]: ${C_RESET}"
        read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            run_root rm -f "$NM_CONF_FILE"
            run_root systemctl reload NetworkManager 2>/dev/null || true
            echo -e "${C_GREEN}✔ تم إلغاء التمويه الدائم التلقائي بنجاح.${C_RESET}"
        fi
    else
        echo -e "\n${C_CYAN}⚙ تفعيل التمويه الدائم التلقائي في NetworkManager...${C_RESET}"
        echo -e "هذا سيجعل النظام يولد MAC عشوائي جديد تماماً عند كل اتصال بأي شبكة واي فاي تلقائياً."
        
        cat <<EOF | run_root tee "$NM_CONF_FILE" >/dev/null
[device-mac-randomization]
wifi.scan-rand-mac-address=yes

[connection-mac-randomization]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
EOF
        run_root systemctl reload NetworkManager 2>/dev/null || true
        echo -e "${C_GREEN}✔ تم حفظ وتفعيل التمويه التلقائي الدائم بنجاح.${C_RESET}"
    fi
}

# ------------------------------------------------------------------------------
# Restore Original Baseline Identity
# ------------------------------------------------------------------------------
restore_baseline() {
    if [[ ! -f "$BASELINE_FILE" ]]; then
        echo -e "${C_RED}❌ لا يوجد ملف هوية أصلية محفوظ.${C_RESET}"
        return 1
    fi

    # Source baseline
    # shellcheck disable=SC1090
    source "$BASELINE_FILE"

    echo -e "\n${C_YELLOW}═════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}🔄 جارٍ استعادة الهوية الأصلية للجهاز...${C_RESET}"
    echo -e "  • الاسم الأصلي:  ${C_CYAN}${ORIGINAL_HOSTNAME}${C_RESET}"
    echo -e "  • الماك الأصلي:  ${C_CYAN}${ORIGINAL_HARDWARE_MAC}${C_RESET}"
    echo -e "${C_YELLOW}═════════════════════════════════════════════════════════════════${C_RESET}"

    # Restore Hostname & Default TTL
    run_root hostnamectl set-hostname "$ORIGINAL_HOSTNAME"
    set_ttl 64
    if grep -qE "^127\.0\.0\.1\s+localhost" /etc/hosts; then
        run_root sed -i -E "s/^127\.0\.0\.1\s+localhost.*/127.0.0.1 localhost ${ORIGINAL_HOSTNAME}/" /etc/hosts 2>/dev/null || true
    fi

    # Fix browser locks for restored hostname
    fix_browser_locks

    # Restore Machine ID
    if [[ -n "$ORIGINAL_MACHINE_ID" ]]; then
        echo "$ORIGINAL_MACHINE_ID" | run_root tee /etc/machine-id >/dev/null
        run_root ln -sf /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true
    fi

    # Reset Connection MAC and DHCP Hostname
    detect_network
    if [[ -n "$ACTIVE_CON" ]]; then
        nmcli con mod "$ACTIVE_CON" 802-11-wireless.cloned-mac-address "" 2>/dev/null || true
        nmcli con mod "$ACTIVE_CON" wifi.cloned-mac-address "" 2>/dev/null || true
        nmcli con mod "$ACTIVE_CON" ipv4.dhcp-hostname "" 2>/dev/null || true
        nmcli con mod "$ACTIVE_CON" ipv4.dhcp-client-id "" 2>/dev/null || true
        nmcli con mod "$ACTIVE_CON" ipv6.dhcp-hostname "" 2>/dev/null || true
        run_root resolvectl flush-caches 2>/dev/null || true
        run_root ip neigh flush all 2>/dev/null || true
        nmcli con up "$ACTIVE_CON" >/dev/null 2>&1 || true
    fi

    echo -e "${C_GREEN}${C_BOLD}✔ تم استعادة الهوية الأصلية للجهاز بنجاح!${C_RESET}"
}

# ------------------------------------------------------------------------------
# Display Detailed Live Dashboard
# ------------------------------------------------------------------------------
show_status_dashboard() {
    detect_network

    local vendor="Unknown / Random"
    local mac_prefix
    mac_prefix=$(echo "$CURRENT_MAC" | tr "[:lower:]" "[:upper:]" | cut -d: -f1-3)
    case "$mac_prefix" in
        "74:97:79") vendor="ASUS / AzureWave (Original Hardware)" ;;
        "BC:D0:74"|"F0:18:98"|"38:F9:D3"|"A4:C3:61") vendor="Apple, Inc. (Spoofed)" ;;
        "5C:E8:EB"|"A8:9C:ED"|"34:7E:5C") vendor="Samsung Electronics (Spoofed)" ;;
        "00:1B:77"|"68:05:71"|"80:86:F2") vendor="Intel Corporation (Spoofed)" ;;
        "00:0E:7F") vendor="HP Inc. (Spoofed)" ;;
        "00:05:CD") vendor="LG Electronics (Spoofed)" ;;
        02:*|06:*|0A:*|0E:*|*2:*|*6:*|*A:*|*E:*) vendor="Locally Administered (Random Stealth)" ;;
    esac

    local perm_rand_status="${C_RED}غير مفعّل${C_RESET}"
    if [[ -f "$NM_CONF_FILE" ]]; then
        perm_rand_status="${C_GREEN}مفعّل تلقائياً دائماً${C_RESET}"
    fi

    echo -e "\n${C_CYAN}┌───────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_CYAN}│${C_RESET} ${C_BOLD}${C_MAGENTA}⚡ كشف البصمات الحالية لجهازك (كما يراها الراوتر والشبكة) ⚡${C_RESET}  ${C_CYAN}│${C_RESET}"
    echo -e "${C_CYAN}├───────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_CYAN}│${C_RESET} %-25s : ${C_BOLD}${C_WHITE}%-32s${C_RESET} ${C_CYAN}│${C_RESET}\n" "🖥️ اسم الجهاز في الراوتر" "$CURRENT_HOSTNAME"
    printf "${C_CYAN}│${C_RESET} %-25s : ${C_BOLD}${C_YELLOW}%-32s${C_RESET} ${C_CYAN}│${C_RESET}\n" "🛡️ عنوان الماك (MAC)" "$CURRENT_MAC"
    printf "${C_CYAN}│${C_RESET} %-25s : ${C_DIM}%-32s${C_RESET} ${C_CYAN}│${C_RESET}\n" "🏭 مصنع كرت الشبكة (Vendor)" "$vendor"
    printf "${C_CYAN}│${C_RESET} %-25s : ${C_BOLD}${C_GREEN}%-32s${C_RESET} ${C_CYAN}│${C_RESET}\n" "🌐 عنوان الآي بي (IPv4)" "$CURRENT_IP"
    local current_ttl
    current_ttl=$(cat /proc/sys/net/ipv4/ip_default_ttl 2>/dev/null || echo "64")
    local ttl_desc="Linux (64)"
    if [[ "$current_ttl" -eq 128 ]]; then
        ttl_desc="Windows Stealth (128)"
    fi
    printf "${C_CYAN}│${C_RESET} %-25s : ${C_BOLD}${C_YELLOW}%-32s${C_RESET} ${C_CYAN}│${C_RESET}\n" "⏱️ بصمة الـ TTL الشبكية" "$current_ttl ($ttl_desc)"
    printf "${C_CYAN}│${C_RESET} %-25s : %-32s ${C_CYAN}│${C_RESET}\n" "📡 شبكة الواي فاي الحالية" "${ACTIVE_CON:-None} (${ACTIVE_DEV:-None})"
    printf "${C_CYAN}│${C_RESET} %-25s : ${C_DIM}%-32s${C_RESET} ${C_CYAN}│${C_RESET}\n" "🔑 معرف النظام (Machine ID)" "${CURRENT_MACHINE_ID:0:16}..."
    printf "${C_CYAN}│${C_RESET} %-25s : %-41b ${C_CYAN}│${C_RESET}\n" "⚙️ التمويه الدائم التلقائي" "$perm_rand_status"
    echo -e "${C_CYAN}└───────────────────────────────────────────────────────────────┘${C_RESET}"
}

# ------------------------------------------------------------------------------
# Persona Selection Submenu
# ------------------------------------------------------------------------------
select_persona() {
    echo -e "\n${C_BOLD}${C_CYAN}اختر هوية الجهاز التي تريد أن تظهر لصاحب الراوتر والشبكة:${C_RESET}"
    echo -e "  ${C_GREEN}[1]${C_RESET} 🍏 ${C_BOLD}Apple iPhone 16 Pro${C_RESET}       (MAC: Apple OUI)"
    echo -e "  ${C_GREEN}[2]${C_RESET} 🍏 ${C_BOLD}Apple iPad Air${C_RESET}             (MAC: Apple OUI)"
    echo -e "  ${C_GREEN}[3]${C_RESET} 📱 ${C_BOLD}Samsung Galaxy S24 Ultra${C_RESET}   (MAC: Samsung OUI)"
    echo -e "  ${C_GREEN}[4]${C_RESET} 💻 ${C_BOLD}Windows 11 Laptop${C_RESET}          (MAC: Intel OUI - DESKTOP-XXXX)"
    echo -e "  ${C_GREEN}[5]${C_RESET} 🖨️ ${C_BOLD}HP LaserJet Pro Printer${C_RESET}    (MAC: HP OUI)"
    echo -e "  ${C_GREEN}[6]${C_RESET} 📺 ${C_BOLD}LG Smart TV (webOS)${C_RESET}        (MAC: LG OUI)"
    echo -e "  ${C_GREEN}[7]${C_RESET} 🎲 ${C_BOLD}شبح عشوائي كامل (Android)${C_RESET}  (Random MAC)"
    echo -e "  ${C_GREEN}[8]${C_RESET} ✍️ ${C_BOLD}كتابة اسم مخصص بيدك${C_RESET}         (Custom Name)"
    echo -ne "\n${C_YELLOW}اختر رقم الهوية [1-8]: ${C_RESET}"
    read -r choice

    case "$choice" in
        1)
            CHOSEN_NAME="iPhone-16-Pro"
            CHOSEN_MAC=$(generate_mac "bc:d0:74")
            CHOSEN_DESC="Apple iPhone"
            ;;
        2)
            CHOSEN_NAME="iPad-Air"
            CHOSEN_MAC=$(generate_mac "f0:18:98")
            CHOSEN_DESC="Apple iPad"
            ;;
        3)
            CHOSEN_NAME="Galaxy-S24-Ultra"
            CHOSEN_MAC=$(generate_mac "5c:e8:eb")
            CHOSEN_DESC="Samsung Galaxy"
            ;;
        4)
            CHOSEN_NAME=$(random_win_hostname)
            CHOSEN_MAC=$(generate_mac "00:1b:77")
            CHOSEN_DESC="Windows 11 PC"
            ;;
        5)
            CHOSEN_NAME="HP-LaserJet-Pro"
            CHOSEN_MAC=$(generate_mac "00:0e:7f")
            CHOSEN_DESC="HP Printer"
            ;;
        6)
            CHOSEN_NAME="LG-webOSTV"
            CHOSEN_MAC=$(generate_mac "00:05:cd")
            CHOSEN_DESC="LG Smart TV"
            ;;
        7)
            CHOSEN_NAME=$(random_android_hostname)
            CHOSEN_MAC=$(generate_mac "")
            CHOSEN_DESC="Pure Stealth Random"
            ;;
        8)
            echo -ne "\n${C_YELLOW}اكتب الاسم الذي تريده أن يظهر عند صاحب الشبكة: ${C_RESET}"
            read -r custom_input
            if [[ -z "$custom_input" ]]; then
                custom_input="Device-$(openssl rand -hex 3)"
            fi
            CHOSEN_NAME="$custom_input"
            CHOSEN_MAC=$(generate_mac "")
            CHOSEN_DESC="Custom Identity"
            ;;
        *)
            echo -e "${C_RED}اختيار غير صالح، سيتم اختيار هوية عشوائية.${C_RESET}"
            CHOSEN_NAME=$(random_android_hostname)
            CHOSEN_MAC=$(generate_mac "")
            CHOSEN_DESC="Default Random"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Full Reborn (God Mode)
# ------------------------------------------------------------------------------
full_reborn() {
    select_persona
    apply_network_identity "$CHOSEN_NAME" "$CHOSEN_MAC" "$CHOSEN_DESC"
    reset_machine_id
    clean_browser_footprints
    show_status_dashboard
    echo -e "\n${C_GREEN}${C_BOLD}✨ تم اكتمال عملية الولادة الجديدة الشاملة (Full Reborn)!${C_RESET}"
    echo -e "${C_CYAN}جهازك الآن يظهر للراوتر ولكل من في الشبكة كجهاز جديد تماماً لم يدخل الشبكة من قبل.${C_RESET}\n"

    echo -ne "${C_YELLOW}هل تريد فتح المتصفح الآن بهويتك الجديدة؟ [Y/n]: ${C_RESET}"
    read -r launch_ans
    if [[ -z "$launch_ans" || "$launch_ans" =~ ^[Yy]$ ]]; then
        echo -e "${C_GREEN}🚀 جارٍ تشغيل المتصفح...${C_RESET}"
        launch_default_browser
        sleep 1
    fi
}

# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Static IP Stealth Mode (Bypass DHCP Lease Table Entirely)
# ------------------------------------------------------------------------------
toggle_static_stealth() {
    detect_network
    if [[ -z "$ACTIVE_CON" ]]; then
        echo -e "${C_RED}❌ لا يوجد اتصال شبكة نشط حالياً.${C_RESET}"
        return 1
    fi

    local current_method
    current_method=$(nmcli -g ipv4.method con show "$ACTIVE_CON" 2>/dev/null || echo "auto")

    if [[ "$current_method" == "manual" ]]; then
        echo -e "\n${C_YELLOW}⚠ أنت حالياً في وضع الـ IP الثابت (Static Stealth). هل تريد الرجوع لوضع الـ DHCP التلقائي؟ [y/N]: ${C_RESET}"
        read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            nmcli con mod "$ACTIVE_CON" ipv4.method auto ipv4.addresses "" ipv4.gateway "" ipv4.dns ""
            nmcli con up "$ACTIVE_CON" >/dev/null 2>&1 || true
            echo -e "${C_GREEN}✔ تم الرجوع لوضع الـ DHCP التلقائي بنجاح.${C_RESET}"
        fi
        return 0
    fi

    local gateway
    gateway=$(ip route | grep default | grep "$ACTIVE_DEV" | awk "{print \$3}" | head -n 1 || true)
    local subnet_base
    subnet_base=$(echo "$CURRENT_IP" | cut -d. -f1-3)

    if [[ -z "$gateway" || -z "$subnet_base" ]]; then
        echo -e "${C_RED}❌ تعذر استنتاج البوابة الافتراضية للشبكة.${C_RESET}"
        return 1
    fi

    local suggested_ip="${subnet_base}.224"
    echo -e "\n${C_CYAN}═════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_MAGENTA}👻 تفعيل وضع الشبح الثابت (Static IP Stealth - تجاوز الـ DHCP)${C_RESET}"
    echo -e "${C_CYAN}═════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "هذا الوضع يقوم بـ:"
    echo -e "  1. إيقاف إرسال أي طلبات DHCP نهائياً إلى الراوتر."
    echo -e "  2. حجب إرسال اسم الجهاز (Option 12) لعدم تسجيلك في جدول الـ Leases."
    echo -e "  3. تثبيت عنوان IP مباشر ليمر الترافيك عبر الـ Routing بصمت."
    echo -e "\nالبوابة الحالية (الراوتر): ${C_YELLOW}${gateway}${C_RESET}"
    echo -e "الآي بي المقترح للتخفي:     ${C_GREEN}${suggested_ip}${C_RESET}"
    echo -ne "اضغط Enter للموافقة على (${suggested_ip}) أو اكتب IP آخر: "
    read -r user_ip
    local final_ip="${user_ip:-$suggested_ip}"

    echo -e "\n${C_BLUE}▸ تطبيق الإعدادات وتجاوز خادم الـ DHCP...${C_RESET}"
    nmcli con mod "$ACTIVE_CON" ipv4.method manual ipv4.addresses "${final_ip}/24" ipv4.gateway "$gateway" ipv4.dns "1.1.1.1,8.8.8.8"
    nmcli con mod "$ACTIVE_CON" ipv4.dhcp-send-hostname no 2>/dev/null || true
    nmcli con mod "$ACTIVE_CON" ipv4.dhcp-hostname "" 2>/dev/null || true
    nmcli con up "$ACTIVE_CON" >/dev/null 2>&1 || true
    sleep 2

    detect_network
    echo -e "${C_GREEN}${C_BOLD}✔ تم تفعيل وضع الشبح الثابت بنجاح!${C_RESET}"
    echo -e "  • عنوانك الجديد: ${C_GREEN}${CURRENT_IP}${C_RESET} (بدون أي عقد DHCP)"
}
# Main Interactive Menu
# ------------------------------------------------------------------------------
interactive_menu() {
    save_baseline

    while true; do
        clear 2>/dev/null || true
        echo -e "${C_MAGENTA}"
        cat << "EOF"
  ██████╗ ███████╗██████╗  ██████╗ ██████╗ ███╗   ██╗
  ██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗████╗  ██║
  ██████╔╝█████╗  ██████╔╝██║   ██║██████╔╝██╔██╗ ██║
  ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║
  ██║  ██║███████╗██████╔╝╚██████╔╝██║  ██║██║ ╚████║
  ╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
EOF
        echo -e "${C_RESET}${C_DIM}   — HackerAI Anti-Fingerprint & Ghost Engine for Arch/CachyOS —${C_RESET}"

        show_status_dashboard

        echo -e "${C_BOLD}${C_WHITE}الخيارات والعمليات المتاحة:${C_RESET}"
        echo -e "  ${C_CYAN}[1]${C_RESET} ${C_BOLD}⚡ ولادة جديدة شاملة (Full Reborn - محو كل البصمات بضغطة زر)${C_RESET}"
        echo -e "  ${C_CYAN}[2]${C_RESET} 🎭 ${C_BOLD}تغيير هوية الشبكة فقط (الاسم + الماك + تجديد الـ IP في الراوتر)${C_RESET}"
        echo -e "  ${C_CYAN}[3]${C_RESET} 🔑 ${C_BOLD}تصفير وتوليد Machine-ID جديد للنظام (محو بصمة لينكس العميقة)${C_RESET}"
        echo -e "  ${C_CYAN}[4]${C_RESET} 🧹 ${C_BOLD}تطهير بصمات المتصفح وفك الأقفال (Crashpad / UUIDs / Locks)${C_RESET}"
        echo -e "  ${C_CYAN}[5]${C_RESET} 👻 ${C_BOLD}فتح متصفح شبحي فوري (Ephemeral Chrome - معزول 100% في الرام)${C_RESET}"
        echo -e "  ${C_CYAN}[6]${C_RESET} 🛡️ ${C_BOLD}تبديل وضع التمويه الدائم التلقائي في الشبكات (Auto Random MAC)${C_RESET}"
        echo -e "  ${C_CYAN}[7]${C_RESET} 🔄 ${C_BOLD}استعادة الهوية الأصلية للجهاز (Restore Baseline)${C_RESET}"
        echo -e "  ${C_CYAN}[8]${C_RESET} 🔓 ${C_BOLD}إصلاح وفك أقفال متصفح كروم فورياً (Fix Chrome Locks)${C_RESET}"
        echo -e "  ${C_CYAN}[9]${C_RESET} 👻 ${C_BOLD}وضع الشبح الثابت (Static IP - إيقاف الـ DHCP كلياً للتخفي من الراوتر)${C_RESET}"
        echo -e "  ${C_RED}[0]${C_RESET} خروج (Exit)"
        echo -ne "\n${C_YELLOW}اختر العملية [0-8]: ${C_RESET}"
        read -r opt

        case "$opt" in
            1) full_reborn ;;
            2)
                select_persona
                apply_network_identity "$CHOSEN_NAME" "$CHOSEN_MAC" "$CHOSEN_DESC"
                ;;
            3) reset_machine_id ;;
            4) clean_browser_footprints ;;
            5) launch_ghost_chrome ;;
            6) toggle_permanent_rand ;;
            7) restore_baseline ;;
            8)
                fix_browser_locks
                echo -e "${C_GREEN}✔ Browser locks removed! Ready to launch / تم فك أقفال المتصفح بنجاح، جاهز للفتح الآن.${C_RESET}"
                launch_default_browser
                ;;
            9) toggle_static_stealth ;;
            0) echo -e "\n${C_GREEN}في أمان الله!${C_RESET}\n"; exit 0 ;;
            *) echo -e "${C_RED}خيار غير صالح!${C_RESET}" ;;
        esac

        echo -ne "\n${C_DIM}اضغط Enter للعودة إلى القائمة...${C_RESET}"
        read -r
    done
}

# ------------------------------------------------------------------------------
# CLI Flag Processing
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
save_baseline

case "${1:-}" in
    --quick|-q)
        CHOSEN_NAME=$(random_android_hostname)
        CHOSEN_MAC=$(generate_mac "")
        CHOSEN_DESC="Quick Random Stealth"
        apply_network_identity "$CHOSEN_NAME" "$CHOSEN_MAC" "$CHOSEN_DESC"
        reset_machine_id
        clean_browser_footprints
        ;;
    --name|-n)
        if [[ -z "${2:-}" ]]; then
            echo -e "${C_RED}خطأ: يرجى تحديد الاسم بعد الفلاج، مثال: reborn --name iPhone-16-Pro${C_RESET}"
            exit 1
        fi
        CHOSEN_NAME="$2"
        case "$CHOSEN_NAME" in
            *iPhone*|*iPad*|*Apple*|*Mac*) CHOSEN_MAC=$(generate_mac "bc:d0:74") ;;
            *Galaxy*|*Samsung*) CHOSEN_MAC=$(generate_mac "5c:e8:eb") ;;
            *DESKTOP*|*Windows*) CHOSEN_MAC=$(generate_mac "00:1b:77") ;;
            *) CHOSEN_MAC=$(generate_mac "") ;;
        esac
        apply_network_identity "$CHOSEN_NAME" "$CHOSEN_MAC" "Custom CLI"
        ;;
    --status|-s)
        show_status_dashboard
        ;;
    --restore|-r)
        restore_baseline
        ;;
    --ghost-chrome|-g)
        launch_ghost_chrome
        ;;
    --browser-clean|-b)
        clean_browser_footprints
        ;;
    --fix-chrome)
        fix_browser_locks
        echo -e "${C_GREEN}✔ تم فك أقفال كروم بنجاح!${C_RESET}"
        ;;
    --static-stealth)
        toggle_static_stealth
        ;;
    --help|-h)
        echo "الاستخدام: reborn [خيارات]"
        echo "  بدون خيارات        تشغيل الواجهة التفاعلية الكاملة للقائمة"
        echo "  --quick, -q        ولادة جديدة فورية بهوية شبحية عشوائية"
        echo "  --name, -n <NAME>  تحديد اسم التمويه مباشرة مع ماك مناسب"
        echo "  --status, -s       عرض كشف البصمات الحالية"
        echo "  --restore, -r      استعادة الهوية الأصلية للجهاز"
        echo "  --ghost-chrome, -g  إطلاق متصفح شبحي معزول في الرام"
        echo "  --browser-clean    تطهير كاشات وبصمات المتصفح"
        echo "  --fix-chrome       فك أقفال متصفح كروم فورياً"
        echo "  --static-stealth   تفعيل/تعطيل وضع الشبح الثابت (بدون DHCP)"
        ;;
    "")
        interactive_menu
        ;;
    *)
        echo -e "${C_RED}خيار غير معروف: $1 (استخدم --help للمساعدة)${C_RESET}"
        exit 1
        ;;
esac
fi
