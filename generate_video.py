#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Reborn-Pro ⚡ Official AI Video Generator
Produces 1080p Master Video Walkthrough for YouTube / PMoha1 Channel
"""

import os
import subprocess
import arabic_reshaper
from bidi.algorithm import get_display
from PIL import Image, ImageDraw, ImageFont

def ar(text):
    """Reshape and reorder Arabic text for correct rendering in Pillow"""
    if not text:
        return ""
    return get_display(arabic_reshaper.reshape(text))

WORKDIR = "/tmp/reborn_video"
OUTPUT_DIR = "/home/moha/Reborn-Pro"
OUTPUT_VIDEO = os.path.join(OUTPUT_DIR, "Reborn_Pro_Official_Walkthrough.mp4")

os.makedirs(f"{WORKDIR}/slides", exist_ok=True)
os.makedirs(f"{WORKDIR}/segments", exist_ok=True)

# Fonts
AR_BOLD = "/usr/share/fonts/noto/NotoKufiArabic-Bold.ttf"
AR_BLACK = "/usr/share/fonts/noto/NotoSansArabic-Black.ttf"
MONO_FONT = "/usr/share/fonts/TTF/CaskaydiaCoveNerdFont-SemiBold.ttf"

font_title = ImageFont.truetype(AR_BOLD, 54)
font_subtitle = ImageFont.truetype(AR_BOLD, 30)
font_card_title = ImageFont.truetype(AR_BOLD, 28)
font_card_body = ImageFont.truetype(AR_BOLD, 22)
font_mono = ImageFont.truetype(MONO_FONT, 24)
font_badge = ImageFont.truetype(AR_BOLD, 20)

C_BG = (10, 13, 20)
C_CYAN = (0, 242, 254)
C_MAGENTA = (255, 0, 127)
C_GREEN = (0, 255, 136)
C_YELLOW = (255, 208, 0)
C_RED = (255, 51, 102)
C_TEXT = (248, 250, 252)
C_DIM = (148, 163, 184)
C_CARD_BG = (18, 24, 38)
C_CARD_BORDER = (40, 55, 80)

def draw_header(draw, title_text, subtitle_text, badge_text, badge_color=C_CYAN):
    # Header bar
    draw.rectangle([(0, 0), (1920, 110)], fill=(15, 20, 32))
    draw.line([(0, 110), (1920, 110)], fill=C_CYAN, width=3)
    
    # Brand
    draw.text((80, 35), "👻 Reborn-Pro", font=font_title, fill=C_CYAN)
    draw.text((500, 48), ar("محرك التخفي الرقمي الشامل | PMoha1"), font=font_subtitle, fill=C_DIM)
    
    # Badge
    reshaped_badge = ar(badge_text)
    draw.rounded_rectangle([(1550, 35), (1840, 85)], radius=12, fill=(25, 35, 55), outline=badge_color, width=2)
    draw.text((1580, 45), reshaped_badge, font=font_badge, fill=badge_color)

    # Slide Title
    reshaped_title = ar(title_text)
    draw.text((80, 150), reshaped_title, font=font_title, fill=C_TEXT)
    reshaped_sub = ar(subtitle_text)
    draw.text((80, 225), reshaped_sub, font=font_subtitle, fill=C_DIM)

def draw_footer(draw):
    draw.rectangle([(0, 1010), (1920, 1080)], fill=(12, 16, 26))
    draw.line([(0, 1010), (1920, 1010)], fill=C_CARD_BORDER, width=2)
    draw.text((80, 1030), "YouTube: @PMoha1  |  GitHub: github.com/PMoha1/Reborn-Pro", font=font_mono, fill=C_CYAN)
    draw.text((1520, 1030), ar("مفتوح المصدر | للأمن السيبراني واختبار الاختراق"), font=font_card_body, fill=C_DIM)

# ==========================================
# Slide 1: The Problem (MikroTik Firewall Block)
# ==========================================
def render_slide_1():
    img = Image.new('RGB', (1920, 1080), color=C_BG)
    draw = ImageDraw.Draw(img)
    draw_header(draw, "المشكلة: حظر أنظمة لينكس والأجهزة المروّتة في شبكات ميكروتك",
                "كيف تكتشف راوترات وجدران الحماية هويتك وتعزلك فوراً؟",
                "المشهد الأول: الرصد والحظر", C_RED)

    # Box 1: DHCP Hostname Leak
    draw.rounded_rectangle([(80, 310), (640, 850)], radius=16, fill=C_CARD_BG, outline=C_RED, width=2)
    draw.text((120, 350), ar("1. تسريب اسم الجهاز (DHCP Option 12)"), font=font_card_title, fill=C_RED)
    draw.text((120, 420), ar("عند اتصال كالي لينكس بالشبكة:"), font=font_card_body, fill=C_TEXT)
    draw.rectangle([(120, 470), (600, 550)], fill=(30, 20, 25), outline=C_RED)
    draw.text((140, 495), "Host-Name: 'kali' [DETECTED]", font=font_mono, fill=C_RED)
    draw.text((120, 580), ar("يقوم الراوتر فوراً بمطابقة الاسم\nوحظر المستخدم أو كرت الإنترنت\nمن الوصول للبوابة كلياً."), font=font_card_body, fill=C_DIM)

    # Box 2: TTL Fingerprint
    draw.rounded_rectangle([(680, 310), (1240, 850)], radius=16, fill=C_CARD_BG, outline=C_YELLOW, width=2)
    draw.text((720, 350), ar("2. بصمة نواة لينكس (TTL = 64)"), font=font_card_title, fill=C_YELLOW)
    draw.text((720, 420), ar("قيمة زمن البقاء للحزم الصادرة:"), font=font_card_body, fill=C_TEXT)
    draw.rectangle([(720, 470), (1200, 550)], fill=(30, 28, 20), outline=C_YELLOW)
    draw.text((740, 495), "IP Packet TTL: 64 (Linux Kernel)", font=font_mono, fill=C_YELLOW)
    draw.text((720, 580), ar("قواعد ميكروتك (Mangle / Filter)\nتصنف الحزم كأجهزة لينكس أو أجهزة\nمعدلة وتقوم بإسقاطها فوراً."), font=font_card_body, fill=C_DIM)

    # Box 3: Rooted Devices & Portals
    draw.rounded_rectangle([(1280, 310), (1840, 850)], radius=16, fill=C_CARD_BG, outline=C_MAGENTA, width=2)
    draw.text((1320, 350), ar("3. كشف أجهزة الروت وبصمة المتصفح"), font=font_card_title, fill=C_MAGENTA)
    draw.text((1320, 420), ar("صفحات تسجيل الدخول (Captive Portal):"), font=font_card_body, fill=C_TEXT)
    draw.rectangle([(1320, 470), (1800, 550)], fill=(30, 20, 35), outline=C_MAGENTA)
    draw.text((1340, 495), "User-Agent: Linux x86_64", font=font_mono, fill=C_MAGENTA)
    draw.text((1320, 580), ar("تتبع الكوكيز، بصمات المعالجات،\nومعرفات الـ MAC الموثقة سابقاً\nلمنع إعادة تسجيل الدخول."), font=font_card_body, fill=C_DIM)

    draw_footer(draw)
    img.save(f"{WORKDIR}/slides/scene_1.png")

# ==========================================
# Slide 2: The Solution & Harmless Personas
# ==========================================
def render_slide_2():
    img = Image.new('RGB', (1920, 1080), color=C_BG)
    draw = ImageDraw.Draw(img)
    draw_header(draw, "الحل: التخفي الذكي والتنكر بهويات أجهزة بريئة تماماً",
                "لماذا نحارب الجدران النارية بينما يمكننا المرور أمامها كهوية لا تشك فيها أي شبكة؟",
                "المشهد الثاني: فلسفة التنكر", C_GREEN)

    personas = [
        ("🖨️ طابعة شبكية (HP LaserJet)", "HP-LaserJet-Pro-M404", "MAC: 00:0E:7F (HP OUI)", "مسموح بمرور الترافيك للطباعة بدون حظر"),
        ("📺 شاشة ذكية (LG Smart TV)", "LG-webOSTV-OLED", "MAC: 00:05:CD (LG OUI)", "حصة اتصال واسعة وبدون تدقيق"),
        ("💻 لابتوب رسمي (Windows 11 PC)", "DESKTOP-9B4X2L1", "MAC: Intel | TTL: 128", "مطابقة حزم ويندوز الأصلية 100%"),
        ("🍏 هاتف آبل (iPhone 16 Pro)", "iPhone-16-Pro", "MAC: BC:D0:74 (Apple OUI)", "هوية VIP مقبولة في كافة بوابات الـ Hotspot")
    ]

    for i, (title, name, mac, desc) in enumerate(personas):
        x = 80 + i * 440
        draw.rounded_rectangle([(x, 310), (x + 410, 850)], radius=16, fill=C_CARD_BG, outline=C_CYAN, width=2)
        draw.text((x + 25, 350), ar(title), font=font_card_title, fill=C_CYAN)
        
        # Details Box
        draw.rectangle([(x + 25, 430), (x + 385, 590)], fill=(12, 18, 30), outline=C_CARD_BORDER)
        draw.text((x + 40, 450), "Hostname:", font=font_mono, fill=C_DIM)
        draw.text((x + 40, 480), name, font=font_mono, fill=C_GREEN)
        draw.text((x + 40, 520), mac, font=font_mono, fill=C_YELLOW)

        draw.text((x + 25, 630), ar(desc), font=font_card_body, fill=C_TEXT)
        draw.text((x + 25, 730), ar("✔ تجاوز آلي لفلاتر ميكروتك"), font=font_card_body, fill=C_GREEN)

    draw_footer(draw)
    img.save(f"{WORKDIR}/slides/scene_2.png")

# ==========================================
# Slide 3: The 9 Vectors Matrix
# ==========================================
def render_slide_3():
    img = Image.new('RGB', (1920, 1080), color=C_BG)
    draw = ImageDraw.Draw(img)
    draw_header(draw, "مصفوفة خيارات Reborn-Pro الـ 9 للتحكم الكامل",
                "أقوى محرك لإخفاء الهوية الرقمية ومحو البصمات من جذور النظام بضغطة زر واحدة",
                "المشهد الثالث: خيارات الأداة", C_YELLOW)

    vectors = [
        ("1. Full Reborn", "الولادة الجديدة الشاملة (تغيير كل شيء في ثوانٍ)"),
        ("2. Network Spoofing", "تمويه الشبكة فقط (الماك والاسم والآي بي)"),
        ("3. Reset Machine-ID", "تصفير معرف النظام العميق لمسح تعقب التطبيقات"),
        ("4. Browser Purge", "تطهير كاشات وبصمات ومخلفات HSTS للمتصفحات"),
        ("5. Ephemeral Ghost", "متصفح شبحي معزول 100% داخل الرام بدون أثر"),
        ("6. Auto-Random MAC", "تمويه تلقائي مستمر مع كل اتصال واي فاي جديد"),
        ("7. Restore Baseline", "استعادة الهوية الأصلية للجهاز وضبط المصنع"),
        ("8. Fix Browser Locks", "تدمير أقفال SingletonLocks لمنع انهيار كروم"),
        ("9. Static IP Stealth", "وضع الشبح الثابت وتجاوز جدول الـ DHCP كلياً")
    ]

    for i, (title, desc) in enumerate(vectors):
        row = i // 3
        col = i % 3
        x = 80 + col * 590
        y = 310 + row * 185
        
        draw.rounded_rectangle([(x, y), (x + 560, y + 160)], radius=14, fill=C_CARD_BG, outline=C_CARD_BORDER, width=2)
        draw.text((x + 25, y + 25), title, font=font_card_title, fill=C_YELLOW)
        draw.text((x + 25, y + 75), ar(desc), font=font_card_body, fill=C_TEXT)

    draw_footer(draw)
    img.save(f"{WORKDIR}/slides/scene_3.png")

# ==========================================
# Slide 4: MikroTik Bypass in Action
# ==========================================
def render_slide_4():
    img = Image.new('RGB', (1920, 1080), color=C_BG)
    draw = ImageDraw.Draw(img)
    draw_header(draw, "النتيجة الميدانية: تجاوز جدار حماية ميكروتك بنجاح باهر",
                "مقارنة حية قبل وبعد استخدام أداة Reborn-Pro",
                "المشهد الرابع: التطبيق العملي", C_GREEN)

    # Left: Before (Blocked)
    draw.rounded_rectangle([(80, 310), (920, 850)], radius=16, fill=(25, 15, 20), outline=C_RED, width=3)
    draw.text((120, 350), ar("❌ قبل استخدام الأداة (الحالة: محظور ومكشوف)"), font=font_card_title, fill=C_RED)
    draw.text((120, 430), "• DHCP Hostname: kali (Linux Detected)", font=font_mono, fill=C_TEXT)
    draw.text((120, 480), "• TCP/IP TTL:    64 (Default Kernel)", font=font_mono, fill=C_RED)
    draw.text((120, 530), "• MAC Address:   00:0c:29 (Known Adapter)", font=font_mono, fill=C_TEXT)
    draw.text((120, 580), "• Browser State: Locked / Blocked", font=font_mono, fill=C_RED)
    draw.text((120, 680), "MIKROTIK VERDICT: ACCESS DENIED ❌", font=font_title, fill=C_RED)

    # Right: After (Allowed & Ghosted)
    draw.rounded_rectangle([(1000, 310), (1840, 850)], radius=16, fill=(15, 28, 25), outline=C_GREEN, width=3)
    draw.text((1040, 350), ar("✔ بعد تشغيل Reborn-Pro (الحالة: مسموح وعبور كامل)"), font=font_card_title, fill=C_GREEN)
    draw.text((1040, 430), "• DHCP Hostname: DESKTOP-9B4X2L1 (Windows 11)", font=font_mono, fill=C_TEXT)
    draw.text((1040, 480), "• TCP/IP TTL:    128 (Windows Packets)", font=font_mono, fill=C_GREEN)
    draw.text((1040, 530), "• MAC Address:   00:1B:77 (Intel Genuine OUI)", font=font_mono, fill=C_YELLOW)
    draw.text((1040, 580), "• Browser State: SingletonLocks Destroyed ✔", font=font_mono, fill=C_GREEN)
    draw.text((1040, 680), "MIKROTIK VERDICT: ALLOWED & BYPASSED ✔", font=font_title, fill=C_GREEN)

    draw_footer(draw)
    img.save(f"{WORKDIR}/slides/scene_4.png")

# ==========================================
# Slide 5: One-Liner Install & Call to Action
# ==========================================
def render_slide_5():
    img = Image.new('RGB', (1920, 1080), color=C_BG)
    draw = ImageDraw.Draw(img)
    draw_header(draw, "التشغيل الفوري بضغطة زر واحدة ومفتوح المصدر",
                "الأداة تدعم اللغتين العربية والإنجليزية ومتوافقة مع كالي وآرش وأوبونتو وفيدورا",
                "المشهد الخامس: التثبيت والدعم", C_CYAN)

    # Command Showcase Box
    draw.rounded_rectangle([(80, 330), (1840, 530)], radius=16, fill=(12, 18, 30), outline=C_CYAN, width=3)
    draw.text((120, 360), ar("⚡ أمر التشغيل المباشر من الطرفية بدون أي تحميل معقد:"), font=font_card_title, fill=C_YELLOW)
    draw.text((120, 430), "$ curl -sSL https://raw.githubusercontent.com/PMoha1/Reborn-Pro/main/reborn.sh | sudo bash", font=font_mono, fill=C_GREEN)

    # Channels & Links Box
    draw.rounded_rectangle([(80, 580), (920, 850)], radius=16, fill=C_CARD_BG, outline=C_MAGENTA, width=2)
    draw.text((120, 620), ar("📺 قناة اليوتيوب الرسمية للمطور:"), font=font_card_title, fill=C_MAGENTA)
    draw.text((120, 680), "https://youtube.com/@PMoha1", font=font_mono, fill=C_CYAN)
    draw.text((120, 740), ar("اشترك لمتابعة أحدث أدوات الأمن السيبراني والذكاء الاصطناعي الهجومي"), font=font_card_body, fill=C_TEXT)

    draw.rounded_rectangle([(1000, 580), (1840, 850)], radius=16, fill=C_CARD_BG, outline=C_GREEN, width=2)
    draw.text((1040, 620), ar("🐙 مستودع المشروع على GitHub:"), font=font_card_title, fill=C_GREEN)
    draw.text((1040, 680), "https://github.com/PMoha1/Reborn-Pro", font=font_mono, fill=C_CYAN)
    draw.text((1040, 740), ar("ضع نجمة (Star) للمستودع وساهم في تطوير أدوات التخفي المفتوحة"), font=font_card_body, fill=C_TEXT)

    draw_footer(draw)
    img.save(f"{WORKDIR}/slides/scene_5.png")

print("Rendering all 5 slide images...")
render_slide_1()
render_slide_2()
render_slide_3()
render_slide_4()
render_slide_5()
print("All slide images rendered successfully!")
