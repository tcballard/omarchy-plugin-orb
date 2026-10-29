import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Dialogs as Dialogs
import Quickshell.Io
import "Model.js" as Model

Column {
    id: library
    property var wheels: []
    property var setups: []
    property string editingWheelId: "everyday"
    property string activeWheel: "everyday"
    property var currentActions: []
    property var choices: []
    property bool busy: false
    property string error: ""
    property string newName: ""
    property string setupName: ""
    property int workspace: 1
    property string layout: "tiled"
    property var selectedApps: []
    property var preview: null
    property string importPath: ""
    property string operation: ""
    property string helper: decodeURIComponent(Qt.resolvedUrl("scripts/layout-share").toString().replace(/^file:\/\//,""))
    spacing: 10
    function begin(config) {
        wheels = JSON.parse(JSON.stringify(config.wheels || [{id:"everyday",name:"Everyday",actions:config.actions}]));
        activeWheel = config.activeWheel || "everyday"; setups = JSON.parse(JSON.stringify(config.setups || []));
        editingWheelId = activeWheel;
        error = ""; preview = null; newName = ""; selectedApps = []; setupName = "";
    }
    function newId(prefix) { return prefix + Date.now().toString(36) + Math.random().toString(36).slice(2,7); }
    function addWheel() {
        if (!newName.trim() || wheels.length >= 16) return;
        wheels = wheels.concat([{id:newId("w-"),name:newName.trim(),actions:JSON.parse(JSON.stringify(currentActions))}]); newName = "";
    }
    function rename(index, name) { var copy = JSON.parse(JSON.stringify(wheels)); copy[index].name = name; wheels = copy; }
    function addSetup() {
        if (!setupName.trim() || !selectedApps.length || setups.length >= 16) return;
        setups = setups.concat([{id:newId("s-"),name:setupName.trim(),workspace:workspace,layout:layout,apps:selectedApps.slice()}]);
        setupName = ""; selectedApps = [];
    }
    function share(verb, path, value) {
        if (transfer.running) return;
        error = ""; operation = verb;
        transfer.command = ["bash",helper,verb,path,value || ""]; transfer.running = true;
    }
    EditorLabel { text: "Named wheels"; font.pixelSize: 18 }
    EditorLabel { width: parent.width; wrapMode: Text.WordWrap; text: "Choose a wheel, then Save to switch. Shortcut edits are saved to the wheel you opened. Each layout keeps its own positions." }
    Repeater {
        model: library.wheels
        delegate: Column {
            required property int index
            required property var modelData
            width: library.width; spacing: 5
            Row {
                width: parent.width; spacing: 6
                EditorButton { width: 76; text: library.activeWheel === modelData.id ? "Selected" : "Use"; selected: library.activeWheel === modelData.id; enabled: !library.busy; onClicked: library.activeWheel = modelData.id }
                EditorField { objectName: "orb-wheel-name-" + modelData.id; width: parent.width - 82; text: modelData.name; maximumLength: 32; enabled: !library.busy; onEditingFinished: if (text !== modelData.name) library.rename(index,text) }
            }
            Row {
                spacing: 6
                EditorButton { text: "Export"; enabled: !library.busy && !transfer.running; onClicked: { exportDialog.wheel = {name:modelData.name,actions:modelData.id === library.editingWheelId ? library.currentActions : modelData.actions}; exportDialog.open(); } }
                EditorButton { text: "Remove"; enabled: !library.busy && library.wheels.length > 1 && modelData.id !== library.activeWheel; onClicked: library.wheels = library.wheels.filter(function(w) { return w.id !== modelData.id; }) }
            }
        }
    }
    EditorField { width: parent.width; placeholderText: "Name a copy of this wheel"; maximumLength: 32; text: library.newName; enabled: !library.busy; onTextEdited: library.newName = text }
    EditorButton { text: "Duplicate current wheel"; enabled: !library.busy && library.newName.trim() !== "" && library.wheels.length < 16; onClicked: library.addWheel() }
    EditorButton { text: "Import wheel…"; enabled: !library.busy && !transfer.running; onClicked: importDialog.open() }
    Column {
        width: parent.width; visible: library.preview !== null; spacing: 6
        EditorLabel { width: parent.width; wrapMode: Text.WordWrap; text: library.preview ? "Review “" + library.preview.wheel.name + "”. Commands below will become runnable shortcuts when you use this wheel." : "" }
        Controls.ScrollView { width: parent.width; height: 180; clip: true
        Controls.TextArea { readOnly: true; selectByMouse: true; textFormat: TextEdit.PlainText; wrapMode: TextEdit.Wrap; text: library.preview ? JSON.stringify(library.preview.wheel.actions,null,2) : "" }
        }
        Row {
            spacing: 6
            EditorButton { text: "Add to draft"; enabled: !library.busy && !transfer.running && library.wheels.length < 16; onClicked: library.share("import",library.importPath,library.preview.digest) }
            EditorButton { text: "Discard"; onClicked: library.preview = null }
        }
    }
    EditorLabel { width: parent.width; text: library.error; visible: text !== ""; wrapMode: Text.WordWrap }
    EditorLabel { text: "Saved work setups"; font.pixelSize: 18 }
    Repeater {
        model: library.setups
        delegate: Row {
            required property var modelData
            width: library.width; spacing: 6
            EditorLabel { width: parent.width - 90; height: 48; verticalAlignment: Text.AlignVCenter; text: modelData.name + " · space " + modelData.workspace + " · " + modelData.apps.length + " apps" }
            EditorButton { width: 84; text: "Remove"; enabled: !library.busy; onClicked: library.setups = library.setups.filter(function(s) { return s.id !== modelData.id; }) }
        }
    }
    EditorField { width: parent.width; placeholderText: "New setup name"; maximumLength: 32; text: library.setupName; enabled: !library.busy; onTextEdited: library.setupName = text }
    Row {
        spacing: 8
        EditorLabel { height: 48; verticalAlignment: Text.AlignVCenter; text: "Workspace" }
        Controls.SpinBox { height: 48; from: 1; to: 9999; value: library.workspace; enabled: !library.busy; onValueModified: library.workspace = value }
    }
    Row {
        width: parent.width; spacing: 6
        EditorButton { width: (parent.width-6)/2; text: "Normal tiling"; selected: library.layout === "tiled"; onClicked: library.layout = "tiled" }
        EditorButton { width: (parent.width-6)/2; text: "Equal columns"; selected: library.layout === "columns"; onClicked: library.layout = "columns" }
    }
    EditorLabel { width: parent.width; wrapMode: Text.WordWrap; text: "Choose up to eight apps in opening order. New windows receive the saved workspace/layout. Apps that reuse an existing window may keep its current location." }
    Controls.ComboBox {
        id: appChoice
        width: parent.width; height: 48; textRole: "title"
        model: library.choices.filter(function(c) { return !!c.action.desktopId; })
        Accessible.name: "App to add to work setup"
    }
    EditorButton { text: "Add selected app"; enabled: !library.busy && library.selectedApps.length < 8 && appChoice.currentIndex >= 0; onClicked: { var id = appChoice.model[appChoice.currentIndex].action.desktopId; if (library.selectedApps.indexOf(id) < 0) library.selectedApps = library.selectedApps.concat([id]); } }
    Repeater {
        model: library.selectedApps
        delegate: EditorButton { required property string modelData; text: modelData + " ×"; width: library.width; onClicked: library.selectedApps = library.selectedApps.filter(function(a) { return a !== modelData; }) }
    }
    EditorButton { text: "Add work setup"; enabled: !library.busy && library.setupName.trim() !== "" && library.selectedApps.length > 0 && library.setups.length < 16; onClicked: library.addSetup() }
    Dialogs.FileDialog {
        id: exportDialog
        property var wheel: null
        title: "Export wheel"; fileMode: Dialogs.FileDialog.SaveFile; nameFilters: ["Orb wheel (*.orb.json)"]; defaultSuffix: "orb.json"
        onAccepted: library.share("export",decodeURIComponent(selectedFile.toString().replace(/^file:\/\//,"")),JSON.stringify(wheel))
    }
    Dialogs.FileDialog {
        id: importDialog
        title: "Import wheel"; nameFilters: ["Orb wheel (*.orb.json)"]
        onAccepted: { library.importPath = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//,"")); library.share("preview",library.importPath,""); }
    }
    Process {
        id: transfer
        stdout: StdioCollector { id: result }
        onExited: (code,status) => {
            try {
                var value = JSON.parse(result.text);
                if (code !== 0 || !value.ok) throw new Error(value.error || "Could not transfer this wheel.");
                if (library.operation === "preview") library.preview = value;
                else if (library.operation === "import") {
                    var wheel = value.wheel; wheel.id = library.newId("w-");
                    var checked = Model.librarySettings({actions:wheel.actions,wheels:[wheel],activeWheel:wheel.id});
                    if (checked.error) throw new Error(checked.error);
                    library.wheels = library.wheels.concat([wheel]); library.preview = null;
                } else library.error = "Wheel exported.";
            } catch(e) { library.error = String(e.message).slice(0,250); }
        }
    }
    Timer { interval: 10000; running: transfer.running; onTriggered: { transfer.running = false; library.error = "Wheel transfer timed out."; } }
}
