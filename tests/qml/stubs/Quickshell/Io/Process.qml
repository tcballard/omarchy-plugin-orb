import QtQuick
QtObject {
    property var command: []
    property bool running: false
    property QtObject stdout: null
    signal exited(int code, int status)
}
