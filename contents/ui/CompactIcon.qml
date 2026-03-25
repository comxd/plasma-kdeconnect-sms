/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later

    Compact panel icon with unread SMS badge overlay.
*/

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: compactIcon

    // ── Required properties ──

    required property int unreadCount

    // ── Signal ──

    signal clicked()

    MouseArea {
        anchors.fill: parent
        onClicked: compactIcon.clicked()

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: parent.containsMouse
        }
    }

    // ── Unread SMS dot indicator ──
    Rectangle {
        visible: compactIcon.unreadCount > 0
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -Math.round(height / 4)
        anchors.rightMargin: -Math.round(width / 4)
        width: Kirigami.Units.smallSpacing * 2
        height: width
        radius: width / 2
        color: Kirigami.Theme.highlightColor
    }
}
