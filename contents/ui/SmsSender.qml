/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later

    Non-visual SMS sender: builds and executes kdeconnect-cli --send-sms command.
*/

import QtQuick

import "../lib" as Lib
import "../code/helpers.js" as Helpers

Item {
    id: smsSender
    visible: false
    width: 0; height: 0

    // ── Required properties ──

    required property string deviceId

    // ── State ──

    property string sendState: "idle"
    property string sendError: ""

    // ── Signals ──

    signal sent(var historyEntry)
    signal failed(string error)
    signal clearRequested()

    // ── Internal ──

    property string _pendingPhone: ""
    property string _pendingContact: ""
    property string _pendingMessage: ""
    property string _pendingResult: ""
    property string _pendingError: ""

    Lib.ExecuteCommand {
        id: executor
        onFinished: function(exitCode, stdout, stderr) {
            if (smsSender.sendState !== "sending") return;
            if (exitCode === 0) {
                smsSender._pendingResult = "success";
            } else {
                smsSender._pendingResult = "error";
                smsSender._pendingError = stderr || i18n("Failed to send SMS");
            }
            sendFeedbackTimer.restart();
        }
    }

    Timer {
        id: sendFeedbackTimer
        interval: 2500
        repeat: false
        onTriggered: {
            if (smsSender._pendingResult === "success") {
                smsSender.sendState = "success";
                var preview = smsSender._pendingMessage;
                if (preview.length > 30)
                    preview = preview.substring(0, 30) + "\u2026";
                var entry = {
                    phoneNumber: smsSender._pendingPhone,
                    contactName: smsSender._pendingContact,
                    messagePreview: preview,
                    timestamp: Date.now()
                };
                smsSender.sent(entry);
            } else {
                smsSender.sendState = "error";
                smsSender.sendError = smsSender._pendingError;
                smsSender.failed(smsSender._pendingError);
            }
            statusResetTimer.restart();
        }
    }

    Timer {
        id: statusResetTimer
        interval: 5000
        onTriggered: {
            if (smsSender.sendState === "success") {
                smsSender.clearRequested();
                smsSender.sendState = "idle";
            } else if (smsSender.sendState === "error") {
                smsSender.sendState = "idle";
            }
        }
    }

    // ── Public API ──

    function reset() {
        sendFeedbackTimer.stop();
        statusResetTimer.stop();
        sendState = "idle";
        sendError = "";
        _pendingResult = "";
        _pendingError = "";
    }

    function send(e164Phone, rawPhone, contactName, message) {
        sendState = "sending";
        sendError = "";

        _pendingPhone = rawPhone;
        _pendingContact = contactName;
        _pendingMessage = message;

        var cmd = "kdeconnect-cli --send-sms " + Helpers.shellEscape(message)
                + " --destination " + Helpers.shellEscape(e164Phone)
                + " -d " + Helpers.shellEscape(deviceId);
        executor.run(cmd);
    }
}
