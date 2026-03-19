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

    // ── SMS history (runtime-only, last 5) ──

    property var smsHistory: []

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

    compactRepresentation: CompactIcon {
        unreadCount: root.unreadCount
        onClicked: root.expanded = !root.expanded
    }

    // ── Full representation ──

    fullRepresentation: PlasmaExtras.Representation {
        id: fullRep

        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 12
            + (smsFormPage.phoneInput._hasContact ? Kirigami.Units.gridUnit * 2 : 0)
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
                            smsFormPage.phoneInput.focusPhoneField();
                    }
                }
            }
            function onClearAfterSend() {
                smsFormPage.messageInput.clear();
            }
        }

        // ── Footer toolbar ──

        footer: SmsFormToolbar {
            visible: root.deviceId.length > 0 && fullRep.currentPage === 0
            unreadCount: root.unreadCount
            sendState: smsSender.sendState
            contactsLoading: root.contactsLoading
            smsPluginAvailable: root.smsPluginAvailable
            deviceName: root.deviceName
            deviceCount: devicesModel.count
            phoneText: smsFormPage.phoneInput.phoneText
            isPhoneValid: smsFormPage.phoneInput.isPhoneValid
            messageText: smsFormPage.messageInput.messageText

            onSyncContacts: root.syncContacts()
            onOpenConversations: utilityExecutor.run("kdeconnect-sms")
            onDeviceMenuRequested: function(anchor) {
                deviceMenu.popup(anchor, 0, -deviceMenu.height);
            }
            onNewSms: {
                smsFormPage.phoneInput.clear();
                smsFormPage.messageInput.clear();
                smsSender.reset();
                root.overrideCountry = "";
            }
            onSendSms: smsSender.send(
                smsFormPage.phoneInput.formatE164(),
                smsFormPage.phoneInput.phoneText,
                smsFormPage.phoneInput.selectedContactName,
                smsFormPage.messageInput.messageText
            )
        }

        // ── Main content (StackLayout: page 0 = form, page 1 = country picker, page 2 = about) ──

        StackLayout {
            id: pageStack
            anchors.fill: parent
            currentIndex: fullRep.currentPage

        // ── Page 0: SMS form ──

        SmsFormPage {
            id: smsFormPage
            deviceId: root.deviceId
            deviceCount: devicesModel.count
            smsPluginAvailable: root.smsPluginAvailable
            sendState: smsSender.sendState
            sendError: smsSender.sendError
            smsHistory: root.smsHistory
            activeCountry: root.activeCountry
            contactSearchModel: contactSearchProxy

            onCountryBadgeClicked: {
                fullRep.currentPage = 1;
                countryPicker.activate();
            }
            onPhoneEdited: {
                if (smsSender.sendState === "success" || smsSender.sendState === "error")
                    smsSender.reset();
            }
            onTextEdited: {
                if (smsSender.sendState === "success" || smsSender.sendState === "error")
                    smsSender.reset();
            }
            onHistoryEntryClicked: function(phone, name) {
                smsSender.reset();
            }
            onHistoryEntryDismissed: function(index) {
                var arr = root.smsHistory.slice();
                arr.splice(index, 1);
                root.smsHistory = arr;
            }
            onHistoryClearRequested: root.smsHistory = []
            onOpenKdeConnect: utilityExecutor.run("kdeconnect-settings")
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

    // ── SmsSender (non-visual) ──

    SmsSender {
        id: smsSender
        deviceId: root.deviceId

        onSent: function(entry) {
            root.smsHistory = [entry].concat(root.smsHistory).slice(0, 5);
            if (root.speakerBeep)
                playBeep();
            unreadRefreshDelay.start();
        }

        onClearRequested: root.clearAfterSend()
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
