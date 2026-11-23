pragma Singleton
import QtQuick

QtObject {
    readonly property var screens: [{name:"eDP-1"}]
    property var detached: []
    function execDetached(command) { detached = detached.concat([command]); }
}
