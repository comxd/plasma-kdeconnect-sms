/*
    SPDX-FileCopyrightText: 2026 ComExpertise
    SPDX-License-Identifier: GPL-2.0-or-later

    Helper functions for KDE Connect SMS plasmoid.
*/

.import "lib/libphonenumber-js/libphonenumber-js.min.js" as LP

// ── Shell escaping ──

function shellEscape(str) {
    if (str === undefined || str === null)
        return "''";
    return "'" + String(str).replace(/'/g, "'\\''") + "'";
}

// ── D-Bus command builders (contacts sync only — no native QML API) ──

var _dbusService = "org.kde.kdeconnect";
var _dbusBasePath = "/modules/kdeconnect";

// ── Country names (ISO 3166-1 alpha-2 → English name) ──

var _countryNames = {
    "AC": "Ascension Island", "AD": "Andorra", "AE": "United Arab Emirates",
    "AF": "Afghanistan", "AG": "Antigua and Barbuda", "AI": "Anguilla",
    "AL": "Albania", "AM": "Armenia", "AO": "Angola", "AR": "Argentina",
    "AS": "American Samoa", "AT": "Austria", "AU": "Australia", "AW": "Aruba",
    "AX": "Aland Islands", "AZ": "Azerbaijan", "BA": "Bosnia and Herzegovina",
    "BB": "Barbados", "BD": "Bangladesh", "BE": "Belgium", "BF": "Burkina Faso",
    "BG": "Bulgaria", "BH": "Bahrain", "BI": "Burundi", "BJ": "Benin",
    "BL": "St. Barthelemy", "BM": "Bermuda", "BN": "Brunei", "BO": "Bolivia",
    "BQ": "Caribbean Netherlands", "BR": "Brazil", "BS": "Bahamas", "BT": "Bhutan",
    "BW": "Botswana", "BY": "Belarus", "BZ": "Belize", "CA": "Canada",
    "CC": "Cocos (Keeling) Islands", "CD": "Congo - Kinshasa",
    "CF": "Central African Republic", "CG": "Congo - Brazzaville",
    "CH": "Switzerland", "CI": "Cote d'Ivoire", "CK": "Cook Islands",
    "CL": "Chile", "CM": "Cameroon", "CN": "China", "CO": "Colombia",
    "CR": "Costa Rica", "CU": "Cuba", "CV": "Cape Verde", "CW": "Curacao",
    "CX": "Christmas Island", "CY": "Cyprus", "CZ": "Czechia", "DE": "Germany",
    "DJ": "Djibouti", "DK": "Denmark", "DM": "Dominica",
    "DO": "Dominican Republic", "DZ": "Algeria", "EC": "Ecuador",
    "EE": "Estonia", "EG": "Egypt", "EH": "Western Sahara", "ER": "Eritrea",
    "ES": "Spain", "ET": "Ethiopia", "FI": "Finland", "FJ": "Fiji",
    "FK": "Falkland Islands", "FM": "Micronesia", "FO": "Faroe Islands",
    "FR": "France", "GA": "Gabon", "GB": "United Kingdom", "GD": "Grenada",
    "GE": "Georgia", "GF": "French Guiana", "GG": "Guernsey", "GH": "Ghana",
    "GI": "Gibraltar", "GL": "Greenland", "GM": "Gambia", "GN": "Guinea",
    "GP": "Guadeloupe", "GQ": "Equatorial Guinea", "GR": "Greece",
    "GT": "Guatemala", "GU": "Guam", "GW": "Guinea-Bissau", "GY": "Guyana",
    "HK": "Hong Kong", "HN": "Honduras", "HR": "Croatia", "HT": "Haiti",
    "HU": "Hungary", "ID": "Indonesia", "IE": "Ireland", "IL": "Israel",
    "IM": "Isle of Man", "IN": "India", "IO": "British Indian Ocean Territory",
    "IQ": "Iraq", "IR": "Iran", "IS": "Iceland", "IT": "Italy", "JE": "Jersey",
    "JM": "Jamaica", "JO": "Jordan", "JP": "Japan", "KE": "Kenya",
    "KG": "Kyrgyzstan", "KH": "Cambodia", "KI": "Kiribati", "KM": "Comoros",
    "KN": "St. Kitts and Nevis", "KP": "North Korea", "KR": "South Korea",
    "KW": "Kuwait", "KY": "Cayman Islands", "KZ": "Kazakhstan", "LA": "Laos",
    "LB": "Lebanon", "LC": "St. Lucia", "LI": "Liechtenstein", "LK": "Sri Lanka",
    "LR": "Liberia", "LS": "Lesotho", "LT": "Lithuania", "LU": "Luxembourg",
    "LV": "Latvia", "LY": "Libya", "MA": "Morocco", "MC": "Monaco",
    "MD": "Moldova", "ME": "Montenegro", "MF": "St. Martin", "MG": "Madagascar",
    "MH": "Marshall Islands", "MK": "North Macedonia", "ML": "Mali",
    "MM": "Myanmar (Burma)", "MN": "Mongolia", "MO": "Macao",
    "MP": "Northern Mariana Islands", "MQ": "Martinique", "MR": "Mauritania",
    "MS": "Montserrat", "MT": "Malta", "MU": "Mauritius", "MV": "Maldives",
    "MW": "Malawi", "MX": "Mexico", "MY": "Malaysia", "MZ": "Mozambique",
    "NA": "Namibia", "NC": "New Caledonia", "NE": "Niger", "NF": "Norfolk Island",
    "NG": "Nigeria", "NI": "Nicaragua", "NL": "Netherlands", "NO": "Norway",
    "NP": "Nepal", "NR": "Nauru", "NU": "Niue", "NZ": "New Zealand",
    "OM": "Oman", "PA": "Panama", "PE": "Peru", "PF": "French Polynesia",
    "PG": "Papua New Guinea", "PH": "Philippines", "PK": "Pakistan",
    "PL": "Poland", "PM": "St. Pierre and Miquelon", "PR": "Puerto Rico",
    "PS": "Palestinian Territories", "PT": "Portugal", "PW": "Palau",
    "PY": "Paraguay", "QA": "Qatar", "RE": "Reunion", "RO": "Romania",
    "RS": "Serbia", "RU": "Russia", "RW": "Rwanda", "SA": "Saudi Arabia",
    "SB": "Solomon Islands", "SC": "Seychelles", "SD": "Sudan", "SE": "Sweden",
    "SG": "Singapore", "SH": "St. Helena", "SI": "Slovenia",
    "SJ": "Svalbard and Jan Mayen", "SK": "Slovakia", "SL": "Sierra Leone",
    "SM": "San Marino", "SN": "Senegal", "SO": "Somalia", "SR": "Suriname",
    "SS": "South Sudan", "ST": "Sao Tome and Principe", "SV": "El Salvador",
    "SX": "Sint Maarten", "SY": "Syria", "SZ": "Eswatini",
    "TA": "Tristan da Cunha", "TC": "Turks and Caicos Islands", "TD": "Chad",
    "TG": "Togo", "TH": "Thailand", "TJ": "Tajikistan", "TK": "Tokelau",
    "TL": "Timor-Leste", "TM": "Turkmenistan", "TN": "Tunisia", "TO": "Tonga",
    "TR": "Turkiye", "TT": "Trinidad and Tobago", "TV": "Tuvalu", "TW": "Taiwan",
    "TZ": "Tanzania", "UA": "Ukraine", "UG": "Uganda", "US": "United States",
    "UY": "Uruguay", "UZ": "Uzbekistan", "VA": "Vatican City",
    "VC": "St. Vincent and Grenadines", "VE": "Venezuela",
    "VG": "British Virgin Islands", "VI": "U.S. Virgin Islands", "VN": "Vietnam",
    "VU": "Vanuatu", "WF": "Wallis and Futuna", "WS": "Samoa", "XK": "Kosovo",
    "YE": "Yemen", "YT": "Mayotte", "ZA": "South Africa", "ZM": "Zambia",
    "ZW": "Zimbabwe"
};

function countryName(code) {
    return _countryNames[code] || code;
}

function getCallingCode(countryCode) {
    if (!countryCode)
        return "";
    try {
        return String(LP.libphonenumber.getCountryCallingCode(countryCode));
    } catch (e) {
        return "";
    }
}

function getCountryList() {
    var list = [];
    try {
        var codes = LP.libphonenumber.getCountries();
        for (var i = 0; i < codes.length; i++) {
            var code = codes[i];
            list.push({
                code: code,
                name: countryName(code),
                callingCode: String(LP.libphonenumber.getCountryCallingCode(code))
            });
        }
    } catch (e) {
        console.warn("helpers.js: getCountryList error:", e);
    }
    list.sort(function(a, b) {
        return a.name.localeCompare(b.name);
    });
    return list;
}

// ── Example phone numbers by country ──

var _exampleNumbers = {
    "US": "(201) 555-0123", "GB": "07911 123456", "FR": "06 12 34 56 78",
    "DE": "0151 23456789", "ES": "612 34 56 78", "IT": "312 345 6789",
    "BR": "(11) 96123-4567", "MX": "55 1234 5678", "CA": "(204) 555-0123",
    "AU": "0412 345 678", "IN": "091234 56789", "JP": "090-1234-5678",
    "KR": "010-1234-5678", "CN": "131 2345 6789", "RU": "912 345-67-89",
    "NL": "06 12345678", "PL": "512 345 678", "TR": "0531 234 56 78",
    "SA": "051 234 5678", "ZA": "071 234 5678"
};

function examplePhoneNumber(countryCode) {
    return _exampleNumbers[countryCode] || "";
}

// ── Phone number formatting ──

function formatPhoneNumber(input, defaultCountry) {
    if (!input)
        return "";
    try {
        var formatter = new LP.libphonenumber.AsYouType(defaultCountry || undefined);
        return formatter.input(input);
    } catch (e) {
        return input;
    }
}

function formatPhoneNumberInternational(input, defaultCountry) {
    if (!input)
        return "";
    try {
        var parsed = LP.libphonenumber.parsePhoneNumber(input, defaultCountry || undefined);
        if (parsed)
            return parsed.formatInternational();
    } catch (e) {
        // fall through
    }
    return input;
}

function formatPhoneNumberE164(input, defaultCountry) {
    if (!input)
        return "";
    try {
        var parsed = LP.libphonenumber.parsePhoneNumber(input, defaultCountry || undefined);
        if (parsed && parsed.isValid())
            return parsed.format("E.164");
    } catch (e) {
        // fall through
    }
    return "";
}

// ── Phone number validation ──

function isValidPhoneNumber(input, defaultCountry) {
    if (!input)
        return false;
    try {
        var parsed = LP.libphonenumber.parsePhoneNumber(input, defaultCountry || undefined);
        return parsed ? parsed.isValid() : false;
    } catch (e) {
        return false;
    }
}

function isPossiblePhoneNumber(input, defaultCountry) {
    if (!input)
        return false;
    try {
        var parsed = LP.libphonenumber.parsePhoneNumber(input, defaultCountry || undefined);
        return parsed ? parsed.isPossible() : false;
    } catch (e) {
        return false;
    }
}

function detectCountry(input, defaultCountry) {
    if (!input)
        return defaultCountry || "";
    try {
        var parsed = LP.libphonenumber.parsePhoneNumber(input, defaultCountry || undefined);
        if (parsed && parsed.country)
            return parsed.country;
    } catch (e) {
        // fall through
    }
    return defaultCountry || "";
}

// ── Phone deduplication (KPeople multi-source contacts) ──

function canonicalizePhone(phone, defaultCountry) {
    if (!phone) return "";
    var raw = String(phone);
    try {
        var parsed = LP.libphonenumber.parsePhoneNumber(raw, defaultCountry || undefined);
        if (parsed && parsed.number) return parsed.number;
    } catch (e) { /* fall through */ }
    return raw.replace(/\D/g, "");
}

function phonesMatch(key1, key2) {
    if (!key1 || !key2) return false;
    if (key1 === key2) return true;
    if (key1.charAt(0) === "+" || key2.charAt(0) === "+") return false;
    if (key1.length <= 6 || key2.length <= 6) return false;
    var longer = key1.length >= key2.length ? key1 : key2;
    var shorter = key1.length < key2.length ? key1 : key2;
    return longer.endsWith(shorter);
}

// ── SMS segment counting ──

// GSM-7 basic character set (single-byte) + extension table (double-byte)
var _gsm7Single = "@£$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞ ÆæßÉ !\"#¤%&'()*+,-./0123456789:;<=>?¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà";
var _gsm7Extension = "^{}\\[~]|€";

function smsSegmentInfo(text) {
    if (!text || text.length === 0)
        return { chars: 0, segments: 0, isUnicode: false, charsPerSegment: 160 };

    // Check if all characters fit in GSM-7
    var isUnicode = false;
    var gsm7Length = 0;
    for (var i = 0; i < text.length; i++) {
        var ch = text.charAt(i);
        if (_gsm7Single.indexOf(ch) !== -1) {
            gsm7Length++;
        } else if (_gsm7Extension.indexOf(ch) !== -1) {
            gsm7Length += 2; // extension chars take 2 bytes in GSM-7
        } else {
            isUnicode = true;
            break;
        }
    }

    var chars, singleLimit, multiLimit;
    if (isUnicode) {
        chars = text.length;
        singleLimit = 70;
        multiLimit = 67;
    } else {
        chars = gsm7Length;
        singleLimit = 160;
        multiLimit = 153;
    }

    var segments;
    if (chars <= singleLimit)
        segments = chars > 0 ? 1 : 0;
    else
        segments = Math.ceil(chars / multiLimit);

    return {
        chars: chars,
        segments: segments,
        isUnicode: isUnicode,
        charsPerSegment: chars <= singleLimit ? singleLimit : multiLimit
    };
}

// ── Phone type detection from vCard ──

function phoneTypeLabel(vcard, phoneNumber) {
    if (!vcard || !phoneNumber)
        return "";
    var vcardStr = String(vcard);
    var cleanPhone = phoneNumber.replace(/[\s\-()]/g, "");
    var lines = vcardStr.split(/\r?\n/);
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        if (line.indexOf("TEL") !== 0)
            continue;
        // Extract phone value (after last colon)
        var colonIdx = line.lastIndexOf(":");
        if (colonIdx < 0) continue;
        var value = line.substring(colonIdx + 1).replace(/[\s\-()]/g, "");
        if (value !== cleanPhone)
            continue;
        // Found matching TEL line — extract TYPE parameter
        var params = line.substring(0, colonIdx).toUpperCase();
        if (params.indexOf("CELL") !== -1)
            return "mobile";
        if (params.indexOf("WORK") !== -1)
            return "work";
        if (params.indexOf("HOME") !== -1)
            return "home";
        if (params.indexOf("FAX") !== -1)
            return "fax";
        return "";
    }
    return "";
}

// ── Relative time formatting (returns raw seconds delta — formatting done in QML with i18n) ──

function relativeTimeSeconds(timestamp) {
    if (!timestamp)
        return -1;
    return Math.floor((Date.now() - timestamp) / 1000);
}

// ── Conversations (shell commands — no native QML API) ──

function buildActiveConversationsCommand(deviceId) {
    if (!deviceId) return "";
    var path = _dbusBasePath + "/devices/" + deviceId;
    return "qdbus6 --literal " + _dbusService + " " + shellEscape(path) + " org.kde.kdeconnect.device.conversations.activeConversations";
}

function countUnreadSms(qdbus6Output) {
    if (!qdbus6Output) return 0;
    var matches = qdbus6Output.match(/\}\],\s*\d+,\s*1,\s*0,/g);
    return matches ? matches.length : 0;
}

// ── Contacts (shell command — no native QML API) ──

function buildSyncContactsCommand(deviceId) {
    if (!deviceId)
        return "";
    var path = _dbusBasePath + "/devices/" + deviceId + "/contacts";
    var iface = _dbusService + ".device.contacts.synchronizeRemoteWithLocal";
    return "qdbus6 " + _dbusService + " " + shellEscape(path) + " " + iface;
}
