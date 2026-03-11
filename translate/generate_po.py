#!/usr/bin/env python3
"""Generate .po translation files for KDE Connect SMS plasmoid."""
import os
import datetime

DIR = os.path.dirname(os.path.abspath(__file__))

TRANSLATIONS = {
    "fr": {
        "language": "French",
        "team": "French <fr@li.org>",
        "strings": {
            "General": "Général",
            "Device name:": "Nom de l'appareil :",
            "KDE Connect paired device name": "Nom de l'appareil associé via KDE Connect",
            "Country calling code:": "Indicatif pays :",
            "+33": "+33",
            "Beep after sending:": "Bip après envoi :",
            "Play a beep sound after SMS is sent": "Jouer un bip sonore après l'envoi du SMS",
            "Beep repetitions:": "Nombre de bips :",
            "KDE Connect SMS — Coming soon": "KDE Connect SMS — Bientôt disponible",
        },
    },
    "de": {
        "language": "German",
        "team": "German <de@li.org>",
        "strings": {
            "General": "Allgemein",
            "Device name:": "Gerätename:",
            "KDE Connect paired device name": "Name des mit KDE Connect gekoppelten Geräts",
            "Country calling code:": "Landesvorwahl:",
            "+33": "+49",
            "Beep after sending:": "Signalton nach dem Senden:",
            "Play a beep sound after SMS is sent": "Signalton nach dem Senden der SMS abspielen",
            "Beep repetitions:": "Signalton-Wiederholungen:",
            "KDE Connect SMS — Coming soon": "KDE Connect SMS — Demnächst verfügbar",
        },
    },
    "es": {
        "language": "Spanish",
        "team": "Spanish <es@li.org>",
        "strings": {
            "General": "General",
            "Device name:": "Nombre del dispositivo:",
            "KDE Connect paired device name": "Nombre del dispositivo emparejado con KDE Connect",
            "Country calling code:": "Código de llamada del país:",
            "+33": "+34",
            "Beep after sending:": "Pitido tras enviar:",
            "Play a beep sound after SMS is sent": "Reproducir un pitido después de enviar el SMS",
            "Beep repetitions:": "Repeticiones del pitido:",
            "KDE Connect SMS — Coming soon": "KDE Connect SMS — Próximamente",
        },
    },
    "pt_BR": {
        "language": "Portuguese (Brazil)",
        "team": "Brazilian Portuguese <pt_BR@li.org>",
        "strings": {
            "General": "Geral",
            "Device name:": "Nome do dispositivo:",
            "KDE Connect paired device name": "Nome do dispositivo pareado com KDE Connect",
            "Country calling code:": "Código de chamada do país:",
            "+33": "+55",
            "Beep after sending:": "Bip após enviar:",
            "Play a beep sound after SMS is sent": "Reproduzir um bip após o envio do SMS",
            "Beep repetitions:": "Repetições do bip:",
            "KDE Connect SMS — Coming soon": "KDE Connect SMS — Em breve",
        },
    },
    "ru": {
        "language": "Russian",
        "team": "Russian <ru@li.org>",
        "strings": {
            "General": "Общие",
            "Device name:": "Имя устройства:",
            "KDE Connect paired device name": "Имя устройства, сопряжённого через KDE Connect",
            "Country calling code:": "Код страны:",
            "+33": "+7",
            "Beep after sending:": "Звуковой сигнал после отправки:",
            "Play a beep sound after SMS is sent": "Воспроизводить звуковой сигнал после отправки SMS",
            "Beep repetitions:": "Количество сигналов:",
            "KDE Connect SMS — Coming soon": "KDE Connect SMS — Скоро",
        },
    },
    "zh_CN": {
        "language": "Chinese (Simplified)",
        "team": "Chinese (Simplified) <zh_CN@li.org>",
        "strings": {
            "General": "常规",
            "Device name:": "设备名称：",
            "KDE Connect paired device name": "KDE Connect 已配对的设备名称",
            "Country calling code:": "国际区号：",
            "+33": "+86",
            "Beep after sending:": "发送后提示音：",
            "Play a beep sound after SMS is sent": "短信发送后播放提示音",
            "Beep repetitions:": "提示音重复次数：",
            "KDE Connect SMS — Coming soon": "KDE Connect 短信 — 即将推出",
        },
    },
    "ja": {
        "language": "Japanese",
        "team": "Japanese <ja@li.org>",
        "strings": {
            "General": "一般",
            "Device name:": "デバイス名：",
            "KDE Connect paired device name": "KDE Connect でペアリングされたデバイス名",
            "Country calling code:": "国番号：",
            "+33": "+81",
            "Beep after sending:": "送信後のビープ音：",
            "Play a beep sound after SMS is sent": "SMS送信後にビープ音を再生",
            "Beep repetitions:": "ビープ音の繰り返し回数：",
            "KDE Connect SMS — Coming soon": "KDE Connect SMS — 近日公開",
        },
    },
    "ko": {
        "language": "Korean",
        "team": "Korean <ko@li.org>",
        "strings": {
            "General": "일반",
            "Device name:": "장치 이름:",
            "KDE Connect paired device name": "KDE Connect로 페어링된 장치 이름",
            "Country calling code:": "국가 전화 코드:",
            "+33": "+82",
            "Beep after sending:": "전송 후 알림음:",
            "Play a beep sound after SMS is sent": "SMS 전송 후 알림음 재생",
            "Beep repetitions:": "알림음 반복 횟수:",
            "KDE Connect SMS — Coming soon": "KDE Connect SMS — 곧 출시",
        },
    },
    "it": {
        "language": "Italian",
        "team": "Italian <it@li.org>",
        "strings": {
            "General": "Generale",
            "Device name:": "Nome dispositivo:",
            "KDE Connect paired device name": "Nome del dispositivo abbinato con KDE Connect",
            "Country calling code:": "Prefisso internazionale:",
            "+33": "+39",
            "Beep after sending:": "Segnale acustico dopo l'invio:",
            "Play a beep sound after SMS is sent": "Riprodurre un segnale acustico dopo l'invio dell'SMS",
            "Beep repetitions:": "Ripetizioni del segnale:",
            "KDE Connect SMS — Coming soon": "KDE Connect SMS — In arrivo",
        },
    },
    "nl": {
        "language": "Dutch",
        "team": "Dutch <nl@li.org>",
        "strings": {
            "General": "Algemeen",
            "Device name:": "Apparaatnaam:",
            "KDE Connect paired device name": "Naam van het gekoppelde KDE Connect-apparaat",
            "Country calling code:": "Landnummer:",
            "+33": "+31",
            "Beep after sending:": "Pieptoon na verzending:",
            "Play a beep sound after SMS is sent": "Pieptoon afspelen na het verzenden van het SMS-bericht",
            "Beep repetitions:": "Pieptoon herhalingen:",
            "KDE Connect SMS — Coming soon": "KDE Connect SMS — Binnenkort beschikbaar",
        },
    },
    "pl": {
        "language": "Polish",
        "team": "Polish <pl@li.org>",
        "strings": {
            "General": "Ogólne",
            "Device name:": "Nazwa urządzenia:",
            "KDE Connect paired device name": "Nazwa urządzenia sparowanego z KDE Connect",
            "Country calling code:": "Numer kierunkowy kraju:",
            "+33": "+48",
            "Beep after sending:": "Sygnał dźwiękowy po wysłaniu:",
            "Play a beep sound after SMS is sent": "Odtwórz sygnał dźwiękowy po wysłaniu SMS-a",
            "Beep repetitions:": "Powtórzenia sygnału:",
            "KDE Connect SMS — Coming soon": "KDE Connect SMS — Wkrótce",
        },
    },
    "tr": {
        "language": "Turkish",
        "team": "Turkish <tr@li.org>",
        "strings": {
            "General": "Genel",
            "Device name:": "Aygıt adı:",
            "KDE Connect paired device name": "KDE Connect ile eşleştirilmiş aygıt adı",
            "Country calling code:": "Ülke arama kodu:",
            "+33": "+90",
            "Beep after sending:": "Gönderdikten sonra bip sesi:",
            "Play a beep sound after SMS is sent": "SMS gönderildikten sonra bip sesi çal",
            "Beep repetitions:": "Bip sesi tekrarı:",
            "KDE Connect SMS — Coming soon": "KDE Connect SMS — Yakında",
        },
    },
    "ar": {
        "language": "Arabic",
        "team": "Arabic <ar@li.org>",
        "strings": {
            "General": "عام",
            "Device name:": "اسم الجهاز:",
            "KDE Connect paired device name": "اسم الجهاز المقترن عبر KDE Connect",
            "Country calling code:": "رمز الاتصال الدولي:",
            "+33": "+966",
            "Beep after sending:": "صوت تنبيه بعد الإرسال:",
            "Play a beep sound after SMS is sent": "تشغيل صوت تنبيه بعد إرسال الرسالة القصيرة",
            "Beep repetitions:": "عدد تكرارات التنبيه:",
            "KDE Connect SMS — Coming soon": "KDE Connect SMS — قريبًا",
        },
    },
    "uk": {
        "language": "Ukrainian",
        "team": "Ukrainian <uk@li.org>",
        "strings": {
            "General": "Загальні",
            "Device name:": "Назва пристрою:",
            "KDE Connect paired device name": "Назва пристрою, з'єднаного через KDE Connect",
            "Country calling code:": "Код країни:",
            "+33": "+380",
            "Beep after sending:": "Звуковий сигнал після надсилання:",
            "Play a beep sound after SMS is sent": "Відтворити звуковий сигнал після надсилання SMS",
            "Beep repetitions:": "Кількість сигналів:",
            "KDE Connect SMS — Coming soon": "KDE Connect SMS — Незабаром",
        },
    },
    "cs": {
        "language": "Czech",
        "team": "Czech <cs@li.org>",
        "strings": {
            "General": "Obecné",
            "Device name:": "Název zařízení:",
            "KDE Connect paired device name": "Název zařízení spárovaného přes KDE Connect",
            "Country calling code:": "Mezinárodní předvolba:",
            "+33": "+420",
            "Beep after sending:": "Zvukový signál po odeslání:",
            "Play a beep sound after SMS is sent": "Přehrát zvukový signál po odeslání SMS",
            "Beep repetitions:": "Počet opakování signálu:",
            "KDE Connect SMS — Coming soon": "KDE Connect SMS — Již brzy",
        },
    },
}


def generate_po(lang, data):
    """Generate a .po file for the given language."""
    now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M%z")
    header = f"""# Translation of KDE Connect SMS
# Copyright (C) {datetime.datetime.now().year} David DIVERRES
# This file is distributed under the same license as the kdeconnectsms package.
#
msgid ""
msgstr ""
"Project-Id-Version: kdeconnectsms\\n"
"Report-Msgid-Bugs-To: https://www.comexpertise.com\\n"
"POT-Creation-Date: {now}\\n"
"PO-Revision-Date: {now}\\n"
"Last-Translator: David DIVERRES <david@comexpertise.com>\\n"
"Language-Team: {data['team']}\\n"
"Language: {lang}\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"""

    def po_escape(s):
        return s.replace('\\', '\\\\').replace('"', '\\"')

    entries = []
    for msgid, msgstr in data["strings"].items():
        entries.append(f'msgid "{po_escape(msgid)}"\nmsgstr "{po_escape(msgstr)}"')

    content = header + "\n" + "\n\n".join(entries) + "\n"

    filepath = os.path.join(DIR, f"{lang}.po")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"  Generated: {filepath}")


if __name__ == "__main__":
    print(f"Generating .po files for {len(TRANSLATIONS)} languages...")
    for lang, data in sorted(TRANSLATIONS.items()):
        generate_po(lang, data)
    print("Done.")
