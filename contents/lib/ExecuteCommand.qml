/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later

    Reusable async shell command wrapper using plasma5support DataSource.
*/

import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: root

    signal finished(int exitCode, string stdout, string stderr)

    function run(command) {
        datasource.connectSource(command);
    }

    Plasma5Support.DataSource {
        id: datasource
        engine: "executable"
        connectedSources: []

        onNewData: function(source, data) {
            var stdout = data["stdout"] || "";
            var stderr = data["stderr"] || "";
            var exitCode = data["exit code"] || 0;

            disconnectSource(source);

            root.finished(exitCode, stdout, stderr);
        }
    }
}
