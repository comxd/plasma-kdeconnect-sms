/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later

    Message text area with character counter and SMS segment info.
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

import "../code/helpers.js" as Helpers

ColumnLayout {
    id: messageInput
    spacing: Kirigami.Units.smallSpacing

    // ── Required properties ──

    required property string sendState

    // ── Output ──

    readonly property string messageText: messageField.text

    // ── Signals ──

    signal textEdited()

    // ── Internal ──

    property bool _clearing: false

    // ── Public API ──

    function clear() {
        _clearing = true;
        messageField.text = "";
        _clearing = false;
    }

    // ── UI ──

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Controls.ScrollView {
            anchors.fill: parent

            Controls.TextArea {
                id: messageField
                placeholderText: i18n("Type your message here...")
                Accessible.name: i18n("Message")
                wrapMode: TextEdit.WordWrap
                enabled: messageInput.sendState !== "sending"
                Kirigami.SpellCheck.enabled: true

                onTextChanged: {
                    if (!messageInput._clearing)
                        messageInput.textEdited();
                }
            }
        }

        Controls.ToolButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Kirigami.Units.smallSpacing
            visible: messageField.text.length > 0 && messageField.enabled
            icon.name: "edit-clear"
            icon.width: Kirigami.Units.iconSizes.small
            icon.height: Kirigami.Units.iconSizes.small
            width: Kirigami.Units.iconSizes.medium
            height: Kirigami.Units.iconSizes.medium
            onClicked: messageField.text = ""
            Controls.ToolTip.text: i18n("Clear message")
            Controls.ToolTip.visible: hovered
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.largeSpacing

        Controls.Label {
            id: segmentLabel
            Layout.fillWidth: true
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: Kirigami.Theme.disabledTextColor
            text: {
                var info = Helpers.smsSegmentInfo(messageField.text);
                if (info.segments <= 0)
                    return "";
                var counter = i18np("%1 character", "%1 characters", info.chars);
                if (info.segments === 1)
                    return counter;
                return counter + " · " + i18np("%1 segment", "%1 segments", info.segments);
            }
        }

        Controls.Label {
            visible: {
                var info = Helpers.smsSegmentInfo(messageField.text);
                return info.isUnicode && info.chars > 0;
            }
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: Kirigami.Theme.neutralTextColor
            text: i18n("Unicode")
        }

        // ── Spell-check toggle ──

        Controls.AbstractButton {
            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing / 2

                Kirigami.Icon {
                    source: "tools-check-spelling"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    opacity: messageField.Kirigami.SpellCheck.enabled ? 1.0 : 0.4
                }

                Controls.Label {
                    text: i18n("Spell check")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: messageField.Kirigami.SpellCheck.enabled
                        ? Kirigami.Theme.textColor
                        : Kirigami.Theme.disabledTextColor
                }
            }

            Controls.ToolTip.text: messageField.Kirigami.SpellCheck.enabled
                ? i18n("Disable spell check")
                : i18n("Enable spell check")
            Controls.ToolTip.visible: hovered

            onClicked: messageField.Kirigami.SpellCheck.enabled = !messageField.Kirigami.SpellCheck.enabled
        }
    }
}
