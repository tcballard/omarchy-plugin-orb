pragma Singleton
import QtQuick
QtObject {
    function alpha(color: color, opacity: real): color { return Qt.rgba(color.r, color.g, color.b, opacity); }
}
