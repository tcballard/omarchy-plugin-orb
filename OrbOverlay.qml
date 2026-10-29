import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Based on Omarchy's MIT-licensed OverlayWindow (57e4d3d12).
// Keep this local: Omarchy 4.0.6 exports PanelWindow but not OverlayWindow.
PanelWindow {
    id: window
    property bool shown: false
    property int shownKeyboardFocus: WlrKeyboardFocus.Exclusive
    property var targetScreen: null
    property bool respectReserved: false
    property string requestedScreen: ""
    property bool preferPointerScreen: false
    property point openingPointer: Qt.point(0, 0)
    readonly property var targetMonitor: {
        var monitors = Hyprland.monitors.values;
        for (var i = 0; i < monitors.length; i++)
            if (targetScreen && monitors[i].name === targetScreen.name) return monitors[i];
        return null;
    }
    // Do not reveal an opening frame until fullscreen geometry and output
    // scale agree. Fractional scales are expressed in units of 1/120.
    readonly property bool contentReady: shown && backingWindowVisible && !!targetScreen
        && (respectReserved ? (width > 0 && height > 0 && width <= targetScreen.width && height <= targetScreen.height)
            : width === targetScreen.width && height === targetScreen.height)
        && !!targetMonitor && Math.round(devicePixelRatio * 120) === Math.round(targetMonitor.scale * 120)
    property bool contentRevealed: false
    onContentReadyChanged: {
        contentRevealed = false;
        if (contentReady) Qt.callLater(function() { if (window.contentReady) window.contentRevealed = true; });
    }
    function requestedOutput() {
        for (var i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === requestedScreen) return Quickshell.screens[i];
        return null;
    }
    function focusedScreen() {
        var monitor = Hyprland.focusedMonitor, name = monitor ? String(monitor.name || "") : "";
        for (var i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === name) return Quickshell.screens[i];
        return Quickshell.screens.length ? Quickshell.screens[0] : null;
    }
    function screenAtPointer(point) {
        var monitors = Hyprland.monitors.values;
        for (var i = 0; i < monitors.length; i++) {
            var data = monitors[i].lastIpcObject || ({});
            for (var j = 0; j < Quickshell.screens.length; j++) {
                var candidate = Quickshell.screens[j];
                if (candidate.name !== monitors[i].name || !isFinite(data.x) || !isFinite(data.y)) continue;
                if (point.x >= data.x && point.x < data.x + candidate.width
                    && point.y >= data.y && point.y < data.y + candidate.height) return candidate;
            }
        }
        return null;
    }
    // Freeze the selected screen for this opening. A focus change must not
    // combine one screen's coordinates with another monitor's reserved area.
    onShownChanged: {
        targetScreen = shown ? (requestedOutput() || (preferPointerScreen && screenAtPointer(openingPointer)) || focusedScreen()) : null;
        if (shown) Hyprland.refreshMonitors();
    }
    onDevicePixelRatioChanged: if (shown) Hyprland.refreshMonitors()
    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (window.shown && Quickshell.screens.indexOf(window.targetScreen) < 0) {
                window.targetScreen = null;
                Qt.callLater(function() {
                    if (window.shown && !window.targetScreen) window.targetScreen = window.focusedScreen();
                });
            }
        }
    }
    visible: shown && !!targetScreen && !!targetMonitor
    screen: targetScreen
    anchors { top: true; left: true; bottom: true; right: true }
    color: "transparent"
    exclusionMode: respectReserved ? ExclusionMode.Normal : ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? shownKeyboardFocus : WlrKeyboardFocus.None
    Binding { target: window.contentItem; property: "opacity"; value: window.contentRevealed ? 1 : 0 }
    Binding { target: window.contentItem; property: "LayoutMirroring.enabled"; value: Qt.application.layoutDirection === Qt.RightToLeft }
    Binding { target: window.contentItem; property: "LayoutMirroring.childrenInherit"; value: true }
}
