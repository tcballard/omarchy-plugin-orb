import QtQuick
import QtQuick.Controls as Controls
import qs.Commons as Commons
import "TouchModel.js" as TouchModel

Item {
    id: wheel
    property var actions: []
    property var iconSources: []
    property string edge: "right"
    property string shape: "fan"
    property real targetScale: 1
    property bool dragSelection: false
    property var interaction: null
    readonly property var geometry: TouchModel.layout(width, height, actions.length, edge, shape, targetScale)
    signal activated(int index)
    signal edited(int index)
    signal canceled()

    function press(x, y) { interaction = TouchModel.press(x, y, geometry); hold.restart(); }
    function move(x, y) { interaction = TouchModel.move(interaction, x, y, geometry); if (interaction && interaction.moved) hold.stop(); }
    function release(x, y) {
        hold.stop();
        var selection = TouchModel.release(interaction, x, y, geometry, dragSelection);
        interaction = null;
        if (selection >= 0) activated(selection);
    }
    function cancel() { hold.stop(); interaction = null; }
    onVisibleChanged: if (!visible) cancel()
    onGeometryChanged: cancel()
    Timer {
        id: hold; interval: 550
        onTriggered: {
            if (wheel.interaction && !wheel.interaction.moved && wheel.interaction.first >= 0) {
                var index = wheel.interaction.first;
                wheel.interaction = Object.assign({}, wheel.interaction, { held: true });
                wheel.edited(index);
            }
        }
    }
    Repeater {
        model: wheel.geometry.grid ? [] : wheel.actions
        delegate: Rectangle {
            required property int index
            required property var modelData
            readonly property bool chosen: wheel.interaction && wheel.interaction.selected === index
            x: wheel.geometry.points[index].x - width / 2; y: wheel.geometry.points[index].y - height / 2
            width: wheel.geometry.size; height: width
            radius: Commons.Style.cornerRadius
            color: chosen || activeFocus ? Commons.Color.menu.selectedBackground : Commons.Color.menu.background
            border.width: chosen || activeFocus ? 2 : 1
            border.color: chosen || activeFocus ? Commons.Color.menu.selectedBorder : Commons.Util.alpha(Commons.Color.menu.text, 0.35)
            activeFocusOnTab: true
            Accessible.role: Accessible.Button; Accessible.name: modelData.label
            Accessible.onPressAction: wheel.activated(index)
            Keys.onReturnPressed: wheel.activated(index)
            Keys.onSpacePressed: wheel.activated(index)
            ActionIcon {
                anchors.horizontalCenter: parent.horizontalCenter; y: 10
                width: 30 * wheel.targetScale; height: width
                name: modelData.icon; appSource: wheel.iconSources[index] || ""; selected: parent.chosen
                ink: Commons.Color.menu.text
            }
            Text {
                x: 4; width: parent.width - 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                text: modelData.label; textFormat: Text.PlainText; elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter; font.pixelSize: 12 * wheel.targetScale
                font.family: Commons.Style.font.menuFamily; color: Commons.Color.menu.text
            }
        }
    }
    MouseArea {
        anchors.fill: parent; enabled: !wheel.geometry.grid; acceptedButtons: Qt.LeftButton
        onPressed: mouse => wheel.press(mouse.x, mouse.y)
        onPositionChanged: mouse => { if (pressed) wheel.move(mouse.x, mouse.y); }
        onReleased: mouse => wheel.release(mouse.x, mouse.y)
        onCanceled: wheel.cancel()
    }
    MultiPointTouchArea {
        anchors.fill: parent; enabled: !wheel.geometry.grid; minimumTouchPoints: 1; maximumTouchPoints: 1; mouseEnabled: false
        onPressed: points => { if (points.length) wheel.press(points[0].x, points[0].y); }
        onUpdated: points => { if (points.length) wheel.move(points[0].x, points[0].y); }
        onReleased: points => { if (points.length) wheel.release(points[0].x, points[0].y); }
        onCanceled: wheel.cancel()
    }
    GridView {
        anchors.fill: parent; visible: wheel.geometry.grid; clip: true
        cellWidth: Math.max(96, width / Math.max(1, Math.floor(width / 112))); cellHeight: 104 * wheel.targetScale
        model: visible ? wheel.actions : []; boundsBehavior: Flickable.StopAtBounds
        delegate: Item {
            required property int index
            required property var modelData
            width: GridView.view.cellWidth; height: GridView.view.cellHeight
            Rectangle {
                x: 5; y: 5; width: parent.width - 10; height: parent.height - 10
                radius: Commons.Style.cornerRadius
                color: gridPointer.pressed ? Commons.Color.menu.selectedBackground : Commons.Color.menu.background
                border.width: 1; border.color: Commons.Util.alpha(Commons.Color.menu.text, 0.35)
                Accessible.role: Accessible.Button; Accessible.name: modelData.label
                Accessible.onPressAction: wheel.activated(index)
                activeFocusOnTab: true
                Keys.onReturnPressed: wheel.activated(index)
                Keys.onSpacePressed: wheel.activated(index)
                ActionIcon {
                    anchors.horizontalCenter: parent.horizontalCenter; y: 12
                    width: 30 * wheel.targetScale; height: width
                    name: modelData.icon; appSource: wheel.iconSources[index] || ""; ink: Commons.Color.menu.text
                }
                Text {
                    x: 4; width: parent.width - 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                    text: modelData.label; textFormat: Text.PlainText; elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter; font.pixelSize: 12 * wheel.targetScale
                    font.family: Commons.Style.font.menuFamily; color: Commons.Color.menu.text
                }
                MouseArea {
                    id: gridPointer; anchors.fill: parent; acceptedButtons: Qt.LeftButton
                    property bool held: false
                    onPressed: held = false
                    onPressAndHold: { held = true; wheel.edited(index); }
                    onClicked: if (!held) wheel.activated(index)
                }
            }
        }
        Controls.ScrollBar.vertical: Controls.ScrollBar {}
    }
}
