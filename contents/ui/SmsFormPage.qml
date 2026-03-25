/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later

    SMS form page: onboarding, plugin warning, phone/message inputs, status label.
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: smsFormPage
    spacing: Kirigami.Units.smallSpacing

    // ── Required properties ──

    required property string deviceId
    required property int deviceCount
    required property bool smsPluginAvailable
    required property bool pluginChecking
    required property string sendState
    required property string sendError
    required property int historyCount
    required property string activeCountry
    required property var contactSearchModel

    // ── Exposed child components ──

    property alias phoneInput: phoneInput
    property alias messageInput: messageInput

    // ── Signals ──

    signal countryBadgeClicked()
    signal phoneEdited()
    signal textEdited()
    signal historyPageRequested()
    signal openKdeConnect()

    // ── Onboarding: no device configured ──

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: smsFormPage.deviceId.length === 0
        spacing: Kirigami.Units.largeSpacing

        Item { Layout.fillHeight: true }

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
            source: "smartphone"
            opacity: 0.5
        }

        Controls.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: smsFormPage.deviceCount === 0
                ? i18n("No device available")
                : i18n("No device configured")
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
        }

        Controls.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: Kirigami.Theme.disabledTextColor
            text: smsFormPage.deviceCount === 0
                ? i18n("Pair and connect your phone with KDE Connect to start sending SMS.")
                : i18n("Select a device in the widget settings to start sending SMS.")
        }

        Controls.Button {
            Layout.alignment: Qt.AlignHCenter
            icon.name: "configure"
            icon.width: Kirigami.Units.iconSizes.smallMedium
            icon.height: Kirigami.Units.iconSizes.smallMedium
            text: i18n("Open Settings")
            onClicked: plasmoid.internalAction("configure").trigger()
        }

        Item { Layout.fillHeight: true }
    }

    // ── SMS plugin check in progress ──

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: smsFormPage.deviceId.length > 0 && smsFormPage.pluginChecking && !smsFormPage.smsPluginAvailable

        Controls.BusyIndicator {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.large
            height: Kirigami.Units.iconSizes.large
            running: visible
        }
    }

    // ── SMS plugin not available warning ──

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: smsFormPage.deviceId.length > 0 && !smsFormPage.smsPluginAvailable && !smsFormPage.pluginChecking
        spacing: Kirigami.Units.largeSpacing

        Item { Layout.fillHeight: true }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Warning
            text: i18n("SMS plugin is not available on this device. Make sure the device is reachable and the SMS plugin is enabled in KDE Connect settings.")
            visible: true

            actions: [
                Kirigami.Action {
                    text: i18n("Open KDE Connect")
                    icon.name: "kdeconnect"
                    onTriggered: smsFormPage.openKdeConnect()
                }
            ]
        }

        Item { Layout.fillHeight: true }
    }

    // ── SMS form ──

    PhoneInput {
        id: phoneInput
        Layout.fillWidth: true
        visible: smsFormPage.deviceId.length > 0 && smsFormPage.smsPluginAvailable
        activeCountry: smsFormPage.activeCountry
        sendState: smsFormPage.sendState
        contactSearchModel: smsFormPage.contactSearchModel

        onCountryBadgeClicked: smsFormPage.countryBadgeClicked()
        onPhoneTextChanged: smsFormPage.phoneEdited()
    }

    MessageInput {
        id: messageInput
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: smsFormPage.deviceId.length > 0 && smsFormPage.smsPluginAvailable
        sendState: smsFormPage.sendState

        onTextEdited: smsFormPage.textEdited()
    }

    // ── Status label ──

    Controls.Label {
        id: statusLabel
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: Kirigami.Theme.smallFont.pointSize

        property bool shouldShow: smsFormPage.sendState !== "idle" && smsFormPage.deviceId.length > 0

        onShouldShowChanged: {
            if (shouldShow) {
                visible = true;
                opacity = 1;
            } else {
                opacity = 0;
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                onRunningChanged: {
                    if (!running && statusLabel.opacity === 0)
                        statusLabel.visible = false;
                }
            }
        }
        color: {
            if (smsFormPage.sendState === "success")
                return Kirigami.Theme.positiveTextColor;
            if (smsFormPage.sendState === "error")
                return Kirigami.Theme.negativeTextColor;
            return Kirigami.Theme.textColor;
        }
        text: {
            if (smsFormPage.sendState === "sending")
                return i18n("Sending...");
            if (smsFormPage.sendState === "success")
                return i18n("SMS sent successfully");
            if (smsFormPage.sendState === "error")
                return smsFormPage.sendError || i18n("Failed to send SMS");
            return "";
        }
    }

    // ── SMS history navigation ──

    Controls.ItemDelegate {
        Layout.fillWidth: true
        visible: smsFormPage.deviceId.length > 0 && smsFormPage.historyCount > 0
        padding: Kirigami.Units.smallSpacing
        onClicked: smsFormPage.historyPageRequested()

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "mail-sent"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                color: Kirigami.Theme.disabledTextColor
            }

            Controls.Label {
                text: i18np("SMS History (%1)", "SMS History (%1)", smsFormPage.historyCount)
                Layout.fillWidth: true
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                color: Kirigami.Theme.disabledTextColor
            }

            Kirigami.Icon {
                source: mirrored ? "go-previous" : "go-next"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                color: Kirigami.Theme.disabledTextColor
            }
        }
    }
}
