<div align="center">
  <h1>👻 Reborn-Pro (Ghost Identity Engine)</h1>
  <p><b>محرك التخفي الأقوى، محو البصمة الرقمية، ومراوغة جدران الحماية وشبكات MikroTik متعدد المنصات.</b></p>
  <p><i>Architected for Elite Red Teaming & Anti-Fingerprint Operations by <a href="https://github.com/PMoha1">PMoha1</a></i></p>

  <p>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge" /></a>
    <img src="https://img.shields.io/badge/OS-Linux%20%7C%20Kali%20%7C%20Arch%20%7C%20Ubuntu-1793D1?style=for-the-badge&logo=linux&logoColor=white" />
    <img src="https://img.shields.io/badge/Kali_Linux-Verified-557C94?style=for-the-badge&logo=kalilinux&logoColor=white" />
    <img src="https://img.shields.io/badge/Arch_Linux-Verified-1793D1?style=for-the-badge&logo=archlinux&logoColor=white" />
    <img src="https://img.shields.io/badge/Network-MikroTik_Evasion-E02424?style=for-the-badge" />
    <img src="https://img.shields.io/badge/Bash-100%25_Native-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" />
  </p>

  <p>
    <a href="https://youtube.com/@PMoha1"><img src="https://img.shields.io/badge/YouTube-PMoha1-FF0000?style=for-the-badge&logo=youtube&logoColor=white" /></a>
    <a href="https://github.com/PMoha1"><img src="https://img.shields.io/badge/GitHub-PMoha1-181717?style=for-the-badge&logo=github&logoColor=white" /></a>
  </p>
</div>

---

## ⚡ التثبيت والتشغيل الفوري (One-Liner Instant Launch)

لتشغيل محرك التخفي مباشرة بضغطة زر واحدة في أي طرفية (Terminal):

```bash
curl -sSL https://raw.githubusercontent.com/PMoha1/Reborn-Pro/main/reborn.sh | sudo bash
```

### 📥 أو التثبيت الدائم كأمر نظام (`reborn`):

```bash
git clone https://github.com/PMoha1/Reborn-Pro.git
cd Reborn-Pro
sudo cp reborn.sh /usr/local/bin/reborn
sudo chmod +x /usr/local/bin/reborn
reborn
```

---

## 🎬 الشرح المرئي والاستوديو التفاعلي (Walkthrough & Interactive Demo)

<div align="center">
  <p>
    <a href="https://youtube.com/@PMoha1"><img src="https://img.shields.io/badge/YouTube-Watch%20Walkthrough-FF0000?style=for-the-badge&logo=youtube&logoColor=white" /></a>
    <a href="demo_showcase.html"><img src="https://img.shields.io/badge/Studio-Interactive%20Demo-00f2fe?style=for-the-badge&logo=html5&logoColor=white" /></a>
  </p>
  <p><i>📺 شاهد فيديو الشرح الكامل على يوتيوب | 🌐 وافتح ملف <a href="demo_showcase.html"><b>demo_showcase.html</b></a> لتجربة محاكاة الهويات التفاعلية بالصوت (عربي / English)</i></p>
</div>

---

## 👁️ نظرة عامة (Overview)

أداة **Reborn-Pro** هي منصة هجومية ودفاعية متقدمة مبنية بتقنيات (Native Bash Engine) صُممت خصيصاً لمحو البصمة الرقمية للأنظمة من جذورها، وإسقاط محاولات تتبع الأجهزة (Device Fingerprinting) على مستوى الشبكات السلكية واللاسلكية، وتجاوز جدران حماية الراوترات (مثل **MikroTik Hotspot**, **Captive Portals**, **NAC**).

### 🛡️ التوزيعات والبيئات المدعومة (Universal Compatibility):
| التوزيعة / النظام | حالة الدعم | ملاحظات |
|---|---|---|
| **Kali Linux** | مدعوم أصلياً 100% ✅ | متوافق تماماً مع جلسات Live Persistence ومتصفح Firefox ESR |
| **Arch Linux / CachyOS** | مدعوم أصلياً 100% ✅ | متوافق مع كافة بيئات سطح المكتب وأدوات NetworkManager |
| **Debian / Ubuntu / Mint** | مدعوم أصلياً 100% ✅ | مسار ديناميكي لمجلدات المستخدم وإعدادات الـ IP |
| **Fedora / RHEL** | مدعوم أصلياً 100% ✅ | تطابق كامل مع أوامر `hostnamectl` و `nmcli` |
| **Android (Root Magisk/KernelSU & Rootless)** | مدعوم بالكامل (Root + Knox 0x0 Safe) ✅ | يدعم أندرويد 11–17 مع كشف تلقائي لصلاحيات الـ Root (`su`) أو وضع بدون روت (Shizuku / ADB) وبيئات Termux / PRoot |
| **Termux (Native)** | مدعوم للعمليات المحمولة ✅ | يعمل عبر `reborn-android.sh` وربط الـ ADB المحلي |
| **Windows (WSL / Git Bash)** | مدعوم جزئياً ✅ | تم توفير نسخة مخصصة كاملة في مستودع Reborn-Windows |

---

## 🎯 متجهات التخفي المتقدمة (Stealth & Evasion Vectors)

بمجرد تشغيل الأداة عبر كتابة `reborn`، تتاح لك **9 متجهات تكتيكية**:

1. ⚡ **Full Reborn (الولادة الجديدة الشاملة):** تغيير هوية النظام بالكامل بضغطة زر واحدة (MAC, Hostname, Machine-ID, TTL) مع تطهير المتصفح.
2. 🎭 **تغيير هوية الشبكة فقط (Network Spoofing):** حقن بصمات مصنّعين حقيقيين (Apple, Samsung, Intel, HP, LG) وتحديث الـ DHCP لسحب آي بي جديد.
3. ⏱️ **تزييف مكدس الـ TCP/IP (TTL = 128 Spoofing):** مطابقة بصمة حزم ويندوز لتضليل قواعد كشف أنظمة لينكس في راوترات ميكروتك (Mangle / Filter Rules).
4. 🔑 **تصفير وتوليد Machine-ID جديد:** مسح المعرف العالمي للنظام لمنع تتبع التطبيقات والبرمجيات للجهاز عبر الجلسات.
5. 🧹 **تطهير بصمات المتصفح (Deep Browser Purge):** مسح ملفات الارتباط، معرّفات الـ Crashpad، وكاشات الـ GPU لمتصفحات Chrome, Chromium, Firefox, Brave.
6. 👻 **متصفح شبحي فوري (Ephemeral Ghost Browser):** إطلاق متصفح معزول بالكامل في الذاكرة العشوائية (RAM) ينحذف كلياً مع كل إغلاق.
7. 🛡️ **التمويه التلقائي الدائم (Auto-Random MAC):** إجبار NetworkManager على توليد ماك عشوائي جديد عند كل اتصال بأي شبكة لاسلكية.
8. 🔄 **استعادة الهوية الأصلية (Restore Factory Baseline):** العودة لنقطة الصفر واسترجاع الماك والاسم الأصليين للجهاز.
9. 👻 **وضع الشبح الثابت (Static IP Stealth - تجاوز الـ DHCP):** إيقاف بروتوكول الـ DHCP كلياً، وتثبيت آي بي صامت لتجاوز التسجيل في جداول الـ Lease Table الخاصة بالراوتر.

---

## 📱 محرك أندرويد الموحد للهواتف المروتة وبدون روت (Reborn Mobile v2.0 Engine)

تمت هندسة سكربت `reborn-android.sh` ليعمل بسلاسة في كلٍ من **الهواتف المروتة (Magisk / KernelSU / APatch)** كمحرك تخفٍ كامل يطابق نسخة اللابتوب، وكذلك في وضع **بدون روت (Knox 0x0 Safe)** عبر **ADB / Shizuku / Termux / PRoot**:

- **كشف تلقائي ذكي للصلاحيات والبيئة:** يكتشف تلقائياً بيئة التشغيل (`WORKSTATION_REMOTE`, `ANDROID_NATIVE`, `TERMUX`, `PROOT_CONTAINER`) ويفعّل **وضع Root (`uid=0`)** تلقائياً عند توفر `su`.
- **تبديل حقيقي للـ MAC وتجديد الـ DHCP IP (Root Engine):**
  - استخراج بيانات الشبكة الحالية من `WifiConfigStore.xml` بأمان داخل ذاكرة الروت (Open / OWE / WPA2 / WPA3 مع حماية شبكات Enterprise).
  - تدوير الماك الفعلي عبر إعادة التوثيق الديناميكي (`-r non_persistent`) وإجبار راوتر MikroTik على منح IP جديد وتخطي الحظر وإظهار بوابة الدخول فوراً.
- **تطابق كامل مع قدرات اللابتوب في وضع Root:**
  - حقن هوية الـ DHCP (`net.hostname` عبر `resetprop` + `device_name` + `bluetooth_name`).
  - تزييف بصمة مكدس الشبكة **TCP/IP TTL (`128` لويندوز / `64` لآبل وأندرويد)** لتضليل قواعد MikroTik Mangle/Filter.
  - تطهير بصمات وكاشات المتصفحات (Chrome / Tor Browser / Brave / Firefox) مع الحفاظ على المفضلات.
  - دعم **وضع الشبح الثابت (Static IP Stealth)**، تدوير `Android ID`، وحفظ واستعادة الهوية الأصلية (`restore`).

### 📥 التشغيل على أندرويد (من اللابتوب عبر ADB أو داخل الجوال/Termux):
```bash
# ولادة جديدة شاملة وتغيير الماك والآي بي والبصمات فوراً:
./reborn-android.sh

# تحديد هوية مخصصة (مثال: بصمة ويندوز TTL=128):
./reborn-android.sh --name DESKTOP-GHOST7

# فتح القائمة التفاعلية الكاملة أو عرض لوحة الحالة:
./reborn-android.sh menu
./reborn-android.sh status

# استعادة الهوية الأصلية للجهاز:
./reborn-android.sh restore
```

---

## 🚨 حل مشكلة انهيار المتصفحات (The SingletonLock Killer)

**المشكلة:**  
عندما يتم تغيير اسم مضيف النظام (Hostname) أو معرّف الجهاز (Machine-ID) بقوة أثناء تشغيل النظام، تضع متصفحات كروميوم وفيرفوكس أقفال أمان (`SingletonLock` / `.parentlock`) تمنع المتصفح من العمل ظناً منها أن ملفات التعريف نُقلت لجهاز آخر.

**الحل المدمج في Reborn-Pro (الخيار 8):**  
يقوم المحرك بالبحث في الطبقات العميقة للنظام وتدمير كافة ملفات الأقفال فورياً وإعادة إنعاش المتصفح ليعمل فوراً دون الحاجة لإعادة تشغيل النظام، مما يضمن استمرارية العمليات الأمنية بدون انقطاع.

---

## 📜 الترخيص وحفظ الملكية الفكرية (License & Copyright)

هذا المشروع مرخص بموجب **Apache License 2.0**.

> ⚠️ **إشعار الملكية الفكرية والحماية القانونية:**
> - تم ابتكار وهندسة وبناء محرك **Reborn-Pro** حصرياً بواسطة **محمد يقين (PMoha1)**.
> - يُمنع منعاً باتاً نزع اسم المطور الأصلي أو إعادة تسمية المشروع ونسبه لغير صاحبه.
> - يُسمح بالاستخدام والتطوير والبحث الأمني المشروع تحت شروط رخصة أباتشي 2.0 مع الإبقاء على إشعار الحقوق الأصلي.

**Copyright (c) 2026 Mohammed Yaqeen (PMoha1). All Rights Reserved.**

---

<div align="center">
  <b>PMoha1 | Offensive AI & Hardware Hacker</b><br>
  <i>Empowering Autonomous Cybersecurity & Ghost Operations</i><br><br>
  <a href="https://youtube.com/@PMoha1"><img src="https://img.shields.io/badge/YouTube-Subscribe-FF0000?style=for-the-badge&logo=youtube&logoColor=white" /></a>
  <a href="https://github.com/PMoha1"><img src="https://img.shields.io/badge/GitHub-Follow-181717?style=for-the-badge&logo=github&logoColor=white" /></a>
</div>
