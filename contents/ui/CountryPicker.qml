/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later

    Country picker popup with search and filterable list.
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kirigami.primitives as KirigamiPrimitives

import "../code/helpers.js" as Helpers

Controls.Popup {
    id: countryPicker
    width: Kirigami.Units.gridUnit * 18
    height: Kirigami.Units.gridUnit * 14
    modal: true
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100 }
    }

    background: KirigamiPrimitives.ShadowedRectangle {
        color: Kirigami.Theme.backgroundColor
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
        border.width: 1
        radius: Kirigami.Units.cornerRadius
        shadow.size: 12
        shadow.yOffset: 4
        shadow.color: Qt.rgba(0, 0, 0, 0.15)
    }

    // ── Required properties ──

    required property string activeCountry

    // ── Signals ──

    signal countrySelected(string code)

    // ── UI ──

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Controls.TextField {
            id: countrySearchField
            Layout.fillWidth: true
            placeholderText: i18n("Search country...")
            onTextChanged: countryFilterModel.update()
        }

        ListView {
            id: countryListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: countryFilterModel

            delegate: Controls.ItemDelegate {
                width: countryListView.width
                text: model.display
                highlighted: model.code === countryPicker.activeCountry
                onClicked: {
                    countryPicker.countrySelected(model.code);
                    countryPicker.close();
                    countrySearchField.text = "";
                }
            }
        }
    }

    onOpened: {
        countrySearchField.text = "";
        countryFilterModel.update();
        countrySearchField.forceActiveFocus();
    }

    ListModel {
        id: countryFilterModel
        property var allCountries: []

        function update() {
            clear();
            if (allCountries.length === 0)
                allCountries = Helpers.getCountryList();
            var search = countrySearchField.text.toLowerCase();
            for (var i = 0; i < allCountries.length; i++) {
                var c = allCountries[i];
                var display = c.name + " (+" + c.callingCode + ")";
                if (!search || display.toLowerCase().indexOf(search) !== -1)
                    append({ code: c.code, display: display });
            }
        }

        Component.onCompleted: update()
    }
}
