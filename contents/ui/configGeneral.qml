/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import org.kde.plasma.plasmoid
import org.kde.kdeconnect as KDEConnect

import "../code/helpers.js" as Helpers

KCM.SimpleKCM {
    id: configPage

    property string cfg_defaultDeviceId
    property string cfg_defaultDeviceName
    property string cfg_defaultCountry
    property alias cfg_speakerBeep: speakerBeepCheck.checked
    property alias cfg_speakerBeepReps: speakerBeepReps.value
    property alias cfg_hideWidget: hideWidgetCheck.checked

    // ── Non-visual: Device list (KDE Connect native model) ──

    KDEConnect.DevicesModel {
        id: devicesModel
        displayFilter: KDEConnect.DevicesModel.Paired | KDEConnect.DevicesModel.Reachable
    }

    // Bridge: Instantiator reads devicesModel roles via delegate properties
    Instantiator {
        id: deviceInstantiator
        model: devicesModel
        active: true
        delegate: QtObject {
            required property string deviceId
            required property string name
        }
        onCountChanged: configPage.refreshDevices()
    }

    ListModel {
        id: deviceModel
    }

    ListModel {
        id: countryModel
    }

    // ── Non-visual: helper state and functions ──

    property bool _buildingCountry: false

    function refreshDevices() {
        deviceModel.clear();
        deviceModel.append({ deviceId: "", deviceName: i18n("-- Select a device --") });

        for (var i = 0; i < deviceInstantiator.count; i++) {
            var obj = deviceInstantiator.objectAt(i);
            if (obj) {
                deviceModel.append({ deviceId: obj.deviceId, deviceName: obj.name });
            }
        }

        if (deviceModel.count === 1) {
            deviceModel.clear();
            deviceModel.append({ deviceId: "", deviceName: i18n("-- No devices found --") });
        }

        // Restore saved selection
        var selIdx = 0;
        if (cfg_defaultDeviceId) {
            for (var j = 1; j < deviceModel.count; j++) {
                if (deviceModel.get(j).deviceId === cfg_defaultDeviceId) {
                    selIdx = j;
                    break;
                }
            }
        }
        deviceCombo.currentIndex = selIdx;
    }

    function buildCountryModel() {
        _buildingCountry = true;
        countryModel.clear();
        countryModel.append({ countryCode: "", countryDisplay: i18n("-- Select a country --") });
        var countries = Helpers.getCountryList();
        for (var i = 0; i < countries.length; i++) {
            countryModel.append({
                countryCode: countries[i].code,
                countryDisplay: countries[i].name + " (+" + countries[i].callingCode + ")"
            });
        }
        _syncCountryIndex();
        _buildingCountry = false;
    }

    function _syncCountryIndex() {
        var idx = 0;
        if (cfg_defaultCountry) {
            for (var j = 1; j < countryModel.count; j++) {
                if (countryModel.get(j).countryCode === cfg_defaultCountry) {
                    idx = j;
                    break;
                }
            }
        }
        countryCombo.currentIndex = idx;
    }

    onCfg_defaultCountryChanged: {
        if (!_buildingCountry && countryModel.count > 0)
            _syncCountryIndex();
    }

    Component.onCompleted: {
        refreshDevices();
        buildCountryModel();
    }

    // ── Visual: form controls only ──

    Kirigami.FormLayout {
        id: formLayout

        // ── KDE Connect section ──

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("KDE Connect")
        }

        Item { width: 1; height: Kirigami.Units.smallSpacing }

        RowLayout {
            Kirigami.FormData.label: i18n("Device:")
            spacing: Kirigami.Units.smallSpacing

            Controls.ComboBox {
                id: deviceCombo
                Layout.fillWidth: true
                model: deviceModel
                textRole: "deviceName"
                valueRole: "deviceId"

                onActivated: {
                    var selected = deviceModel.get(currentIndex);
                    cfg_defaultDeviceId = selected.deviceId;
                    cfg_defaultDeviceName = selected.deviceName;
                    if (!selected.deviceId) {
                        cfg_defaultDeviceId = "";
                        cfg_defaultDeviceName = "";
                    }
                }
            }

            Controls.Button {
                icon.name: "view-refresh"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                text: i18n("Refresh")
                onClicked: configPage.refreshDevices()
            }
        }

        // ── Phone number section ──

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Phone number")
        }

        Item { width: 1; height: Kirigami.Units.smallSpacing }

        Controls.ComboBox {
            id: countryCombo
            Kirigami.FormData.label: i18n("Country:")
            Layout.fillWidth: true
            model: countryModel
            textRole: "countryDisplay"
            valueRole: "countryCode"
            editable: true

            onActivated: function(index) {
                var selected = countryModel.get(index);
                cfg_defaultCountry = selected ? selected.countryCode : "";
            }

            onAccepted: {
                if (currentIndex >= 0) {
                    var selected = countryModel.get(currentIndex);
                    cfg_defaultCountry = selected ? selected.countryCode : "";
                }
            }

            // Type-ahead: jump to first matching country as user types
            onEditTextChanged: {
                // Skip during model rebuild
                if (configPage._buildingCountry)
                    return;
                // Skip programmatic changes (when editText matches selected item)
                if (currentIndex >= 0
                        && currentIndex < countryModel.count
                        && editText === countryModel.get(currentIndex).countryDisplay)
                    return;
                var search = editText.toLowerCase();
                if (!search) return;
                for (var i = 1; i < countryModel.count; i++) {
                    var entry = countryModel.get(i);
                    if (entry.countryDisplay.toLowerCase().indexOf(search) === 0) {
                        currentIndex = i;
                        cfg_defaultCountry = entry.countryCode;
                        break;
                    }
                }
            }
        }

        // ── Notifications section ──

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Notifications")
        }

        Item { width: 1; height: Kirigami.Units.smallSpacing }

        Controls.CheckBox {
            id: speakerBeepCheck
            Kirigami.FormData.label: i18n("Beep after sending:")
            text: i18n("Play a beep sound after SMS is sent")
        }

        Controls.SpinBox {
            id: speakerBeepReps
            Kirigami.FormData.label: i18n("Beep repetitions:")
            from: 1
            to: 10
            enabled: speakerBeepCheck.checked
        }

        // ── Widget visibility section ──

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Widget visibility")
        }

        Item { width: 1; height: Kirigami.Units.smallSpacing }

        Controls.CheckBox {
            id: hideWidgetCheck
            Kirigami.FormData.label: i18n("Panel icon:")
            text: i18n("Hide widget icon from panel")
            checked: plasmoid.configuration.hideWidget
            onToggled: {
                plasmoid.configuration.hideWidget = checked;
                plasmoid.configuration.writeConfig();
            }

            Connections {
                target: plasmoid.configuration
                function onHideWidgetChanged() {
                    hideWidgetCheck.checked = plasmoid.configuration.hideWidget;
                }
            }
        }

        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            color: plasmoid.configuration.hideWidget
                ? Kirigami.Theme.neutralTextColor
                : Kirigami.Theme.disabledTextColor
            text: plasmoid.configuration.hideWidget
                ? i18n("The widget icon is hidden from the panel. To restore it, enter Edit Mode, right-click the widget, and uncheck \"Hide widget from panel\". Tip: you can also assign a global keyboard shortcut to toggle the popup.")
                : i18n("Hides the widget icon from the panel. The widget remains accessible via Edit Mode or a keyboard shortcut.")
        }

    } // Kirigami.FormLayout
}
