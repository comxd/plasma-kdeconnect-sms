/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later

    Country picker inline view with search and filterable list.
    Designed to be used as a page in a StackLayout.
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3

import "../code/helpers.js" as Helpers

ColumnLayout {
    id: countryPicker
    spacing: 0

    // ── Required properties ──

    required property string activeCountry

    // ── Signals ──

    signal countrySelected(string code)
    signal backRequested()

    // ── Public API ──

    function activate() {
        countrySearchField.text = "";
        countryFilterModel.update();
        countrySearchField.forceActiveFocus();
    }

    // ── Header with back button ──

    PlasmaExtras.PlasmoidHeading {
        Layout.fillWidth: true

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Button {
                icon.name: mirrored ? "go-next" : "go-previous"
                text: i18n("Back")
                onClicked: countryPicker.backRequested()
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: i18n("Select Country")
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                elide: Text.ElideRight
            }

            // Spacer to balance the back button
            Item {
                implicitWidth: Kirigami.Units.gridUnit * 4
            }
        }
    }

    // ── Search field ──

    Controls.TextField {
        id: countrySearchField
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        Layout.topMargin: Kirigami.Units.smallSpacing
        placeholderText: i18n("Search country...")
        onTextChanged: countryFilterModel.update()

        Keys.onEscapePressed: countryPicker.backRequested()
    }

    // ── Country list ──

    PlasmaComponents3.ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: Kirigami.Units.smallSpacing

        PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

        ListView {
            id: countryListView
            clip: true
            model: countryFilterModel
            currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds
            Keys.onEscapePressed: countryPicker.backRequested()

            delegate: Controls.ItemDelegate {
                width: countryListView.width
                text: model.display
                highlighted: model.code === countryPicker.activeCountry
                onClicked: {
                    countryPicker.countrySelected(model.code);
                    countrySearchField.text = "";
                }
            }
        }
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
