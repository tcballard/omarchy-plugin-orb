import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons as Commons

PanelWindow {
    id: handle
    property bool handleEnabled: false
    property var targetScreen: null
    property string edge: "right"
    property real position: 0.7
    property real targetScale: 1
    property real livePosition: position
    property var reserved: [0, 0, 0, 0]
    readonly property real travel: Math.max(1, (targetScreen ? targetScreen.height : 0) - height - reserved[1] - reserved[3] - 16)
    signal summoned(string output)
    signal repositioned(real value)
    screen: targetScreen
    visible: handleEnabled && !!targetScreen
    implicitWidth: Math.max(56, Math.round(56 * targetScale))
    implicitHeight: implicitWidth
    color: "transparent"
    anchors.top: true
    anchors.left: edge === "left"
    anchors.right: edge === "right"
    margins.top: 8 + Math.round(travel * livePosition)
    margins.left: 6
    margins.right: 6
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "omarchy-orb-touch-handle"
    onPositionChanged: if (!pointer.pressed) livePosition = position
    Rectangle {
        anchors.fill: parent; radius: Commons.Style.cornerRadius
        color: pointer.pressed ? Commons.Color.menu.selectedBackground : Commons.Color.menu.background
        border.width: 2; border.color: Commons.Color.menu.selectedBorder
        Text {
            anchors.centerIn: parent; text: "Orb"; textFormat: Text.PlainText
            color: Commons.Color.menu.text; font.family: Commons.Style.font.menuFamily
            font.pixelSize: 16 * handle.targetScale; font.weight: Font.DemiBold
        }
        Accessible.role: Accessible.Button
        Accessible.name: "Open Orb. Drag up or down to move."
        Accessible.onPressAction: handle.summoned(handle.targetScreen.name)
        MouseArea {
            id: pointer; anchors.fill: parent; acceptedButtons: Qt.LeftButton
            property real initialY: 0
            property real initialPosition: 0
            property bool moved: false
            onPressed: mouse => { initialY = mapToGlobal(mouse.x, mouse.y).y; initialPosition = handle.livePosition; moved = false; }
            onPositionChanged: mouse => {
                if (!pressed) return;
                var delta = mapToGlobal(mouse.x, mouse.y).y - initialY;
                if (Math.abs(delta) > 10) moved = true;
                if (moved) handle.livePosition = Math.max(0, Math.min(1, initialPosition + delta / handle.travel));
            }
            onReleased: {
                if (moved) handle.repositioned(handle.livePosition);
                else handle.summoned(handle.targetScreen.name);
            }
            onCanceled: handle.livePosition = handle.position
        }
    }
}
