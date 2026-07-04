// Liquid glass volume/brightness OSD (replaces swayosd).
//
// Volume/mic: keybinds in hyprland.lua set levels natively via wpctl; this
// shell watches PipeWire and shows the OSD on any sink/source change (so
// waybar scrolls and headphone buttons trigger it too). Brightness has no
// PipeWire equivalent: its binds run brightnessctl, then `qs ipc call osd
// brightness` to make us re-read sysfs (inotify doesn't work there).
//
// The OSD window paints only the glass *tint*; refraction/blur/specular come
// from the HyprGlass plugin keyed on the "qs-osd" layer namespace (see the
// PLUGINS section of hyprland.lua).

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

ShellRoot {
    id: root

    // Bind the default nodes so their .audio properties populate.
    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink, Pipewire.defaultAudioSource ]
    }

    OsdWindow { id: osd }

    // Baseline guards: snapshot levels when a node becomes ready (startup and
    // default-device switches) so those transitions never flash the OSD, and
    // the first real keypress isn't mistaken for the initial sync.
    property real lastSinkVolume: -1
    property bool lastSinkMuted: false
    property bool sourceSynced: false
    property bool lastSourceMuted: false

    function syncSink() {
        const sink = Pipewire.defaultAudioSink;
        if (sink?.ready && sink.audio) {
            lastSinkVolume = sink.audio.volume;
            lastSinkMuted = sink.audio.muted;
        }
    }

    function syncSource() {
        const source = Pipewire.defaultAudioSource;
        if (source?.ready && source.audio) {
            sourceSynced = true;
            lastSourceMuted = source.audio.muted;
        }
    }

    Component.onCompleted: { syncSink(); syncSource(); }

    Connections {
        target: Pipewire.defaultAudioSink
        function onReadyChanged() { root.syncSink(); }
    }

    Connections {
        target: Pipewire.defaultAudioSource
        function onReadyChanged() { root.syncSource(); }
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null

        function onVolumesChanged() {  // "volume" notifies via volumesChanged
            const audio = Pipewire.defaultAudioSink.audio;
            if (root.lastSinkVolume < 0) {
                root.lastSinkVolume = audio.volume;
                root.lastSinkMuted = audio.muted;
                return;
            }
            if (audio.volume === root.lastSinkVolume) return;
            root.lastSinkVolume = audio.volume;
            osd.show("volume", audio.volume, audio.muted);
        }

        function onMutedChanged() {
            const audio = Pipewire.defaultAudioSink.audio;
            if (root.lastSinkVolume < 0) return; // pre-sync
            if (audio.muted === root.lastSinkMuted) return;
            root.lastSinkMuted = audio.muted;
            osd.show("volume", audio.volume, audio.muted);
        }
    }

    Connections {
        target: Pipewire.defaultAudioSource?.audio ?? null

        function onMutedChanged() {
            const audio = Pipewire.defaultAudioSource.audio;
            if (!root.sourceSynced) {
                root.sourceSynced = true;
                root.lastSourceMuted = audio.muted;
                return;
            }
            if (audio.muted === root.lastSourceMuted) return;
            root.lastSourceMuted = audio.muted;
            osd.show("mic", audio.muted ? 0 : 1, audio.muted);
        }
    }

    // Device switches re-sync silently.
    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() {
            root.lastSinkVolume = -1;
            root.syncSink();
        }
        function onDefaultAudioSourceChanged() {
            root.sourceSynced = false;
            root.syncSource();
        }
    }

    // Brightness: read on demand, triggered over IPC by the keybinds.
    // Synchronous reads — sysfs is instant and `loaded` doesn't re-fire on
    // reload() of an unloaded view.
    FileView {
        id: maxBrightness
        path: "/sys/class/backlight/intel_backlight/max_brightness"
        blockLoading: true
    }

    FileView {
        id: curBrightness
        path: "/sys/class/backlight/intel_backlight/brightness"
        preload: false
        blockLoading: true
    }

    IpcHandler {
        target: "osd"
        function brightness(): void {
            curBrightness.reload();
            curBrightness.waitForJob();
            const max = parseInt(maxBrightness.text());
            if (max > 0)
                osd.show("brightness", parseInt(curBrightness.text()) / max, false);
        }
    }
}
