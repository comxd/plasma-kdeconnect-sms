/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: Qt.resolvedUrl("../icons/icon.svg")
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Help")
        icon: "help-contents"
        source: "configHelp.qml"
    }
}
