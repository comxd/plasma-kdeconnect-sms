/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later

    KDE Connect SMS — Send SMS from your desktop via KDE Connect.
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

import org.kde.kdeconnect as KDEConnect
import org.kde.people as KPeople
import org.kde.kitemmodels as KItemModels

import "../code/helpers.js" as Helpers
import "../lib" as Lib

PlasmoidItem {
    id: root
    activationTogglesExpanded: true
    Plasmoid.icon: Qt.resolvedUrl("../icons/icon.svg")
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground | PlasmaCore.Types.ConfigurableBackground

    // ── Configuration helpers ──

    property string deviceId: plasmoid.configuration.defaultDeviceId
    property string deviceName: plasmoid.configuration.defaultDeviceName
    property string overrideCountry: ""
    property string activeCountry: overrideCountry.length > 0
        ? overrideCountry : plasmoid.configuration.defaultCountry
    property bool speakerBeep: plasmoid.configuration.speakerBeep
    property int speakerBeepReps: plasmoid.configuration.speakerBeepReps

    // ── KPeople role constants ──

    readonly property int kPeoplePhoneNumberRole: 260

    // ── Send state: "idle" | "sending" | "success" | "error" ──

    property string sendState: "idle"
    property string sendError: ""

    // ── SMS history (runtime-only, last 5) ──

    property var smsHistory: []
    property bool historyExpanded: true

    // ── Signal to clear message field after successful send ──

    signal clearAfterSend()

    // ── Contacts (KPeople) ──

    property bool contactsLoading: false

    // ── KDE Connect: device model (paired + reachable) ──

    KDEConnect.DevicesModel {
        id: devicesModel
        displayFilter: KDEConnect.DevicesModel.Paired | KDEConnect.DevicesModel.Reachable
    }

    // Bridge: read DevicesModel roles via delegate properties (data()/roleNames() not available in QML)
    Instantiator {
        id: devicesBridge
        model: devicesModel
        active: true
        delegate: QtObject {
            required property string deviceId
            required property string name
        }
        onCountChanged: root._autoSelectDevice()
    }

    // ── KDE Connect: device interface for current device ──

    property KDEConnect.DeviceDbusInterface currentDevice: null

    function _refreshDevice() {
        if (deviceId.length > 0) {
            currentDevice = KDEConnect.DeviceDbusInterfaceFactory.create(deviceId);
        } else {
            currentDevice = null;
        }
    }

    onDeviceIdChanged: _refreshDevice()

    // ── KDE Connect: SMS plugin availability ──
    // supportedPlugins is a D-Bus property (non-bindable, loaded async).
    // Check imperatively after device changes, with a delayed retry.

    property bool smsPluginAvailable: false

    function _checkSmsPlugin() {
        if (!currentDevice || deviceId.length === 0) {
            smsPluginAvailable = false;
            return;
        }
        var plugins = currentDevice.supportedPlugins;
        smsPluginAvailable = (plugins && plugins.indexOf("kdeconnect_sms") !== -1);
    }

    onCurrentDeviceChanged: {
        _checkSmsPlugin();
        smsPluginCheckTimer.restart();
    }

    property int _pluginCheckCount: 0

    Timer {
        id: smsPluginCheckTimer
        interval: 500
        repeat: true
        onTriggered: {
            root._pluginCheckCount++;
            root._checkSmsPlugin();
            if (root.smsPluginAvailable || root._pluginCheckCount >= 5)
                running = false;
        }
    }

    // (SMS sending handled via kdeconnect-cli — see sendSms())

    // ── KDE Connect: notifications model (for unread SMS badge) ──

    KDEConnect.NotificationsModel {
        id: notificationsModel
        deviceId: root.deviceId
    }

    readonly property int unreadCount: notificationsModel.count

    // ── Auto-select first device if none configured ──

    function _autoSelectDevice() {
        if (plasmoid.configuration.defaultDeviceId.length === 0 && devicesBridge.count > 0) {
            var first = devicesBridge.objectAt(0);
            if (first) {
                plasmoid.configuration.defaultDeviceId = first.deviceId;
                plasmoid.configuration.defaultDeviceName = first.name;
            }
        }
    }

    Component.onCompleted: _autoSelectDevice()


    // ── Compact representation ──

    compactRepresentation: MouseArea {
        onClicked: root.expanded = !root.expanded

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: parent.containsMouse
        }

        // ── Unread SMS badge ──
        Rectangle {
            visible: root.unreadCount > 0
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -Math.round(height / 4)
            anchors.rightMargin: -Math.round(width / 4)
            width: badgeLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
            height: badgeLabel.implicitHeight + Kirigami.Units.smallSpacing
            radius: height / 2
            color: Kirigami.Theme.highlightColor

            Controls.Label {
                id: badgeLabel
                anchors.centerIn: parent
                text: root.unreadCount > 99 ? "99+" : String(root.unreadCount)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.bold: true
                color: Kirigami.Theme.highlightedTextColor
            }
        }
    }

    // ── Full representation ──

    fullRepresentation: PlasmaExtras.Representation {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 12
            + (phoneInput._hasContact ? Kirigami.Units.gridUnit * 2 : 0)
        Layout.maximumHeight: Kirigami.Units.gridUnit * 28

        // Auto-focus phone field when popup opens
        Connections {
            target: root
            function onExpandedChanged() {
                if (root.expanded) {
                    root.overrideCountry = "";
                    if (root.deviceId.length > 0)
                        phoneInput.focusPhoneField();
                }
            }
        }

        // ── Footer toolbar ──

        footer: PlasmaExtras.PlasmoidHeading {
            visible: root.deviceId.length > 0
            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Controls.ToolButton {
                    icon.name: "view-refresh"
                    icon.width: Kirigami.Units.iconSizes.smallMedium
                    icon.height: Kirigami.Units.iconSizes.smallMedium
                    enabled: !root.contactsLoading
                    Controls.ToolTip.text: i18n("Sync contacts from phone")
                    Controls.ToolTip.visible: hovered
                    onClicked: root.syncContacts()
                }

                Controls.ToolButton {
                    icon.name: "dialog-messages"
                    icon.width: Kirigami.Units.iconSizes.smallMedium
                    icon.height: Kirigami.Units.iconSizes.smallMedium
                    visible: root.smsPluginAvailable
                    Controls.ToolTip.text: i18n("Open conversations")
                    Controls.ToolTip.visible: hovered
                    onClicked: utilityExecutor.run("kdeconnect-sms")

                    Rectangle {
                        visible: root.unreadCount > 0
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        width: Kirigami.Units.smallSpacing * 2
                        height: width
                        radius: width / 2
                        color: Kirigami.Theme.highlightColor
                    }
                }

                Controls.ToolButton {
                    id: deviceSwitcherButton
                    text: root.deviceName || i18n("No device")
                    icon.name: "smartphone"
                    icon.width: Kirigami.Units.iconSizes.smallMedium
                    icon.height: Kirigami.Units.iconSizes.smallMedium
                    visible: devicesModel.count > 0
                    Controls.ToolTip.text: devicesModel.count > 1
                        ? i18n("Switch device")
                        : root.deviceName
                    Controls.ToolTip.visible: hovered
                    onClicked: {
                        if (devicesModel.count > 1)
                            deviceMenu.popup(deviceSwitcherButton, 0, -deviceMenu.height);
                    }

                    Kirigami.Icon {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        width: Kirigami.Units.iconSizes.small / 2
                        height: width
                        source: "arrow-down"
                        visible: devicesModel.count > 1
                    }
                }

                Item { Layout.fillWidth: true }

                Controls.ToolButton {
                    icon.name: "document-new"
                    icon.width: Kirigami.Units.iconSizes.smallMedium
                    icon.height: Kirigami.Units.iconSizes.smallMedium
                    visible: phoneInput.phoneText.length > 0 || messageInput.messageText.length > 0
                    Controls.ToolTip.text: i18n("New SMS")
                    Controls.ToolTip.visible: hovered
                    onClicked: {
                        phoneInput.clear();
                        messageInput.clear();
                        root.sendState = "idle";
                        root.overrideCountry = "";
                    }
                }

                Controls.BusyIndicator {
                    visible: root.sendState === "sending" || root.contactsLoading
                    running: visible
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }

                Controls.Button {
                    id: sendButton
                    icon.name: "mail-send"
                    icon.width: Kirigami.Units.iconSizes.smallMedium
                    icon.height: Kirigami.Units.iconSizes.smallMedium
                    text: i18n("Send SMS")
                    enabled: root.sendState !== "sending"
                             && root.smsPluginAvailable
                             && phoneInput.isPhoneValid
                             && messageInput.messageText.length > 0

                    onClicked: root.sendSms(
                        phoneInput.formatE164(),
                        phoneInput.phoneText,
                        phoneInput.selectedContactName,
                        messageInput.messageText
                    )
                }
            }
        }

        // ── Main content ──

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            // ── Onboarding: no device configured ──

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.deviceId.length === 0
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
                    text: devicesModel.count === 0
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
                    text: devicesModel.count === 0
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

            // ── SMS plugin not available warning ──

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.deviceId.length > 0 && !root.smsPluginAvailable
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
                            onTriggered: utilityExecutor.run("kdeconnect-settings")
                        }
                    ]
                }

                Item { Layout.fillHeight: true }
            }

            // ── SMS form with drag & drop file sharing ──

            Item {
                id: smsFormContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.deviceId.length > 0 && root.smsPluginAvailable

                ColumnLayout {
                    id: smsFormColumn
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    PhoneInput {
                        id: phoneInput
                        Layout.fillWidth: true
                        activeCountry: root.activeCountry
                        sendState: root.sendState
                        contactSearchModel: contactSearchProxy

                        onCountryBadgeClicked: countryPicker.open()

                        onPhoneTextChanged: {
                            if (root.sendState === "success" || root.sendState === "error")
                                root.sendState = "idle";
                        }
                    }

                    MessageInput {
                        id: messageInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        sendState: root.sendState

                        onTextEdited: {
                            if (root.sendState === "success" || root.sendState === "error")
                                root.sendState = "idle";
                        }
                    }
                }

                // ── DropArea overlay for file sharing ──

                DropArea {
                    id: fileDropArea
                    anchors.fill: parent

                    onDropped: function(drop) {
                        if (drop.hasUrls) {
                            for (var i = 0; i < drop.urls.length; i++) {
                                var urlStr = drop.urls[i].toString();
                                if (urlStr.indexOf("file://") !== 0)
                                    continue;
                                var filePath = urlStr.substring(7);
                                root.shareFile(filePath);
                            }
                            drop.accept();
                        }
                    }
                }

                // Drag indicator overlay (dashed border + icon + label)
                Rectangle {
                    id: dropIndicator
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    visible: fileDropArea.containsDrag
                    color: Qt.rgba(
                        Kirigami.Theme.highlightColor.r,
                        Kirigami.Theme.highlightColor.g,
                        Kirigami.Theme.highlightColor.b, 0.1)
                    radius: Kirigami.Units.cornerRadius
                    border.color: Kirigami.Theme.highlightColor
                    border.width: 2

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: Kirigami.Units.iconSizes.large
                            Layout.preferredHeight: Kirigami.Units.iconSizes.large
                            source: "document-share"
                        }

                        Controls.Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: i18n("Drop files to share with %1", root.deviceName)
                            color: Kirigami.Theme.highlightColor
                            font.bold: true
                        }
                    }
                }

                Controls.ToolTip {
                    parent: smsFormContainer
                    visible: fileDropArea.containsDrag
                    text: i18n("Drop files here to share them via KDE Connect")
                    delay: 0
                }
            }

            Controls.Label {
                id: statusLabel
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: Kirigami.Theme.smallFont.pointSize

                property bool shouldShow: root.sendState !== "idle" && root.deviceId.length > 0

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
                    if (root.sendState === "success")
                        return Kirigami.Theme.positiveTextColor;
                    if (root.sendState === "error")
                        return Kirigami.Theme.negativeTextColor;
                    return Kirigami.Theme.textColor;
                }
                text: {
                    if (root.sendState === "sending")
                        return i18n("Sending...");
                    if (root.sendState === "success")
                        return i18n("SMS sent successfully");
                    if (root.sendState === "error")
                        return root.sendError || i18n("Failed to send SMS");
                    return "";
                }
            }

            // ── SMS history (collapsible) ──

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.deviceId.length > 0 && root.smsHistory.length > 0
                spacing: 0

                // Collapsible header
                Controls.ItemDelegate {
                    Layout.fillWidth: true
                    padding: Kirigami.Units.smallSpacing
                    onClicked: root.historyExpanded = !root.historyExpanded

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            source: "arrow-down"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            color: Kirigami.Theme.textColor

                            rotation: root.historyExpanded ? 0 : -90

                            Behavior on rotation {
                                NumberAnimation {
                                    duration: Kirigami.Units.shortDuration
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }

                        Controls.Label {
                            text: i18n("SMS History")
                            Layout.fillWidth: true
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.disabledTextColor
                        }
                    }
                }

                // Animated collapsible container
                Item {
                    id: historyContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.historyExpanded ? smsHistoryContent.implicitHeight : 0
                    clip: true

                    Behavior on Layout.preferredHeight {
                        NumberAnimation {
                            duration: Kirigami.Units.shortDuration
                            easing.type: Easing.InOutQuad
                        }
                    }

                    SmsHistory {
                        id: smsHistoryContent
                        width: parent.width
                        historyModel: root.smsHistory

                        onEntryClicked: function(phoneNumber, contactName) {
                            phoneInput.setPhone(phoneNumber, contactName);
                            root.sendState = "idle";
                        }
                        onEntryDismissed: function(index) {
                            var arr = root.smsHistory.slice();
                            arr.splice(index, 1);
                            root.smsHistory = arr;
                        }
                        onClearRequested: {
                            root.smsHistory = [];
                        }
                    }
                }
            }

            // ── File share status ──

            Controls.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                visible: root.fileShareState !== "idle"
                color: root.fileShareState === "success"
                    ? Kirigami.Theme.positiveTextColor
                    : root.fileShareState === "error"
                        ? Kirigami.Theme.negativeTextColor
                        : Kirigami.Theme.textColor
                text: {
                    if (root.fileShareState === "sharing")
                        return i18n("Sharing file...");
                    if (root.fileShareState === "success")
                        return i18n("File shared successfully");
                    if (root.fileShareState === "error")
                        return root.fileShareError || i18n("Failed to share file");
                    return "";
                }
            }

            // ── Notification reply section ──

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.deviceId.length > 0 && root.unreadCount > 0
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Separator {
                    Layout.fillWidth: true
                }

                Repeater {
                    model: notificationsModel

                    delegate: ColumnLayout {
                        id: notifDelegate
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        required property int index
                        required property var model

                        property bool replying: false

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                source: notifDelegate.model.appIcon || "mail-message"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Controls.Label {
                                    Layout.fillWidth: true
                                    text: notifDelegate.model.appName || i18n("Notification")
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Controls.Label {
                                    Layout.fillWidth: true
                                    text: {
                                        var title = notifDelegate.model.title || "";
                                        var notitext = notifDelegate.model.notitext || "";
                                        if (title.length > 0 && title !== notifDelegate.model.appName)
                                            return title + ": " + notitext;
                                        return notitext;
                                    }
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    elide: Text.ElideRight
                                    color: Kirigami.Theme.disabledTextColor
                                }
                            }

                            Controls.ToolButton {
                                id: notifReplyButton
                                icon.name: "mail-reply-sender"
                                icon.width: Kirigami.Units.iconSizes.smallMedium
                                icon.height: Kirigami.Units.iconSizes.smallMedium
                                visible: notifDelegate.model.repliable
                                enabled: notifDelegate.model.repliable && !notifDelegate.replying
                                Controls.ToolTip.text: i18n("Reply")
                                Controls.ToolTip.visible: hovered
                                onClicked: {
                                    notifDelegate.replying = true;
                                    replyTextField.forceActiveFocus();
                                }
                            }

                            Controls.ToolButton {
                                icon.name: "window-close"
                                icon.width: Kirigami.Units.iconSizes.smallMedium
                                icon.height: Kirigami.Units.iconSizes.smallMedium
                                visible: notifDelegate.model.dismissable
                                Controls.ToolTip.text: i18n("Dismiss")
                                Controls.ToolTip.visible: hovered
                                onClicked: notifDelegate.model.dbusInterface.dismiss()
                            }
                        }

                        // Inline reply area
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Kirigami.Units.largeSpacing
                            visible: notifDelegate.replying
                            spacing: Kirigami.Units.smallSpacing

                            Controls.ToolButton {
                                id: replyCancelButton
                                Layout.alignment: Qt.AlignBottom
                                icon.name: "dialog-cancel"
                                icon.width: Kirigami.Units.iconSizes.smallMedium
                                icon.height: Kirigami.Units.iconSizes.smallMedium
                                Controls.ToolTip.text: i18n("Cancel")
                                Controls.ToolTip.visible: hovered
                                onClicked: {
                                    replyTextField.text = "";
                                    notifDelegate.replying = false;
                                }
                            }

                            Controls.TextArea {
                                id: replyTextField
                                Layout.fillWidth: true
                                placeholderText: i18n("Reply to %1...", notifDelegate.model.appName || i18n("Notification"))
                                wrapMode: TextEdit.Wrap
                                Keys.onPressed: function(event) {
                                    if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                            && !(event.modifiers & Qt.ShiftModifier)) {
                                        replySendButton.clicked();
                                        event.accepted = true;
                                    }
                                    if (event.key === Qt.Key_Escape) {
                                        replyCancelButton.clicked();
                                        event.accepted = true;
                                    }
                                }
                            }

                            Controls.ToolButton {
                                id: replySendButton
                                Layout.alignment: Qt.AlignBottom
                                icon.name: "document-send"
                                icon.width: Kirigami.Units.iconSizes.smallMedium
                                icon.height: Kirigami.Units.iconSizes.smallMedium
                                Controls.ToolTip.text: i18n("Send")
                                Controls.ToolTip.visible: hovered
                                enabled: replyTextField.text.length > 0
                                onClicked: {
                                    notifDelegate.model.dbusInterface.sendReply(replyTextField.text);
                                    replyTextField.text = "";
                                    notifDelegate.replying = false;
                                }
                            }
                        }

                        Kirigami.Separator {
                            Layout.fillWidth: true
                            visible: notifDelegate.index < notificationsModel.count - 1
                            opacity: 0.5
                        }
                    }
                }
            }

            // ── Country picker popup ──

            CountryPicker {
                id: countryPicker
                activeCountry: root.activeCountry
                onCountrySelected: function(code) {
                    root.overrideCountry = code;
                }
            }

            // ── Clear message field after successful send ──

            Connections {
                target: root
                function onClearAfterSend() { messageInput.clear(); }
            }
            }
    }

    // ── Send SMS via kdeconnect-cli ──

    property string _pendingPhone: ""
    property string _pendingContact: ""
    property string _pendingMessage: ""

    Lib.ExecuteCommand {
        id: smsExecutor
        onFinished: function(exitCode, stdout, stderr) {
            if (exitCode === 0) {
                root.sendState = "success";

                var preview = root._pendingMessage;
                if (preview.length > 30)
                    preview = preview.substring(0, 30) + "…";
                var entry = {
                    phoneNumber: root._pendingPhone,
                    contactName: root._pendingContact,
                    messagePreview: preview,
                    timestamp: Date.now()
                };
                root.smsHistory = [entry].concat(root.smsHistory).slice(0, 5);

                if (root.speakerBeep)
                    playBeep();
            } else {
                root.sendState = "error";
                root.sendError = stderr || i18n("Failed to send SMS");
            }
            statusResetTimer.restart();
        }
    }

    function sendSms(e164Phone, rawPhone, contactName, message) {
        root.sendState = "sending";
        root.sendError = "";

        root._pendingPhone = rawPhone;
        root._pendingContact = contactName;
        root._pendingMessage = message;

        var cmd = "kdeconnect-cli --send-sms " + Helpers.shellEscape(message)
                + " --destination " + Helpers.shellEscape(e164Phone)
                + " -d " + Helpers.shellEscape(root.deviceId);
        smsExecutor.run(cmd);
    }

    // ── Status reset timer ──

    Timer {
        id: statusResetTimer
        interval: 5000
        onTriggered: {
            if (root.sendState === "success") {
                root.clearAfterSend();
                root.sendState = "idle";
            } else if (root.sendState === "error") {
                root.sendState = "idle";
            }
        }
    }

    // ── Beep sound (still uses shell command) ──

    property int _beepCount: 0
    property int _beepPlayed: 0

    function playBeep() {
        _beepCount = root.speakerBeepReps;
        _beepPlayed = 0;
        if (_beepCount > 0)
            beepExecutor.run("paplay /usr/share/sounds/freedesktop/stereo/complete.oga");
    }

    Lib.ExecuteCommand {
        id: beepExecutor
    }

    // ── Utility command executor (open settings, etc.) ──

    Lib.ExecuteCommand {
        id: utilityExecutor
    }

    // ── File sharing via kdeconnect-cli --share ──

    property string fileShareState: "idle"
    property string fileShareError: ""
    property string _pendingShareFile: ""

    function shareFile(filePath) {
        if (root.deviceId.length === 0)
            return;
        root._pendingShareFile = filePath;
        root.fileShareState = "sharing";
        root.fileShareError = "";
        var cmd = "kdeconnect-cli --share " + Helpers.shellEscape(filePath)
                + " -d " + Helpers.shellEscape(root.deviceId);
        fileShareExecutor.run(cmd);
    }

    Lib.ExecuteCommand {
        id: fileShareExecutor
        onFinished: function(exitCode, stdout, stderr) {
            if (exitCode === 0) {
                root.fileShareState = "success";
            } else {
                root.fileShareState = "error";
                root.fileShareError = stderr || i18n("Failed to share file");
            }
            fileShareResetTimer.restart();
        }
    }

    Timer {
        id: fileShareResetTimer
        interval: 3000
        onTriggered: {
            root.fileShareState = "idle";
            root.fileShareError = "";
        }
    }

    Connections {
        target: beepExecutor
        function onFinished() {
            root._beepPlayed++;
            if (root._beepPlayed < root._beepCount)
                beepExecutor.run("paplay /usr/share/sounds/freedesktop/stereo/complete.oga");
        }
    }

    // ── Contacts: KPeople model chain ──
    // PersonsModel → PersonsSortFilterProxyModel (phones only) → KSortFilterProxyModel (user search)

    KPeople.PersonsModel {
        id: personsModel
    }

    KPeople.PersonsSortFilterProxyModel {
        id: contactsWithPhones
        sourceModel: personsModel
        requiredProperties: ["phoneNumber"]
        Component.onCompleted: sort(0)
    }

    KItemModels.KSortFilterProxyModel {
        id: contactSearchProxy
        sourceModel: contactsWithPhones
        filterRoleName: "display"

        filterRowCallback: function(sourceRow, sourceParent) {
            if (filterString.length < 2)
                return false;
            var q = filterString.toLowerCase();
            var name = sourceModel.data(
                sourceModel.index(sourceRow, 0, sourceParent), 0 /* Qt::DisplayRole */);
            if (name && name.toString().toLowerCase().indexOf(q) !== -1)
                return true;
            var phone = sourceModel.data(
                sourceModel.index(sourceRow, 0, sourceParent), root.kPeoplePhoneNumberRole);
            if (phone && phone.toString().replace(/[\s\-()]/g, "").indexOf(
                    q.replace(/[\s\-()]/g, "")) !== -1)
                return true;
            return false;
        }
    }

    // ── Contacts sync (D-Bus trigger — no native QML API available) ──

    function syncContacts() {
        var cmd = Helpers.buildSyncContactsCommand(root.deviceId);
        if (cmd) {
            root.contactsLoading = true;
            contactSyncExecutor.run(cmd);
        }
    }

    Lib.ExecuteCommand {
        id: contactSyncExecutor
        onFinished: function(exitCode, stdout, stderr) {
            root.contactsLoading = false;
        }
    }

    // ── Device switcher menu ──

    Controls.Menu {
        id: deviceMenu

        Instantiator {
            model: devicesModel
            delegate: Controls.MenuItem {
                text: model.name
                checkable: true
                checked: model.deviceId === root.deviceId
                onTriggered: {
                    plasmoid.configuration.defaultDeviceId = model.deviceId;
                    plasmoid.configuration.defaultDeviceName = model.name;
                }
            }
            onObjectAdded: function(index, object) { deviceMenu.insertItem(index, object); }
            onObjectRemoved: function(index, object) { deviceMenu.removeItem(object); }
        }
    }
}
