/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later

    SMS history full-page view with back navigation.
    Designed to be used as a page in a StackLayout.
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3

ColumnLayout {
    id: historyPage
    spacing: 0

    // ── Required properties ──

    required property var smsHistory

    // ── Signals ──

    signal backRequested()
    signal entryClicked(string phoneNumber, string contactName)
    signal entryDismissed(int index)
    signal clearRequested()

    // ── Header with back button ──

    PlasmaExtras.PlasmoidHeading {
        Layout.fillWidth: true

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Button {
                icon.name: mirrored ? "go-next" : "go-previous"
                text: i18n("Back")
                onClicked: historyPage.backRequested()
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: i18n("SMS History")
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

    // ── History content ──

    PlasmaComponents3.ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        visible: historyPage.smsHistory && historyPage.smsHistory.length > 0

        PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

        Flickable {
            contentWidth: width
            contentHeight: smsHistoryContent.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            SmsHistory {
                id: smsHistoryContent
                width: parent.width
                historyModel: historyPage.smsHistory

                onEntryClicked: function(phoneNumber, contactName) {
                    historyPage.entryClicked(phoneNumber, contactName);
                }
                onEntryDismissed: function(index) {
                    historyPage.entryDismissed(index);
                }
                onClearRequested: historyPage.clearRequested()
            }
        }
    }

    // ── Empty state ──

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !historyPage.smsHistory || historyPage.smsHistory.length === 0
        spacing: Kirigami.Units.largeSpacing

        Item { Layout.fillHeight: true }

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
            source: "mail-sent"
            opacity: 0.5
        }

        Controls.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: i18n("No messages sent yet")
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
            color: Kirigami.Theme.disabledTextColor
        }

        Item { Layout.fillHeight: true }
    }
}
