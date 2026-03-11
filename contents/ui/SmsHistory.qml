/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later

    SMS history: shows last sent messages with quick re-send.
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

import "../code/helpers.js" as Helpers

ColumnLayout {
    id: historyRoot
    spacing: 0

    // ── Required properties ──

    required property var historyModel   // array of { phoneNumber, contactName, messagePreview, timestamp }

    // ── Signals ──

    signal entryClicked(string phoneNumber, string contactName)
    signal entryDismissed(int index)
    signal clearRequested()

    // ── Sync JS array → ListModel for proper add/remove animations ──

    ListModel {
        id: internalModel
    }

    onHistoryModelChanged: _syncModel()

    function _syncModel() {
        internalModel.clear();
        if (!historyModel) return;
        for (var i = 0; i < historyModel.length; i++) {
            var e = historyModel[i];
            internalModel.append({
                phoneNumber: e.phoneNumber || "",
                contactName: e.contactName || "",
                messagePreview: e.messagePreview || "",
                timestamp: e.timestamp || 0
            });
        }
    }

    // ── Header ──

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Controls.Label {
            text: i18n("Recent")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: Kirigami.Theme.disabledTextColor
            Layout.fillWidth: true
        }

        Controls.ToolButton {
            icon.name: "edit-clear-history"
            icon.width: Kirigami.Units.iconSizes.small
            icon.height: Kirigami.Units.iconSizes.small
            width: Kirigami.Units.iconSizes.medium
            height: Kirigami.Units.iconSizes.medium
            Controls.ToolTip.text: i18n("Clear history")
            Controls.ToolTip.visible: hovered
            onClicked: historyRoot.clearRequested()
        }
    }

    // ── Separator ──

    Kirigami.Separator {
        Layout.fillWidth: true
    }

    // ── History list ──

    Column {
        id: historyColumn
        Layout.fillWidth: true

        // Fade-in for new entries
        add: Transition {
            NumberAnimation {
                properties: "opacity"
                from: 0
                to: 1
                duration: Kirigami.Units.shortDuration
            }
        }

        // Smooth repositioning when entries are removed
        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.InOutQuad
            }
        }

        Repeater {
            model: internalModel

            delegate: Controls.ItemDelegate {
                id: historyDelegate
                width: historyColumn.width
                padding: Kirigami.Units.smallSpacing
                hoverEnabled: true
                clip: true

                // Slide-out dismiss animation
                SequentialAnimation {
                    id: dismissAnimation
                    NumberAnimation {
                        target: historyDelegate
                        property: "x"
                        to: historyColumn.width
                        duration: Kirigami.Units.shortDuration
                        easing.type: Easing.InQuad
                    }
                    ScriptAction {
                        script: {
                            historyDelegate.visible = false;
                            historyRoot.entryDismissed(index);
                        }
                    }
                }

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        source: "mail-sent"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        Layout.alignment: Qt.AlignTop
                        opacity: 0.6
                    }

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        Controls.Label {
                            text: model.contactName || model.phoneNumber
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }

                        Controls.Label {
                            text: model.messagePreview
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.disabledTextColor
                        }
                    }

                    Controls.Label {
                        text: formatRelativeTime(model.timestamp)
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        Layout.alignment: Qt.AlignTop
                    }

                    // Dismiss button (visible on hover)
                    Controls.ToolButton {
                        visible: historyDelegate.hovered
                        icon.name: "window-close"
                        icon.width: Kirigami.Units.iconSizes.small
                        icon.height: Kirigami.Units.iconSizes.small
                        width: Kirigami.Units.iconSizes.medium
                        height: Kirigami.Units.iconSizes.medium
                        Layout.alignment: Qt.AlignTop
                        Controls.ToolTip.text: i18n("Dismiss")
                        Controls.ToolTip.visible: hovered
                        onClicked: dismissAnimation.start()
                    }
                }

                onClicked: historyRoot.entryClicked(model.phoneNumber, model.contactName)
            }
        }
    }

    // ── Relative time formatting (using i18n) ──

    function formatRelativeTime(timestamp) {
        var secs = Helpers.relativeTimeSeconds(timestamp);
        if (secs < 0)
            return "";
        if (secs < 60)
            return i18n("Just now");
        if (secs < 3600) {
            var mins = Math.floor(secs / 60);
            return i18np("1 min ago", "%1 min ago", mins);
        }
        if (secs < 86400) {
            var hours = Math.floor(secs / 3600);
            return i18np("1 h ago", "%1 h ago", hours);
        }
        var days = Math.floor(secs / 86400);
        return i18np("1 d ago", "%1 d ago", days);
    }
}
