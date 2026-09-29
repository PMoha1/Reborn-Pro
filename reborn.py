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

# Colors
C_RESET   = "\033[0m"
C_BOLD    = "\033[1m"
C_DIM     = "\033[2m"
C_RED     = "\033[31m"
C_GREEN   = "\033[32m"
C_YELLOW  = "\033[33m"
C_BLUE    = "\033[34m"
C_MAGENTA = "\033[35m"
C_CYAN    = "\033[36m"

BANNER = f"""{C_MAGENTA}
  ██████╗ ███████╗██████╗  ██████╗ ██████╗ ███╗   ██╗
  ██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗████╗  ██║
  ██████╔╝█████╗  ██████╔╝██║   ██║██████╔╝██╔██╗ ██║
  ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║
  ██║  ██║███████╗██████╔╝╚██████╔╝██║  ██║██║ ╚████║
  ╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
{C_RESET}{C_DIM}  — Reborn Anti-Fingerprint & Ghost Engine (Cross-Platform) —{C_RESET}
{C_GREEN}  المطور: محمد يقين مجمل الفايق - صنعاء، اليمن 🇾🇪{C_RESET}
"""

class RebornEngine:
    def __init__(self):
        self.os_type = platform.system()
        self.is_termux = "com.termux" in os.environ.get("PREFIX", "") or os.path.exists("/data/data/com.termux")
        if self.is_termux:
            self.os_type = "Termux"
            
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
            subprocess.run(["systemctl", "restart", "NetworkManager"], capture_output=True)

        elif self.os_type == "Windows":
            # Change Hostname
            subprocess.run(["powershell", "-Command", f"Rename-Computer -NewName {name}"], capture_output=True)
            # Change MAC Address requires registry modification on Windows, using generic message
            print(f"{C_YELLOW}[!] تم جدولة تغيير اسم الويندوز، الماك يتطلب أدوات طرف ثالث أو تعديل الريجستري اليدوي لكرت الشبكة.{C_RESET}")
            print(f"{C_YELLOW}[!] لتطبيق الاسم الجديد كلياً في الويندوز يرجى إعادة التشغيل لاحقاً.{C_RESET}")

        elif self.os_type == "Termux":
            subprocess.run(["su", "-c", f"setprop net.hostname {name}"], capture_output=True)
            print(f"{C_CYAN}▸ تدوير الماك في الأندرويد يتطلب دعم النواة (Kernel)...{C_RESET}")
            subprocess.run(["su", "-c", "ip link set wlan0 down"], capture_output=True)
            subprocess.run(["su", "-c", f"macchanger -m {mac} wlan0"], capture_output=True)
            subprocess.run(["su", "-c", "ip link set wlan0 up"], capture_output=True)

        print(f"{C_GREEN}✔ اكتمل التمويه وتحديث الهوية!{C_RESET}")

    def launch_ghost_browser(self):
        print(f"\n{C_CYAN}▸ إطلاق متصفح شبحي معزول بالكامل في الذاكرة الحية (RAM)...{C_RESET}")
        if self.os_type == "Linux":
            # Use /tmp for isolated RAM profile
            profile_dir = f"/tmp/ghost_chrome_{random.randint(1000,9999)}"
            cmd = f"nohup google-chrome --user-data-dir={profile_dir} --no-first-run --incognito >/dev/null 2>&1 &"
            os.system(cmd)
            print(f"{C_GREEN}✔ تم إطلاق المتصفح الشبحي بنجاح!{C_RESET}")
        else:
            print(f"{C_YELLOW}[!] المتصفح الشبحي في الذاكرة مدعوم حالياً على نظام لينكس بشكل كامل.{C_RESET}")

    def interactive_menu(self):
        while True:
            os.system("clear" if self.os_type != "Windows" else "cls")
            print(BANNER)
            print(f"{C_BOLD}{C_WHITE}الخيارات والعمليات المتاحة:{C_RESET}")
            print(f"  {C_CYAN}[1]{C_RESET} {C_BOLD}⚡ ولادة جديدة شاملة (Full Reborn - محو كل البصمات وتوليد هوية عشوائية){C_RESET}")
            print(f"  {C_CYAN}[2]{C_RESET} 🎭 {C_BOLD}تغيير هوية الشبكة فقط (الاسم + الماك){C_RESET}")
            print(f"  {C_CYAN}[3]{C_RESET} 🔑 {C_BOLD}تصفير وتوليد Machine-ID جديد للنظام{C_RESET}")
            print(f"  {C_CYAN}[4]{C_RESET} 🧹 {C_BOLD}تطهير بصمات المتصفح وفك الأقفال{C_RESET}")
            print(f"  {C_CYAN}[5]{C_RESET} 👻 {C_BOLD}فتح متصفح شبحي فوري (معزول في الرام - Linux فقط){C_RESET}")
            print(f"  {C_RED}[0]{C_RESET} خروج (Exit)")
            
            try:
                opt = input(f"\n{C_YELLOW}اختر العملية [0-5]: {C_RESET}")
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
            elif opt == "4":
                self.clean_browser_footprints()
            elif opt == "5":
                self.launch_ghost_browser()
            elif opt == "0":
                print(f"\n{C_GREEN}في أمان الله!{C_RESET}\n")
                break
            else:
                print(f"{C_RED}خيار غير صالح!{C_RESET}")
            
            input(f"\n{C_DIM}اضغط Enter للعودة إلى القائمة...{C_RESET}")

def main():
    engine = RebornEngine()
    engine.check_privileges()
    
    parser = argparse.ArgumentParser(description="Reborn ⚡ Ghost Identity & Fingerprint Eraser")
    parser.add_argument("--quick", "-q", action="store_true", help="Quick random identity spoofing and footprint purge")
    parser.add_argument("--ghost-browser", "-g", action="store_true", help="Launch isolated ghost browser in RAM")
    parser.add_argument("--clean", "-c", action="store_true", help="Clean browser footprints and locks")
    
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
