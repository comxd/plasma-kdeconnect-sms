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

    onDeviceIdChanged: {
        _refreshDevice();
        if (deviceId.length > 0) {
            syncConversationThreads();
            refreshUnreadCount();
        }
    }

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

    // ── Unread SMS count (via D-Bus conversations API) ──

    property int unreadCount: 0

    Lib.ExecuteCommand {
        id: unreadExecutor
        onFinished: function(exitCode, stdout, stderr) {
            if (exitCode === 0)
                root.unreadCount = Helpers.countUnreadSms(stdout);
        }
    }

    function refreshUnreadCount() {
        if (root.deviceId.length === 0) return;
        var cmd = Helpers.buildActiveConversationsCommand(root.deviceId);
        if (cmd) unreadExecutor.run(cmd);
    }

    Lib.ExecuteCommand {
        id: conversationSyncExecutor
        onFinished: function(exitCode, stdout, stderr) {
            unreadRefreshDelay.start();
        }
    }

    function syncConversationThreads() {
        if (root.deviceId.length === 0) return;
        var cmd = Helpers.buildRequestConversationThreadsCommand(root.deviceId);
        if (cmd) conversationSyncExecutor.run(cmd);
    }

    Timer {
        id: unreadRefreshDelay
        interval: 3000
        repeat: false
        onTriggered: root.refreshUnreadCount()
    }

    Timer {
        id: unreadPollTimer
        interval: 60000
        running: root.deviceId.length > 0
        repeat: true
        onTriggered: root.refreshUnreadCount()
    }

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

    Component.onCompleted: {
        _autoSelectDevice();
        updatePlasmoidStatus();
        hideWidgetAction.checked = plasmoid.configuration.hideWidget;
        if (deviceId.length > 0) {
            syncConversationThreads();
            refreshUnreadCount();
        }
    }


    // ── Compact representation ──

    compactRepresentation: Item {

        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded

            Kirigami.Icon {
                anchors.fill: parent
                source: Plasmoid.icon
                active: parent.containsMouse
            }
        }

        // ── Unread SMS badge ──
        Rectangle {
            visible: root.unreadCount > 0
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -Math.round(height / 4)
            anchors.rightMargin: -Math.round(width / 4)
            width: Math.max(badgeLabel.implicitWidth + Kirigami.Units.smallSpacing * 2, height)
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
        id: fullRep

        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 12
            + (phoneInput._hasContact ? Kirigami.Units.gridUnit * 2 : 0)
        Layout.maximumHeight: Kirigami.Units.gridUnit * 28

        // ── Page navigation: 0 = SMS form, 1 = Country picker, 2 = About ──
        property int currentPage: 0

        // Auto-focus phone field when popup opens; reset to form page
        Connections {
            target: root
            function onExpandedChanged() {
                if (root.expanded) {
                    root.refreshUnreadCount();
                    if (root._pendingPage >= 0) {
                        fullRep.currentPage = root._pendingPage;
                        // Don't reset _pendingPage here — the popup may toggle
                        // (close/open) from context menu. Let the 2s timer reset it.
                    } else {
                        fullRep.currentPage = 0;
                        root.overrideCountry = "";
                        if (root.deviceId.length > 0)
                            phoneInput.focusPhoneField();
                    }
                }
            }
        }

        // ── Footer toolbar ──

        footer: PlasmaExtras.PlasmoidHeading {
            visible: root.deviceId.length > 0 && fullRep.currentPage === 0
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
                        anchors.topMargin: -Math.round(height / 4)
                        anchors.rightMargin: -Math.round(width / 4)
                        width: Math.max(conversationBadgeLabel.implicitWidth + Kirigami.Units.smallSpacing * 2, height)
                        height: conversationBadgeLabel.implicitHeight + Kirigami.Units.smallSpacing
                        radius: height / 2
                        color: Kirigami.Theme.highlightColor

                        Controls.Label {
                            id: conversationBadgeLabel
                            anchors.centerIn: parent
                            text: root.unreadCount > 99 ? "99+" : String(root.unreadCount)
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            font.bold: true
                            color: Kirigami.Theme.highlightedTextColor
                        }
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

        // ── Main content (StackLayout: page 0 = form, page 1 = country picker, page 2 = about) ──

        StackLayout {
            id: pageStack
            anchors.fill: parent
            currentIndex: fullRep.currentPage

        // ── Page 0: SMS form ──

        ColumnLayout {
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

            // ── SMS form ──

            PhoneInput {
                id: phoneInput
                Layout.fillWidth: true
                visible: root.deviceId.length > 0 && root.smsPluginAvailable
                activeCountry: root.activeCountry
                sendState: root.sendState
                contactSearchModel: contactSearchProxy

                onCountryBadgeClicked: {
                    fullRep.currentPage = 1;
                    countryPicker.activate();
                }

                onPhoneTextChanged: {
                    if (root.sendState === "success" || root.sendState === "error")
                        root.sendState = "idle";
                }
            }

            MessageInput {
                id: messageInput
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.deviceId.length > 0 && root.smsPluginAvailable
                sendState: root.sendState

                onTextEdited: {
                    if (root.sendState === "success" || root.sendState === "error")
                        root.sendState = "idle";
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

            // ── Clear message field after successful send ──

            Connections {
                target: root
                function onClearAfterSend() { messageInput.clear(); }
            }
        }

        // ── Page 1: Country picker (inline view) ──

        CountryPicker {
            id: countryPicker
            activeCountry: root.activeCountry
            onCountrySelected: function(code) {
                root.overrideCountry = code;
                fullRep.currentPage = 0;
            }
            onBackRequested: fullRep.currentPage = 0
        }

        // ── Page 2: About ──

        AboutTab {
            id: aboutTab
            onBackRequested: fullRep.currentPage = 0
        }

        } // StackLayout
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
                unreadRefreshDelay.start();
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

    // ── Hide widget from panel ──

    property bool editMode: {
        if (Plasmoid.containment && Plasmoid.containment.corona) {
            return Plasmoid.containment.corona.editMode;
        }
        return false;
    }
    property bool hideWidget: plasmoid.configuration.hideWidget

    function updatePlasmoidStatus() {
        Plasmoid.status = (editMode || !hideWidget)
            ? PlasmaCore.Types.ActiveStatus
            : PlasmaCore.Types.HiddenStatus;
    }

    onEditModeChanged: updatePlasmoidStatus()
    onHideWidgetChanged: updatePlasmoidStatus()

    property PlasmaCore.Action hideWidgetAction: PlasmaCore.Action {
        text: i18n("Hide widget from panel")
        icon.name: "visibility-symbolic"
        checkable: true
        onTriggered: {
            plasmoid.configuration.hideWidget = !plasmoid.configuration.hideWidget;
            plasmoid.configuration.writeConfig();
        }
    }

    Connections {
        target: plasmoid.configuration
        function onHideWidgetChanged() {
            hideWidgetAction.checked = plasmoid.configuration.hideWidget;
        }
    }

    // ── About page request (cross-scope: root → fullRep) ──

    property int _pendingPage: -1

    // Delay popup open to let the context menu close first (avoids toggle)
    Timer {
        id: aboutOpenTimer
        interval: 200
        onTriggered: root.expanded = true
    }

    // Clear pending page after 2s safety net
    Timer {
        id: pendingPageTimeout
        interval: 2000
        onTriggered: root._pendingPage = -1
    }

    property PlasmaCore.Action aboutAction: PlasmaCore.Action {
        text: i18n("About KDE Connect SMS")
        icon.name: "help-about"
        onTriggered: {
            root.expanded = false;
            root._pendingPage = 2;
            pendingPageTimeout.restart();
            aboutOpenTimer.restart();
        }
    }

    property PlasmaCore.Action settingsAction: PlasmaCore.Action {
        text: i18n("Help && FAQ")
        icon.name: "help-contents"
        onTriggered: Plasmoid.internalAction("configure").trigger()
    }

    Plasmoid.contextualActions: [aboutAction, settingsAction, hideWidgetAction]

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
