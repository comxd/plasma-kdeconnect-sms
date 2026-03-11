/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later

    Phone number input: country badge, text field, validation hint, contact autocomplete.
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kirigami.primitives as KirigamiPrimitives

import "../code/helpers.js" as Helpers

ColumnLayout {
    id: phoneInput
    spacing: Kirigami.Units.smallSpacing

    // ── KPeople role constants ──

    readonly property int kPeoplePhoneNumberRole: 260
    readonly property int kPeoplePersonVCardRole: 257
    readonly property int kPeoplePhotoImageProviderUriRole: 261

    // ── Required properties ──

    required property string activeCountry
    required property string sendState
    required property var contactSearchModel

    // ── Output ──

    readonly property string phoneText: phoneField.text
    readonly property bool isPhoneValid: phoneField.text.length > 0
        && /\d/.test(phoneField.text)
        && Helpers.isPossiblePhoneNumber(phoneField.text, phoneInput.activeCountry)
    property string selectedContactName: ""

    // ── Signals ──

    signal countryBadgeClicked()

    // ── Public API ──

    function clear() {
        phoneField.text = "";
        phoneField.rawInput = "";
        selectedContactName = "";
    }

    function setPhone(phone, contactName) {
        phoneField.text = phone;
        phoneField.rawInput = phone;
        selectedContactName = contactName || "";
        var formatted = Helpers.formatPhoneNumber(phone, phoneInput.activeCountry);
        if (formatted !== phoneField.text)
            phoneField.text = formatted;
    }

    function formatE164() {
        return Helpers.formatPhoneNumberE164(phoneField.text, phoneInput.activeCountry);
    }

    // ── Country badge + phone field ──

    Controls.Label {
        text: i18n("Phone number:")
        Layout.fillWidth: true
    }

    // ── Selected contact chip ──

    RowLayout {
        Layout.fillWidth: true
        visible: phoneInput.selectedContactName.length > 0
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: "user"
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
        }

        Controls.Label {
            text: i18n("To: %1", phoneInput.selectedContactName)
            Layout.fillWidth: true
            elide: Text.ElideRight
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: Kirigami.Theme.activeTextColor
        }

        Controls.ToolButton {
            icon.name: "edit-clear"
            icon.width: Kirigami.Units.iconSizes.small
            icon.height: Kirigami.Units.iconSizes.small
            width: Kirigami.Units.iconSizes.medium
            height: Kirigami.Units.iconSizes.medium
            onClicked: {
                phoneInput.clear();
                phoneField.forceActiveFocus();
            }
            Controls.ToolTip.text: i18n("Clear contact")
            Controls.ToolTip.visible: hovered
        }
    }

    RowLayout {
        id: phoneFieldRow
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Controls.ToolButton {
            id: countryBadge
            property string badgeLabel: {
                var cc = Helpers.detectCountry(phoneField.text, phoneInput.activeCountry);
                if (!cc)
                    cc = phoneInput.activeCountry;
                if (!cc)
                    return "";
                var callingCode = Helpers.getCallingCode(cc);
                return callingCode ? cc + " +" + callingCode : cc;
            }
            text: badgeLabel || i18n("Country")
            icon.name: badgeLabel ? "" : "globe"
            icon.width: Kirigami.Units.iconSizes.smallMedium
            icon.height: Kirigami.Units.iconSizes.smallMedium
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            onClicked: phoneInput.countryBadgeClicked()
        }

        Controls.TextField {
            id: phoneField
            Layout.fillWidth: true
            placeholderText: {
                var example = Helpers.examplePhoneNumber(phoneInput.activeCountry);
                return example || i18n("Enter phone number");
            }
            enabled: phoneInput.sendState !== "sending"

            property string rawInput: ""

            function selectContact(index) {
                var modelIndex = phoneInput.contactSearchModel.index(index, 0);
                var phone = phoneInput.contactSearchModel.data(modelIndex, phoneInput.kPeoplePhoneNumberRole);
                if (!phone) return;
                var name = phoneInput.contactSearchModel.data(modelIndex, 0 /* Qt::DisplayRole */);
                text = phone;
                rawInput = phone;
                phoneInput.selectedContactName = name ? String(name) : "";
                phoneInput.contactSearchModel.filterString = "";
                forceActiveFocus();
                var formatted = Helpers.formatPhoneNumber(phone, phoneInput.activeCountry);
                if (formatted !== text)
                    text = formatted;
            }

            onTextEdited: {
                rawInput = text;
                phoneInput.selectedContactName = "";
                // Only format if input looks like a phone number (has digits)
                // Skip formatting for pure text (contact name search)
                if (/\d/.test(text)) {
                    var formatted = Helpers.formatPhoneNumber(text, phoneInput.activeCountry);
                    if (formatted !== text) {
                        text = formatted;
                        cursorPosition = text.length;
                    }
                }
                // Update contact autocomplete filter
                phoneInput.contactSearchModel.filterString = text;
                contactAutocomplete.currentIndex = -1;
            }

            Keys.onUpPressed: {
                if (contactPopup.visible && contactAutocomplete.currentIndex > 0)
                    contactAutocomplete.currentIndex--;
            }
            Keys.onDownPressed: {
                if (contactPopup.visible)
                    contactAutocomplete.currentIndex = Math.min(
                        contactAutocomplete.currentIndex + 1,
                        contactAutocomplete.count - 1);
            }
            Keys.onReturnPressed: {
                if (contactPopup.visible && contactAutocomplete.currentIndex >= 0)
                    selectContact(contactAutocomplete.currentIndex);
                else
                    event.accepted = false;
            }
            Keys.onEscapePressed: {
                if (contactPopup.visible)
                    phoneInput.contactSearchModel.filterString = "";
                else
                    event.accepted = false;
            }
        }
    }

    // ── Validation hint ──

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        visible: phoneHint.text.length > 0

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            source: {
                if (phoneField.text.length === 0 || !/\d/.test(phoneField.text))
                    return "";
                if (Helpers.isValidPhoneNumber(phoneField.text, phoneInput.activeCountry))
                    return "dialog-ok";
                if (Helpers.isPossiblePhoneNumber(phoneField.text, phoneInput.activeCountry))
                    return "dialog-information";
                return "dialog-warning";
            }
            color: phoneHint.color
        }

        Controls.Label {
            id: phoneHint
            Layout.fillWidth: true
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: {
                if (phoneField.text.length === 0 || !/\d/.test(phoneField.text))
                    return Kirigami.Theme.disabledTextColor;
                if (Helpers.isValidPhoneNumber(phoneField.text, phoneInput.activeCountry))
                    return Kirigami.Theme.positiveTextColor;
                if (Helpers.isPossiblePhoneNumber(phoneField.text, phoneInput.activeCountry))
                    return Kirigami.Theme.linkColor;
                return Kirigami.Theme.neutralTextColor;
            }
            text: {
                if (phoneField.text.length === 0 || !/\d/.test(phoneField.text))
                    return "";
                var countryCode = Helpers.detectCountry(phoneField.text, phoneInput.activeCountry);
                if (Helpers.isValidPhoneNumber(phoneField.text, phoneInput.activeCountry)) {
                    var name = countryCode ? Helpers.countryName(countryCode) : "";
                    return name ? i18n("Valid number — %1", name) : i18n("Valid number");
                }
                if (Helpers.isPossiblePhoneNumber(phoneField.text, phoneInput.activeCountry)) {
                    var possibleName = countryCode ? Helpers.countryName(countryCode) : "";
                    return possibleName ? i18n("Possible number — %1", possibleName) : i18n("Possible number");
                }
                return i18n("Incomplete number");
            }
        }
    }

    // ── Contact autocomplete popup (KPeople) ──

    Controls.Popup {
        id: contactPopup
        parent: phoneFieldRow
        y: phoneFieldRow.height
        width: phoneFieldRow.width
        padding: 1
        focus: false
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

        contentItem: ListView {
            id: contactAutocomplete
            clip: true
            model: phoneInput.contactSearchModel
            currentIndex: -1
            implicitHeight: Math.min(contentHeight,
                6 * Kirigami.Units.gridUnit * 2.5)
            highlight: Rectangle {
                color: Kirigami.Theme.highlightColor
                opacity: 0.2
            }
            highlightMoveDuration: 0

            delegate: Controls.ItemDelegate {
                width: contactAutocomplete.width
                highlighted: contactAutocomplete.currentIndex === index
                background: Rectangle {
                    color: index % 2 === 1 ? Kirigami.Theme.alternateBackgroundColor : "transparent"
                }
                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Image {
                        id: contactPhoto
                        source: {
                            var uri = phoneInput.contactSearchModel.data(
                                phoneInput.contactSearchModel.index(index, 0),
                                phoneInput.kPeoplePhotoImageProviderUriRole);
                            return uri ? String(uri) : "";
                        }
                        visible: status === Image.Ready
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: Kirigami.Units.iconSizes.medium
                        sourceSize.height: Kirigami.Units.iconSizes.medium
                    }

                    Kirigami.Icon {
                        source: "user"
                        visible: !contactPhoto.visible
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    }

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        Controls.Label {
                            text: model.display || ""
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            Controls.Label {
                                text: model.phoneNumber || ""
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                color: Kirigami.Theme.disabledTextColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Controls.Label {
                                property string typeKey: {
                                    var vcard = phoneInput.contactSearchModel.data(
                                        phoneInput.contactSearchModel.index(index, 0), phoneInput.kPeoplePersonVCardRole);
                                    return Helpers.phoneTypeLabel(vcard, model.phoneNumber);
                                }
                                visible: typeKey.length > 0
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                color: Kirigami.Theme.disabledTextColor
                                text: {
                                    if (typeKey === "mobile") return i18n("Mobile");
                                    if (typeKey === "work") return i18n("Work");
                                    if (typeKey === "home") return i18n("Home");
                                    if (typeKey === "fax") return i18n("Fax");
                                    return "";
                                }
                            }
                        }
                    }
                }
                onClicked: phoneField.selectContact(index)
            }
        }

        onClosed: {
            phoneInput.contactSearchModel.filterString = "";
        }
    }

    function _updatePopup() {
        if (contactSearchModel.count > 0 && phoneField.activeFocus) {
            if (!contactPopup.opened)
                contactPopup.open();
        } else {
            if (contactPopup.opened)
                contactPopup.close();
        }
    }

    Connections {
        target: phoneInput.contactSearchModel
        function onCountChanged() { phoneInput._updatePopup(); }
    }

    Connections {
        target: phoneField
        function onActiveFocusChanged() { phoneInput._updatePopup(); }
    }
}
