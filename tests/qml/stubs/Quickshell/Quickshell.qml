pragma Singleton
import QtQuick

QtObject {
    readonly property var screens: [{name:"eDP-1"}]
    property var detached: []
    property var environment: ({})
    function env(name) { return environment[name] || ""; }
    function execDetached(command) { detached = detached.concat([command]); }
}
