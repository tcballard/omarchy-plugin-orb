import QtQuick
QtObject {
    property var command: []
    property bool running: false
    property QtObject stdout: null
    property QtObject stderr: null
    signal exited(int code, int status)
}
