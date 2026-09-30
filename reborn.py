#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Reborn ⚡ Ghost Identity & Fingerprint Eraser
Universal Cross-Platform Edition (Linux, Windows, Termux)
Developed by: Mohammed Yaqeen (Yemen - Sana'a) | محمد يقين مجمل الفايق
"""

import os
import sys
import platform
import subprocess
import shutil
import random
import uuid
import time
import argparse

# Terminal Colors
C_RESET   = "\033[0m"
C_BOLD    = "\033[1m"
C_DIM     = "\033[2m"
C_RED     = "\033[31m"
C_GREEN   = "\033[32m"
C_YELLOW  = "\033[33m"
C_BLUE    = "\033[34m"
C_MAGENTA = "\033[35m"
C_CYAN    = "\033[36m"
C_WHITE   = "\033[37m"

BANNER = f"""{C_MAGENTA}
  ██████╗ ███████╗██████╗  ██████╗ ██████╗ ███╗   ██╗
  ██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗████╗  ██║
  ██████╔╝█████╗  ██████╔╝██║   ██║██████╔╝██╔██╗ ██║
  ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║
  ██║  ██║███████╗██████╔╝╚██████╔╝██║  ██║██║ ╚████║
  ╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
{C_RESET}{C_DIM}  — HackerAI Anti-Fingerprint & Ghost Engine (Cross-Platform) —{C_RESET}
"""

class RebornEngine:
    def __init__(self):
        self.os_type = platform.system()
        self.is_termux = "com.termux" in os.environ.get("PREFIX", "") or os.path.exists("/data/data/com.termux")
        if self.is_termux:
            self.os_type = "Termux"
        
        self.active_dev = "Unknown"
        self.active_con = "Unknown"
        self.current_mac = "Unknown"
        self.current_ip = "Unknown"
        self.current_hostname = "Unknown"
        self.current_machine_id = "Unknown"

    def check_privileges(self):
        if self.os_type == "Linux":
            if os.geteuid() != 0:
                print(f"{C_RED}[!] تنبيه: يلزم صلاحيات الروت. شغل الأداة بأمر sudo{C_RESET}")
                sys.exit(1)
        elif self.os_type == "Termux":
            if subprocess.run(["su", "-c", "id"], capture_output=True).returncode != 0:
                print(f"{C_RED}[!] تنبيه: يلزم صلاحيات الروت في تيرمكس (tsu / su){C_RESET}")
                sys.exit(1)
        elif self.os_type == "Windows":
            try:
                import ctypes
                if not ctypes.windll.shell32.IsUserAnAdmin():
                    print(f"{C_RED}[!] تنبيه: يلزم تشغيل كمسؤول (Run as Administrator) في الويندوز{C_RESET}")
                    sys.exit(1)
            except:
                pass

    def detect_network(self):
        if self.os_type == "Linux":
            try:
                with open("/etc/hostname", "r") as f:
                    self.current_hostname = f.read().strip()
            except:
                self.current_hostname = subprocess.getoutput("hostname")
            
            try:
                with open("/etc/machine-id", "r") as f:
                    self.current_machine_id = f.read().strip()
            except:
                self.current_machine_id = "None"
                
            out = subprocess.getoutput("ip route show default")
            if "dev " in out:
                self.active_dev = out.split("dev ")[1].split()[0]
                try:
                    ip_out = subprocess.getoutput(f"ip -4 addr show {self.active_dev}")
                    if "inet " in ip_out:
                        self.current_ip = ip_out.split("inet ")[1].split("/")[0]
                except:
                    pass
                try:
                    mac_out = subprocess.getoutput(f"cat /sys/class/net/{self.active_dev}/address")
                    self.current_mac = mac_out.strip()
                except:
                    pass
                try:
                    con_out = subprocess.getoutput(f"nmcli -t -f NAME,DEVICE con show --active | grep ':{self.active_dev}$'")
                    if con_out:
                        self.active_con = con_out.split(":")[0]
                except:
                    pass

        elif self.os_type == "Windows":
            self.current_hostname = subprocess.getoutput("hostname").strip()
            self.current_machine_id = "Windows-Registry-Guid"
            self.active_dev = "Wi-Fi / Ethernet"
            self.current_ip = "DHCP-Assigned"
            self.current_mac = "Hardware-MAC"

        elif self.os_type == "Termux":
            self.current_hostname = subprocess.getoutput("su -c getprop net.hostname").strip()
            self.current_machine_id = subprocess.getoutput("su -c settings get secure android_id").strip()
            self.active_dev = "wlan0"
            self.current_ip = "Android-IP"
            self.current_mac = "Android-MAC"

    def show_dashboard(self):
        self.detect_network()
        vendor = "Locally Administered (Random Stealth)" if self.current_mac.startswith(("02", "06", "0a", "0e", "12", "16", "1a", "1e", "3a", "3A")) else "Hardware Default"
        
        print(f"\n{C_CYAN}  ⚡ كشف البصمات الحالية (كما يراها الراوتر والشبكة) ⚡{C_RESET}")
        print(f"{C_CYAN} -------------------------------------------------------- {C_RESET}")
        print(f"  🖥️  اسم الجهاز في الراوتر     : {C_BOLD}{self.current_hostname}{C_RESET}")
        print(f"  🏷️  عنوان الماك (MAC)         : {C_YELLOW}{self.current_mac}{C_RESET}")
        print(f"  🏢 مصنع كرت الشبكة (Vendor) : {vendor}")
        print(f"  🌐 عنوان الآي بي (IPv4)       : {C_GREEN}{self.current_ip}{C_RESET}")
        print(f"  📡 شبكة الواي فاي الحالية     : {self.active_con} ({self.active_dev})")
        print(f"  🔑 معرف النظام (Machine ID)  : {self.current_machine_id[:20]}...")
        print(f"{C_CYAN} -------------------------------------------------------- {C_RESET}\n")

    def print_menu(self):
        print(f"{C_BOLD}الخيارات والعمليات المتاحة:{C_RESET}")
        print("  1 - ولادة جديدة شاملة (محو كل البصمات بضغطة زر واحدة ⚡)")
        print("  2 - تغيير هوية الشبكة فقط (الاسم + الماك + تجديد الـ IP)")
        print("  3 - تصفير وتوليد Machine-ID جديد للنظام (محو البصمة العميقة)")
        print("  4 - تطهير بصمات المتصفح وفك الأقفال (Crashpad / UUIDs / Locks)")
        print("  5 - فتح متصفح شبحي فوري (معزول 100% في الرام - Linux)")
        print("  6 - تفعيل وضع التمويه الدائم التلقائي في الشبكات (Auto MAC)")
        print("  7 - استعادة الهوية الأصلية للجهاز (Restore Baseline)")
        print("  8 - إصلاح وفك أقفال متصفح كروم فورياً (Fix Chrome Locks)")
        print("  9 - وضع الشبح الثابت (Static IP - إيقاف الـ DHCP كلياً للتخفي)")
        print(f"  {C_MAGENTA}10 - نقطة البث المخفية (Stealth Hotspot - تجاوز الحظر وتغيير الباسورد){C_RESET}")
        print(f"  {C_RED}0 - خروج (Exit){C_RESET}")

    def get_random_mac(self, prefix=""):
        if prefix:
            rem = ":".join([f"{random.randint(0, 255):02x}" for _ in range(3)])
            return f"{prefix}:{rem}"
        return ":".join([f"{random.randint(0, 255):02x}" for _ in range(6)])

    def get_random_hostname(self, os_target="android"):
        chars = "0123456789abcdef"
        if os_target == "android":
            return "android-" + "".join(random.choice(chars) for _ in range(12))
        elif os_target == "windows":
            return "DESKTOP-" + "".join(random.choice("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ") for _ in range(7))
        else:
            return "PC-" + "".join(random.choice(chars) for _ in range(6))

    def reset_machine_id(self):
        print(f"\n{C_CYAN}▸ تصفير وتوليد Machine-ID جديد...{C_RESET}")
        if self.os_type == "Linux":
            if os.path.exists("/etc/machine-id"):
                os.remove("/etc/machine-id")
                subprocess.run(["systemd-machine-id-setup"], capture_output=True)
            if os.path.exists("/var/lib/dbus/machine-id"):
                os.remove("/var/lib/dbus/machine-id")
                subprocess.run(["dbus-uuidgen", "--ensure"], capture_output=True)
            print(f"{C_GREEN}✔ تم محو البصمة العميقة للينكس بنجاح!{C_RESET}")
        elif self.os_type == "Windows":
            new_guid = str(uuid.uuid4())
            cmd = f'reg add HKLM\\SOFTWARE\\Microsoft\\Cryptography /v MachineGuid /t REG_SZ /d {new_guid} /f'
            subprocess.run(cmd, shell=True, capture_output=True)
            print(f"{C_GREEN}✔ تم محو MachineGuid للويندوز بنجاح!{C_RESET}")
        elif self.os_type == "Termux":
            new_id = "".join(random.choice("0123456789abcdef") for _ in range(16))
            subprocess.run(["su", "-c", f"settings put secure android_id {new_id}"], capture_output=True)
            print(f"{C_GREEN}✔ تم محو Android ID بنجاح!{C_RESET}")

    def clean_browser_footprints(self):
        print(f"\n{C_CYAN}▸ تطهير بصمات وأقفال المتصفحات (Crashpad/Cookies)...{C_RESET}")
        if self.os_type == "Linux":
            home = os.path.expanduser("~")
            paths = [
                f"{home}/.config/google-chrome/Singleton*",
                f"{home}/.config/chromium/Singleton*",
                f"/tmp/com.google.Chrome.*"
            ]
            for p in paths:
                os.system(f"rm -rf {p} >/dev/null 2>&1")
        elif self.os_type == "Windows":
            local_app_data = os.environ.get("LOCALAPPDATA", "")
            if local_app_data:
                paths = [
                    f"{local_app_data}\\Google\\Chrome\\User Data\\Crashpad",
                    f"{local_app_data}\\Microsoft\\Edge\\User Data\\Crashpad"
                ]
                for p in paths:
                    shutil.rmtree(p, ignore_errors=True)
        print(f"{C_GREEN}✔ تم فك الأقفال وتنظيف كاش المتصفح!{C_RESET}")

    def apply_network_identity(self, name, mac_prefix=""):
        mac = self.get_random_mac(mac_prefix)
        print(f"\n{C_MAGENTA}⚡ جارٍ تطبيق الهوية الشبحية الجديدة...{C_RESET}")
        print(f"  • الاسم الجديد: {C_YELLOW}{name}{C_RESET}")
        print(f"  • الماك الجديد: {C_YELLOW}{mac}{C_RESET}")

        if self.os_type == "Linux":
            subprocess.run(["hostnamectl", "set-hostname", name], capture_output=True)
            res = subprocess.run(["ip", "route", "show", "default"], capture_output=True, text=True)
            iface = "wlan0"
            for line in res.stdout.split('\n'):
                if 'dev' in line:
                    iface = line.split('dev')[1].split()[0]
                    break
            print(f"{C_CYAN}▸ تدوير ماك الشبكة ({iface})...{C_RESET}")
            subprocess.run(["ip", "link", "set", iface, "down"], capture_output=True)
            subprocess.run(["macchanger", "-m", mac, iface], capture_output=True)
            subprocess.run(["ip", "link", "set", iface, "up"], capture_output=True)
            
            if self.active_con != "Unknown":
                subprocess.run(["nmcli", "con", "up", self.active_con], capture_output=True)
            else:
                subprocess.run(["systemctl", "restart", "NetworkManager"], capture_output=True)

        elif self.os_type == "Windows":
            subprocess.run(["powershell", "-Command", f"Rename-Computer -NewName {name}"], capture_output=True)
            print(f"{C_YELLOW}[!] تم تغيير الاسم في الويندوز (يحتاج إعادة تشغيل لاحقاً).{C_RESET}")

        elif self.os_type == "Termux":
            subprocess.run(["su", "-c", f"setprop net.hostname {name}"], capture_output=True)
            subprocess.run(["su", "-c", "ip link set wlan0 down"], capture_output=True)
            subprocess.run(["su", "-c", f"macchanger -m {mac} wlan0"], capture_output=True)
            subprocess.run(["su", "-c", "ip link set wlan0 up"], capture_output=True)

        print(f"{C_GREEN}✔ اكتمل التمويه وتحديث الهوية!{C_RESET}")

    def launch_ghost_browser(self):
        print(f"\n{C_CYAN}▸ إطلاق متصفح شبحي معزول بالكامل في الذاكرة الحية (RAM)...{C_RESET}")
        if self.os_type == "Linux":
            profile_dir = f"/tmp/ghost_chrome_{random.randint(1000,9999)}"
            cmd = f"nohup google-chrome --user-data-dir={profile_dir} --no-first-run --incognito >/dev/null 2>&1 &"
            os.system(cmd)
            print(f"{C_GREEN}✔ تم إطلاق المتصفح الشبحي بنجاح!{C_RESET}")

    def toggle_auto_mac(self):
        print(f"\n{C_CYAN}▸ تفعيل/إلغاء التمويه التلقائي الدائم...{C_RESET}")
        if self.os_type == "Linux":
            nm_conf = "/etc/NetworkManager/conf.d/90-mac-randomization.conf"
            if os.path.exists(nm_conf):
                os.remove(nm_conf)
                print(f"{C_GREEN}✔ تم إيقاف التمويه التلقائي (الوضع العادي).{C_RESET}")
            else:
                with open(nm_conf, "w") as f:
                    f.write("[device]\nwifi.scan-rand-mac-address=yes\n\n[connection]\nwifi.cloned-mac-address=random\nethernet.cloned-mac-address=random\n")
                print(f"{C_GREEN}✔ تم تفعيل التمويه الدائم في NetworkManager!{C_RESET}")
            subprocess.run(["systemctl", "restart", "NetworkManager"])

    def prevent_lid_sleep(self, enable=True):
        # يمنع اللابتوب من النوم عند إغلاق الشاشة
        conf_file = "/etc/systemd/logind.conf"
        if enable:
            os.system(f"sed -i 's/.*HandleLidSwitch=.*/HandleLidSwitch=ignore/' {conf_file}")
            print(f"{C_GREEN}[✓] تم تعطيل النوم عند إغلاق الشاشة (ستستمر الشبكة بالعمل).{C_RESET}")
        else:
            os.system(f"sed -i 's/.*HandleLidSwitch=.*/HandleLidSwitch=suspend/' {conf_file}")
            print(f"{C_YELLOW}[-] تم إعادة تفعيل النوم عند إغلاق الشاشة.{C_RESET}")
        os.system("systemctl restart systemd-logind")

    def stealth_hotspot_menu(self):
        if self.os_type != "Linux":
            print(f"{C_YELLOW}[!] هذه الميزة مخصصة لنظام لينكس حالياً.{C_RESET}")
            return
            
        con_name = "Hotspot-Private"
        iface_in = "ap0"
        
        while True:
            self.detect_network()
            iface_out = self.active_dev if self.active_dev != "Unknown" else "wlp4s0"
            
            # Fetch current SSID and Password from NM if it exists
            ssid_out = subprocess.getoutput(f"nmcli -g 802-11-wireless.ssid con show '{con_name}' 2>/dev/null")
            pass_out = subprocess.getoutput(f"nmcli -g 802-11-wireless-security.psk con show '{con_name}' 2>/dev/null")
            current_ssid = ssid_out if ssid_out else "NET"
            current_pass = pass_out if pass_out else "123456788"

            print(f"\n{C_CYAN}════════ إدارة نقطة البث المخفية (Stealth Hotspot) ════════{C_RESET}")
            print(f"  {C_DIM}• كرت الإنترنت: {iface_out} | كرت البث: {iface_in}{C_RESET}")
            print(f"  {C_DIM}• الشبكة الحالية: {current_ssid} | الرمز: {current_pass}{C_RESET}")
            print(f"{C_CYAN}───────────────────────────────────────────────────────────{C_RESET}")
            print(f"  1 - تشغيل البث (تجاوز حظر + حماية أجهزة الميكروتك + منع النوم)")
            print(f"  2 - إيقاف البث")
            print(f"  3 - تغيير اسم الشبكة (SSID) وكلمة المرور")
            print(f"  4 - منع/تفعيل النوم عند إغلاق الشاشة (Lid Switch)")
            print(f"  5 - عرض الأجهزة المتصلة وحالة البث")
            print(f"  0 - رجوع للقائمة الرئيسية")
            
            opt = input(f"\n{C_YELLOW}  اختر العملية [0-5]: {C_RESET}")
            
            if opt == "1":
                print(f"\n{C_MAGENTA}[+] جاري تجهيز الشبكة لمنع الانقطاع وحجب الأجهزة...{C_RESET}")
                
                # منع اللابتوب من النوم
                self.prevent_lid_sleep(enable=True)
                
                # Check if profile exists, if not create it properly
                if subprocess.run(["nmcli", "con", "show", con_name], capture_output=True).returncode != 0:
                    print(f"{C_YELLOW}[!] جاري بناء ملف الاتصال ({con_name}) لأول مرة...{C_RESET}")
                    os.system(f'nmcli con add type wifi ifname {iface_in} con-name "{con_name}" autoconnect no ssid "{current_ssid}" 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared >/dev/null 2>&1')
                    os.system(f'nmcli con modify "{con_name}" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "{current_pass}" >/dev/null 2>&1')

                # Create virtual interface properly
                os.system(f"iw dev {iface_in} del >/dev/null 2>&1")
                time.sleep(0.5)
                os.system(f"iw dev {iface_out} interface add {iface_in} type __ap >/dev/null 2>&1")
                
                # Ensure the virtual interface has a randomized MAC to avoid NM confusion
                os.system(f"ip link set dev {iface_in} address {self.get_random_mac('02:11:22')} >/dev/null 2>&1")
                
                print(f"{C_MAGENTA}[+] جاري تشغيل البث عبر NetworkManager...{C_RESET}")
                if os.system(f"nmcli connection up '{con_name}' >/dev/null 2>&1") != 0:
                    print(f"{C_RED}[!] فشل التشغيل. تأكد أن كرت الواي فاي يدعم البث المتزامن وأنك غير متصل بشبكة 5GHz لا تدعم البث.{C_RESET}")
                else:
                    # تفعيل حجب الأجهزة عن الميكروتك (Evasion Rules)
                    os.system("sysctl -w net.ipv4.ip_forward=1 >/dev/null")
                    
                    # 1. إخفاء الأجهزة خلف IP اللابتوب
                    os.system(f"iptables -t nat -C POSTROUTING -o {iface_out} -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o {iface_out} -j MASQUERADE")
                    
                    # 2. تطبيع TTL لجميع الحزم بحيث تبدو قادمة من اللابتوب فقط
                    os.system(f"iptables -t mangle -C PREROUTING -i {iface_out} -j TTL --ttl-set 64 2>/dev/null || iptables -t mangle -A PREROUTING -i {iface_out} -j TTL --ttl-set 64")
                    os.system(f"iptables -t mangle -C POSTROUTING -o {iface_out} -j TTL --ttl-set 64 2>/dev/null || iptables -t mangle -A POSTROUTING -o {iface_out} -j TTL --ttl-set 64")
                    os.system(f"iptables -t mangle -C FORWARD -j TTL --ttl-set 64 2>/dev/null || iptables -t mangle -I FORWARD -j TTL --ttl-set 64")
                    
                    # 3. تعديل حجم حزم TCP لمنع كشف الـ MTU
                    os.system(f"iptables -t mangle -C FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || iptables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu")
                    
                    print(f"{C_GREEN}[✓] تم تشغيل الشبكة بنجاح! الأجهزة المتصلة الآن مخفية تماماً عن الميكروتك.{C_RESET}")
            
            elif opt == "2":
                print(f"\n{C_YELLOW}[-] جاري إيقاف نقطة البث وتفريغ قواعد التخفي...{C_RESET}")
                os.system(f"nmcli connection down '{con_name}' >/dev/null 2>&1")
                
                # مسح القواعد
                os.system(f"iptables -t nat -D POSTROUTING -o {iface_out} -j MASQUERADE 2>/dev/null")
                os.system(f"iptables -t mangle -D PREROUTING -i {iface_out} -j TTL --ttl-set 64 2>/dev/null")
                os.system(f"iptables -t mangle -D POSTROUTING -o {iface_out} -j TTL --ttl-set 64 2>/dev/null")
                os.system(f"iptables -t mangle -D FORWARD -j TTL --ttl-set 64 2>/dev/null")
                os.system(f"iptables -t mangle -D FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null")
                
                os.system(f"iw dev {iface_in} del >/dev/null 2>&1")
                self.prevent_lid_sleep(enable=False)
                print(f"{C_GREEN}[✓] تم الإيقاف بنجاح.{C_RESET}")
                
            elif opt == "3":
                new_ssid = input(f"{C_CYAN}أدخل اسم الشبكة الجديد (SSID): {C_RESET}")
                new_pass = input(f"{C_CYAN}أدخل كلمة المرور الجديدة (8 أحرف كحد أدنى): {C_RESET}")
                
                if len(new_pass) < 8:
                    print(f"{C_RED}[!] كلمة المرور يجب أن تكون 8 أحرف على الأقل!{C_RESET}")
                else:
                    if subprocess.run(["nmcli", "con", "show", con_name], capture_output=True).returncode == 0:
                        os.system(f'nmcli con modify "{con_name}" ssid "{new_ssid}" wifi-sec.psk "{new_pass}"')
                        print(f"{C_GREEN}[✓] تم تحديث الاسم وكلمة المرور بنجاح! يرجى إيقاف وتشغيل البث لتطبيقها.{C_RESET}")
                    else:
                        os.system(f'nmcli con add type wifi ifname {iface_in} con-name "{con_name}" autoconnect no ssid "{new_ssid}" 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared >/dev/null 2>&1')
                        os.system(f'nmcli con modify "{con_name}" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "{new_pass}" >/dev/null 2>&1')
                        print(f"{C_GREEN}[✓] تم إنشاء ملف البث بالإعدادات الجديدة بنجاح.{C_RESET}")

            elif opt == "4":
                conf_check = subprocess.getoutput("grep '^HandleLidSwitch=ignore' /etc/systemd/logind.conf")
                if conf_check:
                    self.prevent_lid_sleep(enable=False)
                else:
                    self.prevent_lid_sleep(enable=True)

            elif opt == "5":
                print(f"\n{C_CYAN}=== حالة نقطة البث ==={C_RESET}")
                if os.system(f"iw dev | grep -q 'Interface {iface_in}'") == 0:
                    print(f"[*] الحالة: {C_GREEN}تعمل الآن (ON){C_RESET}")
                    print(f"[*] الأجهزة المتصلة:")
                    os.system(f"iw dev {iface_in} station dump | grep Station || echo '  (لا توجد أجهزة متصلة)'")
                else:
                    print(f"[*] الحالة: {C_RED}متوقفة (OFF){C_RESET}")
                    
            elif opt == "0":
                break
            else:
                print(f"{C_RED}خيار غير صالح!{C_RESET}")

    def interactive_menu(self):
        while True:
            os.system("clear" if self.os_type != "Windows" else "cls")
            print(BANNER)
            print(f"{C_BOLD}  المطور : محمد يقين مجمل الفايق - اليمن (صنعاء){C_RESET}")
            
            self.show_dashboard()
            self.print_menu()
            
            try:
                opt = input(f"\n{C_YELLOW}  اختر العملية [0-10]: {C_RESET}")
            except KeyboardInterrupt:
                break
                
            if opt == "1":
                target_os = "android" if self.os_type == "Termux" else ("windows" if self.os_type == "Windows" else "linux")
                name = self.get_random_hostname(target_os)
                self.apply_network_identity(name)
                self.reset_machine_id()
                self.clean_browser_footprints()
            elif opt == "2":
                name = input(f"{C_CYAN}أدخل اسم الجهاز الجديد (اضغط Enter للاسم العشوائي): {C_RESET}")
                if not name:
                    target_os = "android" if self.os_type == "Termux" else ("windows" if self.os_type == "Windows" else "linux")
                    name = self.get_random_hostname(target_os)
                self.apply_network_identity(name)
            elif opt == "3":
                self.reset_machine_id()
            elif opt == "4" or opt == "8":
                self.clean_browser_footprints()
            elif opt == "5":
                self.launch_ghost_browser()
            elif opt == "6":
                self.toggle_auto_mac()
            elif opt == "7":
                print(f"\n{C_YELLOW}[!] سيتم إضافة ميزة الاستعادة من ملف النسخة الاحتياطية في الإصدار القادم.{C_RESET}")
            elif opt == "10":
                self.stealth_hotspot_menu()
            elif opt == "9":
                print(f"\n{C_CYAN}▸ وضع التخفي من DHCP (Static IP Stealth)...{C_RESET}")
                if self.os_type == "Linux" and self.active_con != "Unknown":
                    print(f"جارٍ تطبيق إعدادات Static IP على اتصال {self.active_con}")
                    subprocess.run(["nmcli", "con", "mod", self.active_con, "ipv4.method", "manual"])
                    print(f"{C_GREEN}✔ تم إيقاف سحب الـ DHCP للتخفي من الراوتر!{C_RESET}")
                else:
                    print(f"{C_YELLOW}[!] غير مدعوم على منصتك الحالية أو لا يوجد اتصال نشط.{C_RESET}")
            elif opt == "0":
                print(f"\n{C_GREEN}في أمان الله!{C_RESET}\n")
                break
            else:
                print(f"{C_RED}خيار غير صالح!{C_RESET}")
            
            input(f"\n{C_DIM}اضغط Enter للعودة إلى القائمة...{C_RESET}")

def main():
    engine = RebornEngine()
    engine.check_privileges()
    
    parser = argparse.ArgumentParser(description="Reborn ⚡ Universal Ghost Identity & Fingerprint Eraser")
    parser.add_argument("--quick", "-q", action="store_true", help="Quick random identity spoofing and footprint purge")
    parser.add_argument("--ghost-browser", "-g", action="store_true", help="Launch isolated ghost browser in RAM")
    parser.add_argument("--clean", "-c", action="store_true", help="Clean browser footprints and locks")
    parser.add_argument("--hotspot", "-H", choices=["on", "off", "status"], help="Manage stealth hotspot without opening menu")
    
    args = parser.parse_args()
    
    if args.quick:
        target_os = "android" if engine.os_type == "Termux" else ("windows" if engine.os_type == "Windows" else "linux")
        engine.apply_network_identity(engine.get_random_hostname(target_os))
        engine.reset_machine_id()
        engine.clean_browser_footprints()
    elif args.ghost_browser:
        engine.launch_ghost_browser()
    elif args.clean:
        engine.clean_browser_footprints()
    elif args.hotspot:
        engine.detect_network()
        iface_in = "ap0"
        iface_out = engine.active_dev if engine.active_dev != "Unknown" else "wlp4s0"
        con_name = "Hotspot-Private"
        if args.hotspot == "on":
            engine.prevent_lid_sleep(enable=True)
            # Create profile if not exist
            if subprocess.run(["nmcli", "con", "show", con_name], capture_output=True).returncode != 0:
                os.system(f'nmcli con add type wifi ifname {iface_in} con-name "{con_name}" autoconnect no ssid "NET_GHOST" 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared >/dev/null 2>&1')
                os.system(f'nmcli con modify "{con_name}" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "123456788" >/dev/null 2>&1')
            
            os.system(f"iw dev {iface_in} del >/dev/null 2>&1")
            time.sleep(0.5)
            os.system(f"iw dev {iface_out} interface add {iface_in} type __ap >/dev/null 2>&1")
            os.system(f"ip link set dev {iface_in} address {engine.get_random_mac('02:11:22')} >/dev/null 2>&1")
            os.system(f"nmcli connection up '{con_name}' >/dev/null 2>&1")
            os.system("sysctl -w net.ipv4.ip_forward=1 >/dev/null")
            os.system(f"iptables -t nat -C POSTROUTING -o {iface_out} -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o {iface_out} -j MASQUERADE")
            os.system(f"iptables -t mangle -C PREROUTING -i {iface_out} -j TTL --ttl-set 64 2>/dev/null || iptables -t mangle -A PREROUTING -i {iface_out} -j TTL --ttl-set 64")
            os.system(f"iptables -t mangle -C POSTROUTING -o {iface_out} -j TTL --ttl-set 64 2>/dev/null || iptables -t mangle -A POSTROUTING -o {iface_out} -j TTL --ttl-set 64")
            os.system(f"iptables -t mangle -C FORWARD -j TTL --ttl-set 64 2>/dev/null || iptables -t mangle -I FORWARD -j TTL --ttl-set 64")
            os.system(f"iptables -t mangle -C FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || iptables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu")
            print(f"\033[32m[✓] Stealth Hotspot ON (Lid Sleep Prevented & MikroTik Evasion Active)\033[0m")
        elif args.hotspot == "off":
            os.system(f"nmcli connection down '{con_name}' >/dev/null 2>&1")
            os.system(f"iptables -t nat -D POSTROUTING -o {iface_out} -j MASQUERADE 2>/dev/null")
            os.system(f"iptables -t mangle -D PREROUTING -i {iface_out} -j TTL --ttl-set 64 2>/dev/null")
            os.system(f"iptables -t mangle -D POSTROUTING -o {iface_out} -j TTL --ttl-set 64 2>/dev/null")
            os.system(f"iptables -t mangle -D FORWARD -j TTL --ttl-set 64 2>/dev/null")
            os.system(f"iptables -t mangle -D FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null")
            os.system(f"iw dev {iface_in} del >/dev/null 2>&1")
            engine.prevent_lid_sleep(enable=False)
            print(f"\033[32m[✓] Stealth Hotspot OFF\033[0m")
        elif args.hotspot == "status":
            os.system(f"iw dev {iface_in} station dump | grep Station || echo 'No devices connected'")
    else:
        engine.interactive_menu()

if __name__ == "__main__":
    main()
