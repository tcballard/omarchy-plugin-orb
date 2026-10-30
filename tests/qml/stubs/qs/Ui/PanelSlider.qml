import QtQuick

Item {
    property real minimum: 0
    property real maximum: 1
    property real step: 0.05
    property real value: 0
    property bool integer: false
    property color trackColor: "gray"
    property color fillColor: "white"
    property color knobColor: "white"
    signal moved(real value)
}
