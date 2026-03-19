/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later

    About tab: project info, donation button, and footer links.
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents3

ColumnLayout {
    id: aboutTab
    spacing: 0

    // ── Signal ──

    signal backRequested()

    // ── Header with back button ──

    PlasmaExtras.PlasmoidHeading {
        Layout.fillWidth: true

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Button {
                icon.name: mirrored ? "go-next" : "go-previous"
                text: i18n("Back")
                onClicked: aboutTab.backRequested()
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: i18n("About")
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

    // ── Scrollable content ──

    Flickable {
        id: flickable
        Layout.fillWidth: true
        Layout.fillHeight: true

        contentWidth: width
        contentHeight: Math.max(aboutColumn.implicitHeight, height)
        clip: true
        flickableDirection: Flickable.VerticalFlick

        Controls.ScrollBar.vertical: Controls.ScrollBar {
            id: scrollBar
            policy: Controls.ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: aboutColumn
            width: parent.width - (scrollBar.visible ? scrollBar.width : 0)
            height: Math.max(implicitHeight, flickable.height)
            spacing: Kirigami.Units.largeSpacing

            // ════════════════════════════════════════
            // ── Section 1: Header ──
            // ════════════════════════════════════════

            Rectangle {
                id: headerBlock
                Layout.fillWidth: true
                implicitHeight: headerRow.implicitHeight + Kirigami.Units.largeSpacing * 4 + accentStrip.height

                Kirigami.Theme.colorSet: Kirigami.Theme.Header
                Kirigami.Theme.inherit: false

                color: Kirigami.Theme.backgroundColor
                radius: Kirigami.Units.smallSpacing

                // Mask top corners to keep them flat (edge-to-edge)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.radius
                    color: parent.color
                }

                RowLayout {
                    id: headerRow
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -Math.round(accentStrip.height / 2)
                    anchors.leftMargin: Kirigami.Units.largeSpacing * 2
                    spacing: Kirigami.Units.largeSpacing * 2

                    Kirigami.Icon {
                        source: Qt.resolvedUrl("../icons/logo.svg")
                        Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                        Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        spacing: 0
                        Layout.alignment: Qt.AlignVCenter

                        Controls.Label {
                            text: "KDE Connect SMS"
                            font.bold: true
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.6
                            color: Kirigami.Theme.textColor
                        }
                        Controls.Label {
                            text: i18n("Version %1", Plasmoid.metaData.version || "1.0.0")
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        }

                        Item { height: Kirigami.Units.smallSpacing }

                        Controls.Label {
                            text: "David DIVERRES — <a href=\"mailto:david@comexpertise.com\">david@comexpertise.com</a>"
                            textFormat: Text.RichText
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            color: Kirigami.Theme.disabledTextColor
                            onLinkActivated: (link) => Qt.openUrlExternally(link)
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }

                // Accent strip at the bottom
                Rectangle {
                    id: accentStrip
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottomMargin: parent.radius
                    height: 3
                    color: Kirigami.Theme.highlightColor
                }
            }

            // ════════════════════════════════════════
            // ── Section 2: Body ──
            // ════════════════════════════════════════

            Controls.Label {
                text: i18n("Send SMS from your desktop via KDE Connect")
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                Layout.rightMargin: Kirigami.Units.largeSpacing * 2
            }

            Item { height: Kirigami.Units.largeSpacing; width: 1 }

            Controls.Label {
                text: i18n("Enjoying this plasmoid? Support its development!")
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                Layout.rightMargin: Kirigami.Units.largeSpacing * 2
            }

            Controls.Label {
                text: i18n("This plasmoid is developed and maintained on my free time. If you find it useful, a small donation helps keep it going!")
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.9
                color: Kirigami.Theme.disabledTextColor
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                Layout.rightMargin: Kirigami.Units.largeSpacing * 2
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: bmcRow.implicitWidth + Kirigami.Units.largeSpacing * 2
                Layout.preferredHeight: bmcRow.implicitHeight + Kirigami.Units.mediumSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: bmcMouse.containsMouse ? "#ffe033" : "#FD0"

                RowLayout {
                    id: bmcRow
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.smallSpacing

                    Image {
                        source: Qt.resolvedUrl("../icons/bmc.svg")
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                        fillMode: Image.PreserveAspectFit
                    }

                    Controls.Label {
                        // Brand name — do NOT translate
                        text: "Buy me a coffee"
                        color: "#0D0C22"
                        font.bold: true
                    }
                }

                MouseArea {
                    id: bmcMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally("https://buymeacoffee.com/comxd")
                }
            }

            // ════════════════════════════════════════
            // ── Section 3: Footer (pushed to bottom) ──
            // ════════════════════════════════════════

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: footerColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                radius: Kirigami.Units.smallSpacing

                // Mask bottom corners to keep them flat (edge-to-edge)
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.radius
                    color: parent.color
                }

                ColumnLayout {
                    id: footerColumn
                    anchors.centerIn: parent
                    spacing: 2

                    Controls.Label {
                        text: "<a href=\"https://comexpertise.com\">comexpertise.com</a> · <a href=\"https://store.kde.org/p/1202579/\">KDE Store</a>"
                        textFormat: Text.RichText
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        color: Kirigami.Theme.disabledTextColor
                        horizontalAlignment: Text.AlignHCenter
                        onLinkActivated: (link) => Qt.openUrlExternally(link)
                        Layout.alignment: Qt.AlignHCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            acceptedButtons: Qt.NoButton
                        }
                    }

                    Controls.Label {
                        text: "\u00A9 2026 ComExpertise \u00B7 GPL-2.0-or-later"
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        color: Kirigami.Theme.disabledTextColor
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
