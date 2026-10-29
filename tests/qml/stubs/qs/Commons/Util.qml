pragma Singleton
import QtQuick
QtObject {
    function alpha(color, opacity) { var c = Qt.color(color); return Qt.rgba(c.r, c.g, c.b, opacity); }
}
