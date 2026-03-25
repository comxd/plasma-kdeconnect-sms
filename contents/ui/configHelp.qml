/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: helpRoot

    ColumnLayout {
        id: helpPage
        width: parent.width
        spacing: 0

    // ── FAQ Component ──

    component FaqItem: ColumnLayout {
        id: faqRoot
        spacing: 0
        Layout.fillWidth: true

        required property string question
        required property string answer

        property bool expanded: false

        Controls.ItemDelegate {
            Layout.fillWidth: true
            topPadding: Kirigami.Units.mediumSpacing
            bottomPadding: Kirigami.Units.mediumSpacing
            onClicked: faqRoot.expanded = !faqRoot.expanded

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    source: faqRoot.expanded ? "arrow-down" : "arrow-right"
                }

                Controls.Label {
                    Layout.fillWidth: true
                    text: faqRoot.question
                    font.bold: true
                    wrapMode: Text.Wrap
                }
            }
        }

        Controls.Label {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.leftMargin: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            visible: faqRoot.expanded
            text: faqRoot.answer
            wrapMode: Text.Wrap
            textFormat: Text.RichText
            color: Kirigami.Theme.disabledTextColor
            onLinkActivated: function(link) { Qt.openUrlExternally(link); }

            MouseArea {
                anchors.fill: parent
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                acceptedButtons: Qt.NoButton
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }
    }

    // ── FAQ Section ──

    Kirigami.Heading {
        Layout.fillWidth: true
        Layout.margins: Kirigami.Units.largeSpacing
        level: 2
        text: i18n("Frequently Asked Questions")
    }

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    FaqItem {
        question: i18n("My SMS won't send. What's wrong?")
        answer: i18n("Make sure the <b>SMS</b> plugin is enabled in KDE Connect settings for your paired device.")
    }

    FaqItem {
        question: i18n("The unread message indicator doesn't appear. Why?")
        answer: i18n("The indicator dot shows when you have unread SMS conversations on your phone. The <b>SMS</b> plugin must be enabled in KDE Connect settings. The indicator refreshes when you open the widget.")
    }

    FaqItem {
        question: i18n("No contacts appear when I type a name. How do I fix this?")
        answer: i18n("Your contacts must be synced to your local address book (KPeople). Enable the <b>Contacts</b> plugin in KDE Connect and click the sync button in the widget footer. Contacts from NextCloud, Google, or other synced sources also work.")
    }

    FaqItem {
        question: i18n("How do I reply to an incoming SMS?")
        answer: i18n("Use KDE's native notification popup — it appears when you receive a message and includes a reply field. You can also open the full conversation window by clicking the conversations button in the widget.")
    }

    FaqItem {
        question: i18n("Where can I report a bug or suggest a feature?")
        answer: i18n("For issues with this widget:") + "<br/><a href=\"https://github.com/comxd/plasma-kdeconnect-sms/issues\">github.com/comxd/plasma-kdeconnect-sms</a>"
            + "<br/><br/>" + i18n("For issues with KDE Connect itself:") + "<br/><a href=\"https://bugs.kde.org/\">bugs.kde.org</a>"
    }

    FaqItem {
        question: i18n("Where can I find more information about KDE Connect?")
        answer: "<a href=\"https://userbase.kde.org/KDEConnect\">" + i18n("KDE Connect Documentation") + "</a>"
            + "<br/><a href=\"https://store.kde.org/p/1202579/\">" + i18n("KDE Store Page") + "</a>"
    }

    FaqItem {
        question: i18n("How can I support this project?")
        answer: i18n("This plasmoid is developed and maintained on my free time. If you find it useful, you can support its development:") + "<br/><a href=\"https://buymeacoffee.com/comxd\">buymeacoffee.com/comxd</a>"
    }

    FaqItem {
        question: i18n("Can I use this widget on the desktop (not just the panel)?")
        answer: i18n("Yes! The widget works both in the panel and on the desktop. Right-click your desktop, select Add Widgets, and search for KDE Connect SMS.")
    }

    FaqItem {
        question: i18n("How do I switch between multiple phones?")
        answer: i18n("Use the device switcher button in the widget footer (next to the phone name). You can also change the default device in the widget settings.")
    }

    // ── Spacer ──

    Item { Layout.fillHeight: true }
    } // ColumnLayout
}
