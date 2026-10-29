import QtQuick
import QtQuick.Controls as Controls

Controls.Button {
    property bool focusable: false
    property bool bordered: false
    property bool selected: false
    property bool leftAlign: false
    property color foreground: "white"
    property string fontFamily: "sans-serif"
    property real fontSize: 14
    font.family: fontFamily
    font.pixelSize: fontSize
    focusPolicy: focusable ? Qt.StrongFocus : Qt.NoFocus
}
