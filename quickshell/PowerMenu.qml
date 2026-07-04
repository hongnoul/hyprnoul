// Liquid glass power-profile picker, opened from the waybar battery icon via
// `qs ipc call power toggle`. Same tint recipe as the OSD/rofi — charcoal
// rgba(22,22,30,22%) at radius 26 — with the glass itself rendered by
// HyprGlass keyed on the "qs-power" layer namespace. Show/hide is Hyprland's
// layer "popin" (power-glass rule); no QML opacity animation, same
// double-fade caveat as the OSD.
//
// Profile state is live D-Bus via Quickshell.Services.UPower, so the
// highlight tracks changes made elsewhere (powerprofilesctl, GNOME, etc.).

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland

PanelWindow {
    id: win

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-power"
    // Exclusive, not OnDemand: the menu opens via IPC so no click ever lands
    // on the surface to hand it focus, and Escape must still work.
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive
                                         : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors.bottom: true
    anchors.right: true
    margins.bottom: 36 // bar (28) + gap — battery sits second from the right
    margins.right: 10
    implicitWidth: 200
    implicitHeight: 3 * 36 + 2 * 2 + 2 * 10 // rows + spacing + padding

    readonly property color fg: Qt.rgba(235 / 255, 240 / 255, 255 / 255, 0.92)

    readonly property var entries: [
        { p: PowerProfile.Performance, label: "Performance", icon: "\u{f04c5}" }, // 󰓅
        { p: PowerProfile.Balanced,    label: "Balanced",    icon: "\u{f0f85}" }, // 󰾅
        { p: PowerProfile.PowerSaver,  label: "Power Saver", icon: "\u{f0f86}" }, // 󰾆
    ]

    property double lastDismiss: 0

    function toggle() {
        if (visible) {
            visible = false;
            return;
        }
        // A battery re-click lands right after the focus grab already
        // dismissed us; without this guard it would instantly reopen.
        if (Date.now() - lastDismiss < 200)
            return;
        visible = true;
    }

    HyprlandFocusGrab {
        windows: [win]
        active: win.visible
        onCleared: {
            win.lastDismiss = Date.now();
            win.visible = false;
        }
    }

    Rectangle { // glass tint only — HyprGlass renders the glass itself
        anchors.fill: parent
        radius: 26
        color: Qt.rgba(22 / 255, 22 / 255, 30 / 255, 0.22)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 2
            focus: true
            Keys.onEscapePressed: win.visible = false

            Repeater {
                model: win.entries

                Rectangle { // profile row
                    id: row

                    required property var modelData
                    readonly property bool current:
                        PowerProfiles.profile === modelData.p

                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 12
                    color: current ? Qt.rgba(1, 1, 1, 0.14)
                         : mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07)
                         : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            Layout.preferredWidth: 20
                            horizontalAlignment: Text.AlignHCenter
                            color: win.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            text: row.modelData.icon
                        }

                        Text {
                            Layout.fillWidth: true
                            color: win.fg
                            font.family: "Adwaita Sans"
                            font.weight: Font.Medium
                            font.pixelSize: 13
                            text: row.modelData.label
                        }

                        Text {
                            visible: row.current
                            color: win.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            text: "\u{f012c}" // 󰄬
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            PowerProfiles.profile = row.modelData.p;
                            win.visible = false;
                        }
                    }
                }
            }
        }
    }
}
