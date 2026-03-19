/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later

    Footer toolbar: sync contacts, open conversations, device switcher, new SMS, send button.
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

PlasmaExtras.PlasmoidHeading {
    id: toolbar

    // ── Required properties ──

    required property int unreadCount
    required property string sendState
    required property bool contactsLoading
    required property bool smsPluginAvailable
    required property string deviceName
    required property int deviceCount
    required property string phoneText
    required property bool isPhoneValid
    required property string messageText

    // ── Signals ──

    signal syncContacts()
    signal openConversations()
    signal newSms()
    signal sendSms()
    signal deviceMenuRequested(var anchor)

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Controls.ToolButton {
            icon.name: "view-refresh"
            icon.width: Kirigami.Units.iconSizes.smallMedium
            icon.height: Kirigami.Units.iconSizes.smallMedium
            enabled: !toolbar.contactsLoading
            Controls.ToolTip.text: i18n("Sync contacts from phone")
            Controls.ToolTip.visible: hovered
            onClicked: toolbar.syncContacts()
        }

        Controls.ToolButton {
            icon.name: "dialog-messages"
            icon.width: Kirigami.Units.iconSizes.smallMedium
            icon.height: Kirigami.Units.iconSizes.smallMedium
            visible: toolbar.smsPluginAvailable
            Controls.ToolTip.text: i18n("Open conversations")
            Controls.ToolTip.visible: hovered
            onClicked: toolbar.openConversations()

            Rectangle {
                visible: toolbar.unreadCount > 0
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: -Math.round(height / 4)
                anchors.rightMargin: -Math.round(width / 4)
                width: Math.max(conversationBadgeLabel.implicitWidth + Kirigami.Units.smallSpacing * 2, height)
                height: conversationBadgeLabel.implicitHeight + Kirigami.Units.smallSpacing
                radius: height / 2
                color: Kirigami.Theme.highlightColor

                Controls.Label {
                    id: conversationBadgeLabel
                    anchors.centerIn: parent
                    text: toolbar.unreadCount > 99 ? "99+" : String(toolbar.unreadCount)
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.bold: true
                    color: Kirigami.Theme.highlightedTextColor
                }
            }
        }

        Controls.ToolButton {
            id: deviceSwitcherButton
            text: toolbar.deviceName || i18n("No device")
            icon.name: "smartphone"
            icon.width: Kirigami.Units.iconSizes.smallMedium
            icon.height: Kirigami.Units.iconSizes.smallMedium
            visible: toolbar.deviceCount > 0
            Controls.ToolTip.text: toolbar.deviceCount > 1
                ? i18n("Switch device")
                : toolbar.deviceName
            Controls.ToolTip.visible: hovered
            onClicked: {
                if (toolbar.deviceCount > 1)
                    toolbar.deviceMenuRequested(deviceSwitcherButton);
            }

            Kirigami.Icon {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: Kirigami.Units.smallSpacing
                width: Kirigami.Units.iconSizes.small / 2
                height: width
                source: "arrow-down"
                visible: toolbar.deviceCount > 1
            }
        }

        Item { Layout.fillWidth: true }

        Controls.ToolButton {
            icon.name: "document-new"
            icon.width: Kirigami.Units.iconSizes.smallMedium
            icon.height: Kirigami.Units.iconSizes.smallMedium
            visible: toolbar.phoneText.length > 0 || toolbar.messageText.length > 0
            Controls.ToolTip.text: i18n("New SMS")
            Controls.ToolTip.visible: hovered
            onClicked: toolbar.newSms()
        }

        Controls.BusyIndicator {
            visible: toolbar.sendState === "sending" || toolbar.contactsLoading
            running: visible
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
        }

        Controls.Button {
            icon.name: "mail-send"
            icon.width: Kirigami.Units.iconSizes.smallMedium
            icon.height: Kirigami.Units.iconSizes.smallMedium
            text: i18n("Send SMS")
            enabled: toolbar.sendState !== "sending"
                     && toolbar.smsPluginAvailable
                     && toolbar.isPhoneValid
                     && toolbar.messageText.length > 0
            onClicked: toolbar.sendSms()
        }
    }
}
