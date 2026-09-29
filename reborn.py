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
            # Hostname
            try:
                with open("/etc/hostname", "r") as f:
                    self.current_hostname = f.read().strip()
            except:
                self.current_hostname = subprocess.getoutput("hostname")
            
            # Machine ID
            try:
                with open("/etc/machine-id", "r") as f:
                    self.current_machine_id = f.read().strip()
            except:
                self.current_machine_id = "None"
                
            # Network Device & IP
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
        
        # We print in pure Arabic first to maintain RTL formatting properly in terminals like QTerminal
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
        # Formatted cleanly for RTL without starting brackets that flip the terminal
        print("  1 - ولادة جديدة شاملة (محو كل البصمات بضغطة زر واحدة ⚡)")
        print("  2 - تغيير هوية الشبكة فقط (الاسم + الماك + تجديد الـ IP)")
        print("  3 - تصفير وتوليد Machine-ID جديد للنظام (محو البصمة العميقة)")
        print("  4 - تطهير بصمات المتصفح وفك الأقفال (Crashpad / UUIDs / Locks)")
        print("  5 - فتح متصفح شبحي فوري (معزول 100% في الرام - Linux)")
        print("  6 - تفعيل وضع التمويه الدائم التلقائي في الشبكات (Auto MAC)")
        print("  7 - استعادة الهوية الأصلية للجهاز (Restore Baseline)")
        print("  8 - إصلاح وفك أقفال متصفح كروم فورياً (Fix Chrome Locks)")
        print("  9 - وضع الشبح الثابت (Static IP - إيقاف الـ DHCP كلياً للتخفي)")
        print("  10 - إدارة شبكة البث المخفية (Stealth Hotspot - تجاوز حظر التوزيع)")
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
            # Change Hostname
            subprocess.run(["hostnamectl", "set-hostname", name], capture_output=True)
            # Find Active Interface
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
            
            # Renew Network
            if self.active_con != "Unknown":
                subprocess.run(["nmcli", "con", "up", self.active_con], capture_output=True)
            else:
                subprocess.run(["systemctl", "restart", "NetworkManager"], capture_output=True)

        elif self.os_type == "Windows":
            subprocess.run(["powershell", "-Command", f"Rename-Computer -NewName {name}"], capture_output=True)
            print(f"{C_YELLOW}[!] تم تغيير الاسم في الويندوز (يحتاج إعادة تشغيل لاحقاً). لتغيير الماك يرجى تعديل كرت الشبكة يدوياً.{C_RESET}")

        elif self.os_type == "Termux":
            subprocess.run(["su", "-c", f"setprop net.hostname {name}"], capture_output=True)
            print(f"{C_CYAN}▸ يتم تغيير الماك الآن...{C_RESET}")
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
        else:
            print(f"{C_YELLOW}[!] المتصفح الشبحي في الذاكرة مدعوم حالياً على نظام لينكس.{C_RESET}")


    def stealth_hotspot_menu(self):
        print(f"\n{C_CYAN}▸ إدارة نقطة البث المخفية (Stealth Hotspot)...{C_RESET}")
        if self.os_type != "Linux":
            print(f"{C_YELLOW}[!] هذه الميزة مخصصة لنظام لينكس حالياً.{C_RESET}")
            return
            
        print(f"  1 - تشغيل البث (تجاوز الحظر + TTL 64)")
        print(f"  2 - إيقاف البث")
        print(f"  3 - حالة البث (الأجهزة المتصلة)")
        print(f"  0 - رجوع")
        
        opt = input(f"\n{C_YELLOW}  اختر العملية [0-3]: {C_RESET}")
        
        iface_in = "ap0"
        iface_out = self.active_dev if self.active_dev != "Unknown" else "wlp4s0"
        con_name = "Hotspot-Private"
        
        if opt == "1":
            print(f"\n{C_MAGENTA}[+] جاري تشغيل نقطة البث المخفية...{C_RESET}")
            os.system(f"iw dev {iface_out} interface add {iface_in} type __ap >/dev/null 2>&1")
            time.sleep(1)
            if os.system(f"nmcli connection up '{con_name}' >/dev/null 2>&1") != 0:
                print(f"{C_RED}[!] فشل بدء الشبكة عبر NetworkManager، تأكد من وجود ملف الاتصال ({con_name}).{C_RESET}")
            else:
                os.system("sysctl -w net.ipv4.ip_forward=1 >/dev/null")
                os.system(f"iptables -t mangle -C PREROUTING -i {iface_out} -j TTL --ttl-set 64 2>/dev/null || iptables -t mangle -A PREROUTING -i {iface_out} -j TTL --ttl-set 64")
                os.system(f"iptables -t mangle -C POSTROUTING -o {iface_out} -j TTL --ttl-set 64 2>/dev/null || iptables -t mangle -A POSTROUTING -o {iface_out} -j TTL --ttl-set 64")
                os.system(f"iptables -t nat -C POSTROUTING -s 10.42.0.0/24 -o {iface_out} -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 10.42.0.0/24 -o {iface_out} -j MASQUERADE")
                print(f"{C_GREEN}[✓] تم تشغيل الشبكة بنجاح وبوضع التخفي الكامل!{C_RESET}")
        elif opt == "2":
            print(f"\n{C_YELLOW}[-] جاري إيقاف نقطة البث وتفريغ القواعد...{C_RESET}")
            os.system(f"nmcli connection down '{con_name}' >/dev/null 2>&1")
            os.system(f"iptables -t mangle -D PREROUTING -i {iface_out} -j TTL --ttl-set 64 2>/dev/null")
            os.system(f"iptables -t mangle -D POSTROUTING -o {iface_out} -j TTL --ttl-set 64 2>/dev/null")
            os.system(f"iw dev {iface_in} del >/dev/null 2>&1")
            print(f"{C_GREEN}[✓] تم الإيقاف بنجاح.{C_RESET}")
        elif opt == "3":
            print(f"\n{C_CYAN}=== حالة نقطة البث ==={C_RESET}")
            if os.system(f"iw dev | grep -q 'Interface {iface_in}'") == 0:
                print(f"[*] الحالة: {C_GREEN}تعمل الآن (ON){C_RESET}")
                print(f"[*] الأجهزة المتصلة:")
                os.system(f"iw dev {iface_in} station dump | grep Station || echo '  (لا توجد أجهزة متصلة)'")
            else:
                print(f"[*] الحالة: {C_RED}متوقفة (OFF){C_RESET}")

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
        else:
            print(f"{C_YELLOW}[!] هذه الميزة مدعومة في نظام لينكس (NetworkManager).{C_RESET}")

    def interactive_menu(self):
        while True:
            os.system("clear" if self.os_type != "Windows" else "cls")
            print(BANNER)
            # Safe Arabic formatting avoiding flip
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
    else:
        engine.interactive_menu()

if __name__ == "__main__":
    main()
