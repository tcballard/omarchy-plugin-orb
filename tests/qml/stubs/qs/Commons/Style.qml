pragma Singleton
import QtQuick
QtObject {
    readonly property var font: ({family:"sans-serif",menuFamily:"sans-serif"})
    readonly property int cornerRadius: 0
    function space(value) { return value; }
}
