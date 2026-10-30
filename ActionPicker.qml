import QtQuick
import QtQuick.Controls as Controls
import qs.Commons as Commons
import qs.Ui

FocusScope {
    id: picker
    property var choices: []
    property int depth: 0
    property bool busy: false
    property bool draggable: false
    property Item dragSurface: null
    property string controlPrefix: "orb-catalog-"
    property real listHeight: Commons.Style.space(252)
    property int cursor: 0
    property bool dragging: false
    property int dragIndex: -1
    property var dragChoice: null
    readonly property var filteredChoices: choices.filter(function(row) {
        return (!picker.depth || (!row.action.children && !row.action.menu))
            && (row.title + " " + row.detail).toLowerCase().indexOf(search.text.trim().toLowerCase()) >= 0;
    })
    implicitHeight: content.height
    height: implicitHeight
    signal chosen(var action)
    signal dragMoved(var action, string iconSource, real x, real y)
    signal dragFinished(var action, real x, real y)
    signal dragCanceled()

    function reset() { cancelDrag(); search.text = ""; cursor = 0; list.positionViewAtBeginning(); }
    function focusSearch() { search.forceActiveFocus(); }
    function titles() { return filteredChoices.map(function(row) { return row.title; }); }
    function choose(index) {
        if (busy || index < 0 || index >= filteredChoices.length) return;
        chosen(JSON.parse(JSON.stringify(filteredChoices[index].action)));
    }
    function moveCursor(delta) {
        if (!filteredChoices.length) return;
        cursor = (cursor + delta + filteredChoices.length) % filteredChoices.length;
        list.positionViewAtIndex(cursor, ListView.Contain);
    }
    function cancelDrag() {
        var active = dragging;
        dragging = false; dragIndex = -1; dragChoice = null;
        if (active) dragCanceled();
    }
    onVisibleChanged: if (!visible) cancelDrag()
    onBusyChanged: if (busy) cancelDrag()
    Column {
        id: content
        width: parent.width; spacing: Commons.Style.space(8)
        TextField {
            id: search
            objectName: picker.controlPrefix + "search"
            width: parent.width; placeholderText: "Search apps and shortcuts…"; enabled: !picker.busy
            onTextChanged: { picker.cancelDrag(); picker.cursor = 0; list.positionViewAtBeginning(); }
            Keys.onDownPressed: picker.moveCursor(1)
            Keys.onUpPressed: picker.moveCursor(-1)
            Keys.onReturnPressed: event => { event.accepted = true; Qt.callLater(function() { picker.choose(picker.cursor); }); }
            Keys.onEnterPressed: event => { event.accepted = true; Qt.callLater(function() { picker.choose(picker.cursor); }); }
        }
        ListView {
            id: list
            width: parent.width; height: picker.listHeight
            clip: true; spacing: Commons.Style.space(4); boundsBehavior: Flickable.StopAtBounds
            model: picker.filteredChoices
            WheelHandler {
                target: null
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    var delta = event.pixelDelta.y || event.angleDelta.y / 120 * Commons.Style.space(44);
                    list.contentY = Math.max(0, Math.min(list.contentHeight - list.height, list.contentY - delta));
                    event.accepted = true;
                }
            }
            Controls.ScrollBar.vertical: Controls.ScrollBar {
                id: scrollBar
                objectName: picker.controlPrefix + "scrollbar"
                width: Commons.Style.space(10); padding: Commons.Style.space(2)
                policy: list.contentHeight > list.height + 1 ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff
                minimumSize: Math.min(1, Commons.Style.space(28) / Math.max(1, height))
                contentItem: Rectangle {
                    implicitWidth: Commons.Style.space(4); implicitHeight: Commons.Style.space(28)
                    radius: width / 2; color: Commons.Util.alpha(Commons.Color.menu.text, 0.45)
                }
            }
            delegate: EditorButton {
                id: row
                required property int index
                required property var modelData
                objectName: picker.controlPrefix + "choice-" + index
                x: scrollBar.mirrored ? scrollBar.width + Commons.Style.space(4) : 0
                width: Math.max(0, list.width - scrollBar.width - Commons.Style.space(4)); height: Commons.Style.space(44)
                text: modelData.title; leftAlign: true; leftPadding: Commons.Style.space(44)
                selected: index === picker.cursor; enabled: !picker.busy
                hasCursor: dragPointer.containsMouse
                opacity: picker.dragging && picker.dragIndex === index ? 0.45 : 1
                tooltipText: modelData.detail
                ActionIcon {
                    x: Commons.Style.space(10); anchors.verticalCenter: parent.verticalCenter
                    width: Commons.Style.space(22); height: width
                    name: row.modelData.action.icon; appSource: row.modelData.iconSource || ""; selected: row.index === picker.cursor
                }
                onClicked: picker.choose(index)
                MouseArea {
                    id: dragPointer
                    anchors.fill: parent; z: 1
                    enabled: picker.draggable && !picker.busy
                    hoverEnabled: true; preventStealing: true
                    cursorShape: picker.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    property point pressPoint: Qt.point(0, 0)
                    onPressed: mouse => {
                        pressPoint = Qt.point(mouse.x, mouse.y);
                        picker.dragChoice = row.modelData; picker.dragIndex = row.index; picker.cursor = row.index;
                        row.forceActiveFocus();
                    }
                    onPositionChanged: mouse => {
                        if (!pressed || !picker.dragChoice || !picker.dragSurface) return;
                        if (Math.hypot(mouse.x - pressPoint.x, mouse.y - pressPoint.y) > Commons.Style.space(7)) picker.dragging = true;
                        if (picker.dragging) {
                            var point = mapToItem(picker.dragSurface, mouse.x, mouse.y);
                            picker.dragMoved(picker.dragChoice.action, picker.dragChoice.iconSource || "", point.x, point.y);
                        }
                    }
                    onReleased: mouse => {
                        var choice = picker.dragChoice, dragged = picker.dragging;
                        picker.dragging = false; picker.dragIndex = -1; picker.dragChoice = null;
                        if (dragged && choice && picker.dragSurface) {
                            var point = mapToItem(picker.dragSurface, mouse.x, mouse.y);
                            picker.dragFinished(choice.action, point.x, point.y);
                        } else picker.choose(row.index);
                    }
                    onCanceled: picker.cancelDrag()
                }
            }
            EditorLabel { anchors.centerIn: parent; visible: list.count === 0; text: "No matching apps or shortcuts" }
        }
    }
}
