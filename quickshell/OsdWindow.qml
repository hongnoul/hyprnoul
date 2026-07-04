// The glass pill. Tint values are a faithful copy of rofi/config.rasi —
// charcoal rgba(22,22,30,22%) at radius 26, foreground rgba(235,240,255,92%),
// panes of low-alpha white. The window surface outside the pill is fully
// transparent, which HyprGlass skips, so the radii stay crisp.
//
// Only the slider animates here. Show/hide is Hyprland's layer "fade" (see
// the osd-glass layer rule); animating opacity in QML too would double-fade
// the partial-alpha mask the glass keys on.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors.bottom: true // only-bottom anchor => horizontally centered
    margins.bottom: 52   // where swayosd sat (720 − 606 − 62)
    implicitWidth: 260
    implicitHeight: 58

    property string mode: "volume" // "volume" | "brightness" | "mic"
    property real value: 0         // slider target, 0..1
    property bool muted: false

    readonly property color fg: Qt.rgba(235 / 255, 240 / 255, 255 / 255, 0.92)

    function show(newMode, newValue, newMuted) {
        // Switching volume<->brightness must not slide between unrelated
        // scales; suppress the animation for that one retarget.
        fill.animate = (newMode === mode);
        mode = newMode;
        value = newValue;
        muted = newMuted;
        fill.animate = true;
        visible = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: win.visible = false
    }

    Rectangle { // glass tint only — HyprGlass renders the glass itself
        anchors.fill: parent
        radius: 26
        color: Qt.rgba(22 / 255, 22 / 255, 30 / 255, 0.22)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 12

            Text {
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignHCenter
                color: win.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 20
                text: {
                    if (win.mode === "brightness")
                        return win.value > 0.5 ? "\u{f00e0}" : "\u{f00de}"; // 󰃠 󰃞
                    if (win.mode === "mic")
                        return win.muted ? "\u{f036d}" : "\u{f036c}";      // 󰍭 󰍬
                    if (win.muted) return "\u{f075f}";                     // 󰝟
                    if (win.value < 0.34) return "\u{f057f}";              // 󰕿
                    if (win.value < 0.67) return "\u{f0580}";              // 󰖀
                    return "\u{f057e}";                                    // 󰕾
                }
            }

            Rectangle { // trough
                id: trough
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                height: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.07)

                Rectangle { // fill eases toward the latest target — no queue
                    id: fill
                    property bool animate: true
                    height: parent.height
                    radius: 3
                    color: win.fg
                    opacity: win.muted ? 0.4 : 1
                    width: parent.width * Math.min(1, Math.max(0, win.value))

                    Behavior on width {
                        enabled: fill.animate
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
            }

            Text { // label shows the target instantly while the bar eases
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                color: win.fg
                font.family: "Adwaita Sans"
                font.weight: Font.Medium
                font.pixelSize: 13
                text: win.mode === "mic"
                    ? (win.muted ? "off" : "on")
                    : Math.round(win.value * 100) + "%"
            }
        }
    }
}
