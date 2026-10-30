import QtQuick
import QtQuick.Dialogs as Dialogs
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

FocusScope {
    id: editor
    Dialogs.FileDialog {
        id: iconDialog
        title: "Choose a shortcut icon"
        nameFilters: ["Images (*.svg *.png *.jpg *.jpeg *.webp)"]
        onAccepted: {
            var value = selectedFile.toString();
            if (value.indexOf("file://") !== 0) return;
            var path = decodeURIComponent(value.slice(7));
            if (Model.validIcon(path)) { editor.customIconPath = path; editor.actionIcon = path; }
        }
    }
    property var choices: []
    property var initial: null
    property int depth: 0
    property int mode: 0
    property alias pickerCursor: actionPicker.cursor
    property string actionLabel: ""
    property string actionIcon: "terminal"
    property string customIconPath: ""
    property string program: ""
    property var commandArguments: []
    property var submenuActions: []
    property var childOrigins: []
    property int editingChild: -1
    property bool busy: false
    property string error: ""
    readonly property string controlPrefix: depth ? "orb-child-" : "orb-action-"
    readonly property var filteredChoices: actionPicker.filteredChoices
    readonly property string pageTitle: editingChild >= 0 ? "Submenu action " + (editingChild + 1) : mode === 1 ? "Custom command" : mode === 2 ? "Edit submenu" : "Choose an action"
    implicitHeight: childLoader.active && childLoader.item ? childLoader.item.implicitHeight : content.height
    signal chosen(var action, var origins)
    signal canceled()

    function begin(value, catalog, level, origins) {
        childLoader.active = false;
        initial = value ? JSON.parse(JSON.stringify(value)) : null;
        choices = catalog; depth = level || 0; error = ""; editingChild = -1;
        actionLabel = value ? value.label : ""; actionIcon = value ? value.icon : "terminal";
        customIconPath = value && value.icon && value.icon.charAt(0) === "/" ? value.icon : "";
        program = value && value.command ? value.command[0] : "";
        commandArguments = value && value.command ? value.command.slice(1) : [];
        submenuActions = value && value.children ? JSON.parse(JSON.stringify(value.children)) : [];
        childOrigins = submenuActions.map(function(c, i) { return origins && origins[i] !== undefined ? origins[i] : i; });
        var known = value && catalog.some(function(c) { return JSON.stringify(c.action) === JSON.stringify(value); });
        mode = value && value.children ? 2 : value && value.command && !known ? 1 : 0;
        actionPicker.reset();
        Qt.callLater(function() { editor.focusFirst(); });
    }
    function pickerTitles() {
        return editingChild >= 0 && childLoader.item ? childLoader.item.pickerTitles() : filteredChoices.map(function(c) { return c.title; });
    }
    function focusFirst() {
        if (editingChild >= 0 && childLoader.item) childLoader.item.focusFirst();
        else if (mode === 0) actionPicker.focusSearch();
        else labelInput.forceActiveFocus();
    }
    function changeMode(value) { mode = value; error = ""; Qt.callLater(function() { editor.focusFirst(); }); }
    function setArgument(index, value) { var copy = commandArguments.slice(); copy[index] = value; commandArguments = copy; }
    function removeArgument(index) { var copy = commandArguments.slice(); copy.splice(index, 1); commandArguments = copy; }
    function choose(index) { actionPicker.choose(index); }
    function movePicker(delta) { actionPicker.moveCursor(delta); }
    function apply() {
        if (busy) return;
        var value = { label: actionLabel, icon: actionIcon };
        if (mode === 1) value.command = [program].concat(commandArguments);
        else value.children = submenuActions;
        // QML var signals can wrap child actions as QVariant lists/maps.
        // Validate the same plain JSON representation used by the save path.
        var checked = Model.action(JSON.parse(JSON.stringify(value)), editor.depth);
        if (!checked) {
            error = !actionLabel.trim() ? "Give this action a name." : mode === 1 && !program ? "Enter the program to run."
                : mode === 2 && !submenuActions.length ? "Add at least one submenu action." : !Model.validIcon(actionIcon) ? "Choose an icon or enter an absolute image path." : "Check the name, program and arguments before continuing.";
            return;
        }
        chosen(checked, childOrigins);
    }
    function editChild(index) {
        editingChild = index;
        childLoader.active = true;
        childLoader.item.begin(submenuActions[index] || null, choices, 1, []);
    }
    function finishChild(value) {
        var copy = submenuActions.slice(), origins = childOrigins.slice();
        if (editingChild === submenuActions.length) origins.push(-1);
        copy[editingChild] = value;
        submenuActions = copy; childOrigins = origins; closeChild();
    }
    function closeChild() { childLoader.active = false; editingChild = -1; focusFirst(); }
    function removeChild(index) {
        var copy = submenuActions.slice(), origins = childOrigins.slice();
        copy.splice(index, 1); origins.splice(index, 1); submenuActions = copy; childOrigins = origins;
    }
    function moveChild(from, to) { submenuActions = Model.move(submenuActions, from, to); childOrigins = Model.move(childOrigins, from, to); }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) { canceled(); event.accepted = true; }
        else if (event.key === Qt.Key_Return && (event.modifiers & Qt.ControlModifier) && mode !== 0) { apply(); event.accepted = true; }
    }
    Column {
        id: content
        visible: editor.editingChild < 0
        width: parent.width
        spacing: Commons.Style.space(10)
        Row {
            width: parent.width; spacing: Commons.Style.space(6)
            Repeater {
                model: editor.depth ? ["Apps & shortcuts", "Custom command"] : ["Apps & shortcuts", "Custom command", "Submenu"]
                delegate: EditorButton {
                    required property int index
                    required property string modelData
                    objectName: editor.controlPrefix + "mode-" + index
                    width: (content.width - parent.spacing * (editor.depth ? 1 : 2)) / (editor.depth ? 2 : 3)
                    text: modelData; selected: editor.mode === index; enabled: !editor.busy
                    onClicked: editor.changeMode(index)
                }
            }
        }
        ActionPicker {
            id: actionPicker
            visible: editor.mode === 0
            width: parent.width; choices: editor.choices; depth: editor.depth; busy: editor.busy
            controlPrefix: editor.controlPrefix
            onChosen: value => editor.chosen(value, value.children ? value.children.map(function() { return -1; }) : [])
        }
        Column {
            visible: editor.mode !== 0
            width: parent.width; spacing: Commons.Style.space(8)
            EditorLabel { text: "Name" }
            TextField {
                id: labelInput
                objectName: editor.controlPrefix + "name"
                width: parent.width; maximumLength: 20; text: editor.actionLabel; enabled: !editor.busy
                placeholderText: editor.mode === 2 ? "My submenu" : "My shortcut"
                onTextEdited: editor.actionLabel = text
            }
            EditorLabel { text: "Icon" }
            Grid {
                width: parent.width; columns: 7; spacing: Commons.Style.space(5)
                Repeater {
                    model: Model.icons
                    delegate: EditorButton {
                        required property string modelData
                        width: (content.width - parent.spacing * 6) / 7; height: Commons.Style.space(34)
                        tooltipText: modelData; selected: editor.actionIcon === modelData; enabled: !editor.busy
                        ActionIcon { anchors.centerIn: parent; width: Commons.Style.space(20); height: width; name: modelData; selected: editor.actionIcon === modelData }
                        onClicked: { editor.actionIcon = modelData; editor.customIconPath = ""; }
                    }
                }
            }
            EditorLabel { text: "Or use a local image" }
            EditorButton { text: "Choose image…"; enabled: !editor.busy; onClicked: iconDialog.open() }
            Row {
                width: parent.width; spacing: Commons.Style.space(6)
                TextField {
                    objectName: editor.controlPrefix + "icon-path"
                    width: parent.width - Commons.Style.space(34) - parent.spacing
                    text: editor.customIconPath; enabled: !editor.busy; maximumLength: 4096
                    placeholderText: "/absolute/path/to/icon.svg"
                    onTextEdited: { editor.customIconPath = text; editor.actionIcon = text; }
                }
                ActionIcon {
                    width: Commons.Style.space(34); height: width
                    name: Model.validIcon(editor.actionIcon) ? editor.actionIcon : "app"
                }
            }
            EditorLabel { width: parent.width; wrapMode: Text.WordWrap; opacity: 0.65
                text: "Absolute path to an SVG, PNG, JPEG or WebP image. Keep the file in place; missing images use a fallback icon." }
        }
        Column {
            visible: editor.mode === 1
            width: parent.width; spacing: Commons.Style.space(8)
            EditorLabel { text: "Program" }
            TextField {
                objectName: editor.controlPrefix + "program"
                width: parent.width; text: editor.program; placeholderText: "e.g. notify-send or /path/to/script"; enabled: !editor.busy
                maximumLength: 4096; onTextEdited: editor.program = text
            }
            EditorLabel { text: "Arguments · one field per argument" }
            Repeater {
                id: argumentRows
                model: editor.commandArguments.length
                delegate: Row {
                    required property int index
                    width: content.width; spacing: Commons.Style.space(6)
                    TextField {
                        id: argumentInput
                        objectName: editor.controlPrefix + "argument-" + index
                        width: parent.width - removeArgument.width - parent.spacing
                        text: editor.commandArguments[index]; placeholderText: "Argument " + (index + 1); enabled: !editor.busy
                        maximumLength: 4096
                        onTextEdited: editor.setArgument(index, text)
                    }
                    property alias input: argumentInput
                    EditorButton {
                        id: removeArgument
                        width: Commons.Style.space(32); text: "×"; tooltipText: "Remove argument"; enabled: !editor.busy
                        onClicked: editor.removeArgument(index)
                    }
                }
            }
            EditorButton {
                objectName: editor.controlPrefix + "add-argument"
                text: "+ Add argument"; enabled: !editor.busy && editor.commandArguments.length < 31
                onClicked: {
                    var index = editor.commandArguments.length;
                    editor.commandArguments = editor.commandArguments.concat([""]);
                    Qt.callLater(function() { var row = argumentRows.itemAt(index); if (row) row.input.forceActiveFocus(); });
                }
            }
            EditorLabel { width: parent.width; wrapMode: Text.WordWrap; text: "Arguments keep their spaces. No quotes are needed around a field."; opacity: 0.65 }
        }
        Column {
            visible: editor.mode === 2
            width: parent.width; spacing: Commons.Style.space(6)
            EditorLabel { text: "Submenu actions · " + editor.submenuActions.length + " / 12" }
            Repeater {
                model: editor.submenuActions
                delegate: Row {
                    required property int index
                    required property var modelData
                    width: content.width; spacing: Commons.Style.space(4)
                    EditorButton {
                        objectName: editor.controlPrefix + "edit-child-" + index
                        width: parent.width - Commons.Style.space(108) - parent.spacing * 3
                        text: (index + 1) + " · " + modelData.label; leftAlign: true; enabled: !editor.busy
                        onClicked: editor.editChild(index)
                    }
                    EditorButton { objectName: editor.controlPrefix + "up-child-" + index; width: Commons.Style.space(32); text: "↑"; tooltipText: "Move up"; enabled: !editor.busy && index > 0; onClicked: editor.moveChild(index, index - 1) }
                    EditorButton { objectName: editor.controlPrefix + "down-child-" + index; width: Commons.Style.space(32); text: "↓"; tooltipText: "Move down"; enabled: !editor.busy && index < editor.submenuActions.length - 1; onClicked: editor.moveChild(index, index + 1) }
                    EditorButton { objectName: editor.controlPrefix + "remove-child-" + index; width: Commons.Style.space(36); text: "×"; tooltipText: "Remove action"; enabled: !editor.busy; onClicked: editor.removeChild(index) }
                }
            }
            EditorButton { objectName: editor.controlPrefix + "add-child"; text: "+ Add action"; enabled: !editor.busy && editor.submenuActions.length < 12; onClicked: editor.editChild(editor.submenuActions.length) }
        }
        EditorLabel { visible: editor.error !== ""; width: parent.width; wrapMode: Text.WordWrap; text: editor.error; color: Commons.Color.urgent }
        Row {
            width: parent.width; spacing: Commons.Style.space(8)
            EditorButton { objectName: editor.controlPrefix + "back"; text: "‹ Back"; enabled: !editor.busy; onClicked: editor.canceled() }
            EditorButton { objectName: editor.controlPrefix + "use"; visible: editor.mode !== 0; text: "Use " + (editor.mode === 2 ? "submenu" : "command"); selected: true; enabled: !editor.busy; onClicked: editor.apply() }
        }
        EditorLabel { width: parent.width; text: "Changes apply when you save Orb settings."; opacity: 0.65; font.pixelSize: Commons.Style.space(10) }
    }
    Loader {
        id: childLoader
        active: false; width: parent.width
        source: Qt.resolvedUrl("ActionEditor.qml")
        onLoaded: item.busy = Qt.binding(function() { return editor.busy; })
    }
    Connections {
        target: childLoader.item
        function onChosen(action, origins) { editor.finishChild(action); }
        function onCanceled() { editor.closeChild(); }
    }
}
