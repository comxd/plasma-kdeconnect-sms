/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

import org.kde.kdeconnect as KDEConnect

import "../code/helpers.js" as Helpers

Kirigami.FormLayout {
    id: configPage

    property string cfg_defaultDeviceId
    property string cfg_defaultDeviceName
    property string cfg_defaultCountry
    property alias cfg_speakerBeep: speakerBeepCheck.checked
    property alias cfg_speakerBeepReps: speakerBeepReps.value

    // ── Device list (KDE Connect native model) ──

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

    // ── Country list model ──

    ListModel {
        id: countryModel
    }

    function buildCountryModel() {
        countryModel.clear();
        countryModel.append({ countryCode: "", countryDisplay: i18n("-- Select a country --") });
        var countries = Helpers.getCountryList();
        for (var i = 0; i < countries.length; i++) {
            countryModel.append({
                countryCode: countries[i].code,
                countryDisplay: countries[i].name + " (+" + countries[i].callingCode + ")"
            });
        }

        // Restore saved selection
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

    Component.onCompleted: {
        refreshDevices();
        buildCountryModel();
    }

    // ── Device selector ──

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

    // ── Country selector ──

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
            if (currentIndex > 0) {
                var selected = countryModel.get(currentIndex);
                cfg_defaultCountry = selected ? selected.countryCode : "";
            }
        }

        // Type-ahead: jump to first matching country as user types
        onEditTextChanged: {
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
                    break;
                }
            }
        }
    }

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
}
