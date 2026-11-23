import QtQuick
import qs.Commons as Commons
import "Model.js" as Model

Item {
    id: preview
    property var actions: []
    property string shape: "circle"
    property var iconSources: []
    property int selected: 0
    property bool busy: false
    property int dragFrom: -1
    property int dragTo: -1
    property bool dragging: false
    property var assignmentAction: null
    property int assignmentTarget: -1
    property point pressPoint: Qt.point(0, 0)
    signal picked(int index)
    signal moved(int from, int to)
    signal assigned(int index, var action)
    function hoverAssignment(action, x, y) {
        assignmentAction = action;
        assignmentTarget = Model.hit(x, y, width, actions.length, shape);
    }
    function cancelAssignment() {
        assignmentAction = null;
        assignmentTarget = -1;
    }
    function dropAssignment(action, x, y) {
        var index = Model.hit(x, y, width, actions.length, shape);
        cancelAssignment();
        if (!busy && index >= 0)
            assigned(index, action);
    }
    readonly property int highlighted: assignmentAction ? assignmentTarget : dragging ? dragTo : pointer.containsMouse
                                                                                        ? Model.hit(pointer.mouseX,
                                                                                                    pointer.mouseY,
                                                                                                    width, actions.length,
                                                                                                    shape) : selected
    readonly property string caption: assignmentAction ? (assignmentTarget < 0
                                                          ? "Drop on a slot · release outside to cancel" :
                                                            "Replace slot " + (assignmentTarget + 1) + " with "
                                                            + assignmentAction.label) : dragging ? (dragTo < 0
                                                                                                    ? "Release outside to cancel" :
                                                                                                      "Move " + actions[dragFrom].label
                                                                                                      + " to slot " + (
                                                                                                          dragTo + 1)) :
                                                                                                   highlighted >= 0
                                                                                                   && highlighted
                                                                                                   < actions.length
                                                                                                   ? actions[highlighted].label :
                                                                                                     "Click to edit · drag to arrange"
    height: width

    WheelSurface {
        anchors.fill: parent
        shape: preview.shape
        count: preview.actions.length
        selection: preview.highlighted
    }
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.32
        height: width
        radius: width / 2
        color: Commons.Color.menu.background
        border.width: 1
        border.color: Commons.Util.alpha(Commons.Color.menu.text, 0.18)
    }
    Repeater {
        model: preview.actions
        delegate: Item {
            required property int index
            required property var modelData
            readonly property real angle: (index * 360 / preview.actions.length - 90) * Math.PI / 180
            width: preview.width * 0.18
            height: width
            x: preview.width / 2 + Math.cos(angle) * preview.width * 0.33 - width / 2
            y: preview.height / 2 + Math.sin(angle) * preview.width * 0.33 - height / 2
            opacity: preview.dragging && preview.dragFrom === index ? 0.3 : 1
            ActionIcon {
                anchors.centerIn: parent
                width: preview.width * 0.085
                height: width
                name: modelData.icon
                appSource: preview.iconSources[index] || ""
                selected: preview.highlighted === index
            }
            EditorLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                text: String(index + 1)
                font.pixelSize: Commons.Style.space(9)
                color: Commons.Util.alpha(Commons.Color.menu.text, 0.65)
            }
        }
    }
    Image {
        anchors.centerIn: parent
        width: parent.width * 0.18
        height: width
        source: Qt.resolvedUrl("assets/omarchy-logo.svg")
        fillMode: Image.PreserveAspectFit
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: !preview.busy
        hoverEnabled: true
        preventStealing: true
        cursorShape: preview.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        onPressed: mouse => {
            preview.dragFrom = Model.hit(mouse.x, mouse.y, width, preview.actions.length, preview.shape);
            preview.pressPoint = Qt.point(mouse.x, mouse.y);
            preview.dragging = false;
            preview.dragTo = preview.dragFrom;
        }
        onPositionChanged: mouse => {
            if (!pressed || preview.dragFrom < 0)
                return;
            if (Math.hypot(mouse.x - preview.pressPoint.x, mouse.y - preview.pressPoint.y) > Commons.Style.space(7))
                preview.dragging = true;
            preview.dragTo = Model.hit(mouse.x, mouse.y, width, preview.actions.length, preview.shape);
        }
        onReleased: mouse => {
            var target = Model.hit(mouse.x, mouse.y, width, preview.actions.length, preview.shape);
            if (preview.dragging && target >= 0 && target !== preview.dragFrom)
                preview.moved(preview.dragFrom, target);
            else if (!preview.dragging && preview.dragFrom >= 0 && target === preview.dragFrom)
                preview.picked(target);
            preview.dragging = false;
            preview.dragFrom = -1;
            preview.dragTo = -1;
        }
        onCanceled: {
            preview.dragging = false;
            preview.dragFrom = -1;
            preview.dragTo = -1;
        }
    }
    ActionIcon {
        visible: preview.dragging && preview.dragFrom >= 0
        x: pointer.mouseX - width / 2
        y: pointer.mouseY - height / 2
        width: preview.width * 0.11
        height: width
        name: preview.dragFrom >= 0 ? preview.actions[preview.dragFrom].icon : "app"
        appSource: preview.iconSources[preview.dragFrom] || ""
    }
}
