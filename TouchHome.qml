import QtQuick
import QtQuick.Controls as Controls
import qs.Commons as Commons
import qs.Ui

FocusScope {
    id: home
    property var controller: null
    property var backend: null
    property string screenName: ""
    property string page: "home"
    property string query: ""
    property string movingWindow: ""
    property var appRows: []
    property string pendingClose: ""
    readonly property var config: controller ? controller.config : ({})
    readonly property bool narrow: width < 560
    signal dismissed()
    signal settingsRequested(int slot)

    function reset() { page = "home"; query = ""; movingWindow = ""; pendingClose = ""; refreshApps(); }
    function refreshApps() {
        if (!controller || !controller.appLibrary) { appRows = []; return; }
        appRows = controller.appLibrary.sortedEntries(query).slice(0, 1000);
    }
    function changePage(next) { page = next; movingWindow = ""; pendingClose = ""; if (next === "apps") refreshApps(); }
    function back() {
        if (pendingClose) pendingClose = "";
        else if (movingWindow) movingWindow = "";
        else if (controller && controller.submenuTitle) controller.back();
        else if (page !== "home") changePage("home");
        else dismissed();
    }
    function action(args, closeAfter) {
        if (!backend) return;
        pendingClose = "";
        if (backend.run(args)) controller.touchDismissAfter = closeAfter === true;
    }
    onQueryChanged: refreshApps()
    Keys.onEscapePressed: event => { back(); event.accepted = true; }
    Rectangle { anchors.fill: parent; radius: Commons.Style.cornerRadius; color: Commons.Color.menu.background; border.color: Commons.Util.alpha(Commons.Color.menu.text, 0.25); border.width: 1 }
    Column {
        id: header
        x: 12; y: 12; width: parent.width - 24; spacing: 10
        Row {
            width: parent.width; spacing: 8
            TouchButton { width: 64; text: "Back"; onClicked: home.back() }
            EditorLabel {
                width: parent.width - 64 - 64 - 16; height: 48; verticalAlignment: Text.AlignVCenter
                font.pixelSize: 22; font.weight: Font.DemiBold; elide: Text.ElideRight
                text: home.controller && home.controller.submenuTitle ? home.controller.submenuTitle : home.page === "home" ? "Orb" : home.page === "apps" ? "All apps" : home.page === "windows" ? "Windows" : "Controls"
            }
            TouchButton { width: 64; text: "Close"; onClicked: home.dismissed() }
        }
        Row {
            width: parent.width; spacing: 6
            Repeater {
                model: [{id:"home",name:"Favourites"},{id:"apps",name:"Apps"},{id:"windows",name:"Windows"},{id:"controls",name:"Controls"}]
                delegate: TouchButton {
                    required property var modelData
                    width: (header.width - 18) / 4; text: modelData.name; fontSize: home.narrow ? 12 : 14
                    selected: home.page === modelData.id; onClicked: home.changePage(modelData.id)
                }
            }
        }
    }
    Item {
        id: body
        x: 12; y: header.y + header.height + 10; width: parent.width - 24
        height: Math.max(1, footer.y - y - 10)
        TouchWheel {
            anchors.fill: parent; visible: home.page === "home"
            actions: home.controller ? home.controller.wheelActions : []
            iconSources: actions.map(function(a) { return home.controller.appIconSource(a); })
            edge: home.config.touchEdge || "right"; shape: home.config.touchLayout || "fan"
            targetScale: home.config.touchScale || 1; dragSelection: home.config.touchDrag === true
            onActivated: index => home.controller.activate(index)
            onEdited: index => { if (!home.controller.submenuTitle) home.settingsRequested(index); }
        }
        Column {
            anchors.fill: parent; visible: home.page === "apps"; spacing: 8
            TextField {
                id: search; width: parent.width; height: 50
                placeholderText: "Find an app"; text: home.query
                onTextEdited: home.query = text
                onActiveFocusChanged: if (activeFocus && home.backend) home.backend.keyboard(true)
            }
            GridView {
                id: apps
                width: parent.width; height: Math.max(1, parent.height - search.height - parent.spacing); clip: true
                cellWidth: width / Math.max(1, Math.floor(width / 120)); cellHeight: 112
                model: home.appRows; boundsBehavior: Flickable.StopAtBounds
                delegate: Item {
                    required property var modelData
                    width: apps.cellWidth; height: apps.cellHeight
                    readonly property var entry: modelData.entry
                    TouchButton {
                        x: 4; y: 4; width: parent.width - 8; height: parent.height - 8
                        Accessible.name: home.controller.appLibrary.entryName(parent.entry)
                        onClicked: home.controller.launchDesktop(parent.entry)
                        Column {
                            anchors.centerIn: parent; spacing: 6; width: parent.width - 12
                            Image { anchors.horizontalCenter: parent.horizontalCenter; width: 36; height: width; source: home.controller.appLibrary.iconSource(String(modelData.entry.icon || "")); fillMode: Image.PreserveAspectFit }
                            EditorLabel { width: parent.width; text: home.controller.appLibrary.entryName(modelData.entry); wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }
                        }
                    }
                }
                Controls.ScrollBar.vertical: Controls.ScrollBar {}
                EditorLabel { anchors.centerIn: parent; visible: !home.appRows.length; text: home.query ? "No apps match your search" : "No apps available" }
            }
        }
        Flickable {
            anchors.fill: parent; visible: home.page === "windows"; contentWidth: width; contentHeight: windowColumn.height
            clip: true; boundsBehavior: Flickable.StopAtBounds
            Column {
                id: windowColumn; width: parent.width; spacing: 10
                Flow {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: home.backend ? home.backend.workspaces : []
                        delegate: TouchButton {
                            required property var modelData
                            text: (home.movingWindow ? "Move to " : "Space ") + modelData.name
                            onClicked: {
                                if (home.movingWindow) { home.action(["window", "move", home.movingWindow, String(modelData.id)], false); home.movingWindow = ""; }
                                else home.action(["workspace", String(modelData.id)], true);
                            }
                        }
                    }
                }
                EditorLabel { visible: home.backend && !home.backend.windows.length; text: "No open windows"; width: parent.width }
                Repeater {
                    model: home.backend ? home.backend.windows : []
                    delegate: Column {
                        required property var modelData
                        width: windowColumn.width; spacing: 6
                        TouchButton {
                            width: parent.width; text: modelData.title; leftAlign: true
                            onClicked: home.action(["window", "focus", modelData.address], true)
                        }
                        EditorLabel { text: modelData.app + " · " + modelData.workspaceName + (modelData.hidden ? " · hidden" : ""); opacity: 0.65; width: parent.width; elide: Text.ElideRight }
                        Row {
                            width: parent.width; spacing: 6
                            TouchButton { width: (parent.width - 12) / 3; text: "Maximise"; onClicked: home.action(["window", "maximize", modelData.address], true) }
                            TouchButton { width: (parent.width - 12) / 3; text: "Move"; onClicked: home.movingWindow = modelData.address }
                            TouchButton { width: (parent.width - 12) / 3; text: home.pendingClose === modelData.address ? "Confirm close" : "Close"; onClicked: { if (home.pendingClose === modelData.address) home.action(["window", "close", modelData.address], false); else home.pendingClose = modelData.address; } }
                        }
                    }
                }
            }
            Controls.ScrollBar.vertical: Controls.ScrollBar {}
        }
        Flickable {
            anchors.fill: parent; visible: home.page === "controls"; contentWidth: width; contentHeight: controlColumn.height
            clip: true; boundsBehavior: Flickable.StopAtBounds
            Column {
                id: controlColumn; width: parent.width; spacing: 12
                EditorLabel { text: "Display"; font.pixelSize: 18 }
                Row {
                    width: parent.width; spacing: 8
                    TouchButton { width: (parent.width - 8) / 2; text: "Dimmer"; enabled: home.backend && home.backend.capabilities.brightness === true && !home.backend.busy; onClicked: home.action(["brightness", "down", home.screenName], false) }
                    TouchButton { width: (parent.width - 8) / 2; text: "Brighter"; enabled: home.backend && home.backend.capabilities.brightness === true && !home.backend.busy; onClicked: home.action(["brightness", "up", home.screenName], false) }
                }
                EditorLabel { text: "Sound"; font.pixelSize: 18 }
                Row {
                    width: parent.width; spacing: 8
                    Repeater {
                        model: [{id:"down",name:"Quieter"},{id:"mute",name:"Mute"},{id:"up",name:"Louder"}]
                        delegate: TouchButton { required property var modelData; width: (controlColumn.width - 16) / 3; text: modelData.name; enabled: home.backend && home.backend.capabilities.audio === true && !home.backend.busy; onClicked: home.action(["volume", modelData.id], false) }
                    }
                }
                Row {
                    width: parent.width; spacing: 8
                    Repeater {
                        model: [{id:"previous",name:"Previous"},{id:"play-pause",name:"Play/pause"},{id:"next",name:"Next"}]
                        delegate: TouchButton { required property var modelData; width: (controlColumn.width - 16) / 3; text: modelData.name; enabled: home.backend && home.backend.capabilities.media === true && !home.backend.busy; onClicked: home.action(["media", modelData.id], false) }
                    }
                }
                EditorLabel { text: "Orientation"; font.pixelSize: 18 }
                Row {
                    width: parent.width; spacing: 8
                    Repeater {
                        model: [{id:"left",name:"Left"},{id:"lock",name:"Rotation lock"},{id:"right",name:"Right"}]
                        delegate: TouchButton {
                            required property var modelData
                            width: (controlColumn.width - 16) / 3; text: modelData.name; fontSize: 12
                            selected: modelData.id === "lock" && home.backend && home.backend.capabilities.rotationLocked === true
                            enabled: home.backend && home.backend.capabilities.tabletEnabled === true && !home.backend.busy
                            onClicked: home.action(["rotation", modelData.id], false)
                        }
                    }
                }
                EditorLabel { width: parent.width; wrapMode: Text.WordWrap; visible: home.backend && !home.backend.capabilities.tabletEnabled; text: "Enable Tablet Mode for rotation and automatic switching. Touch mode works without a fold sensor."; opacity: 0.7 }
                TouchButton { width: parent.width; text: "Wi-Fi and network"; enabled: home.backend && home.backend.capabilities.network === true && !home.backend.busy; onClicked: home.action(["network"], true) }
                TouchButton { width: parent.width; text: "Orb settings"; onClicked: home.settingsRequested(-1) }
                EditorLabel { width: parent.width; wrapMode: Text.WordWrap; text: "Locking and unlocking use Omarchy’s secure lock screen. Confirm that your device can unlock without a physical keyboard before relying on it in tablet mode."; opacity: 0.7 }
            }
            Controls.ScrollBar.vertical: Controls.ScrollBar {}
        }
    }
    Column {
        id: footer
        x: 12; width: parent.width - 24; y: parent.height - height - 12; spacing: 6
        EditorLabel { visible: home.backend && home.backend.error !== ""; width: parent.width; text: home.backend ? home.backend.error : ""; color: Commons.Color.urgent; wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight }
        Row {
            width: parent.width; spacing: 6
            TouchButton { width: (parent.width - 12) / 3; text: home.backend && home.backend.keyboardSpace ? "Hide keys" : "Keyboard"; onClicked: home.backend.keyboard(!home.backend.keyboardSpace) }
            TouchButton { width: (parent.width - 12) / 3; text: home.controller && home.controller.pageCount > 1 ? "Next page" : "Settings"; onClicked: { if (home.controller.pageCount > 1 && home.page === "home") home.controller.turnPage(1); else home.settingsRequested(-1); } }
            TouchButton { width: (parent.width - 12) / 3; text: "Retry"; enabled: !home.backend || !home.backend.busy; onClicked: { home.backend.error = ""; home.backend.refresh(); home.backend.refreshWindows(); } }
        }
    }
}
