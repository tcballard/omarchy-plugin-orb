import QtQuick
import QtQuick.Window
import QtQuick.Controls as Controls
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model
import "ShortcutHistory.js" as History

FocusScope {
    id: panel
    property bool touchFriendly: false
    property bool keyboardShown: false
    property var touchStatus: ({})
    signal keyboardRequested()
    signal keyboardToggled()
    property int diameter: 240
    property bool animation: true
    property string shape: "circle"
    property string shortcut: "SUPER + ALT + O"
    property bool desktopRightClick: false
    property bool mouseOpen: false
    property string mouseButtonText: "277"
    property var actions: []
    property var actionOrigins: []
    property var childOrigins: []
    property var shortcutHistory: []
    property string version: ""
    property var original: ({})
    property var choices: []
    property var appLibrary: null
    property string error: ""
    property bool busy: false
    property bool setupFailed: false
    property int tab: 0
    property int selectedSlot: 0
    property int editingSlot: -1
    property bool browsingActions: false
    property var draggedAction: null
    property string draggedIconSource: ""
    property point dragPosition: Qt.point(0, 0)
    property real maximumHeight: 800
    property real openingHeight: 0
    property alias editor: actionEditor
    readonly property var positions: actions.length === 8 ? ["Top", "Upper right", "Right", "Lower right", "Bottom", "Lower left", "Left", "Upper left"]
        : actions.length === 7 ? ["Top", "Upper right", "Right", "Lower right", "Lower left", "Left", "Upper left"]
        : actions.length === 5 ? ["Top", "Upper right", "Lower right", "Lower left", "Upper left"]
        : ["Top", "Upper right", "Lower right", "Bottom", "Lower left", "Upper left"]
    readonly property bool wide: width >= Commons.Style.space(580)
    readonly property var shortcutCheck: Model.shortcut(shortcut)
    readonly property var mouseCheck: Model.mouseButton(mouseButtonText)
    readonly property string activationError: Model.activationConflict(desktopRightClick, mouseOpen, mouseButtonText)
    readonly property var filteredChoices: actionEditor.filteredChoices
    readonly property var sizePresets: [{ name: "Small", value: 240 }, { name: "Medium", value: 360 }, { name: "Large", value: 480 }]
    implicitHeight: Math.min(maximumHeight, openingHeight || header.height + bodyColumn.height + footer.height + Commons.Style.space(64))
    height: implicitHeight
    signal saveRequested()
    signal canceled()
    signal retrySetup()

    function begin(config, catalog) {
        original = JSON.parse(JSON.stringify(config));
        touchOptions.begin(config);
        diameter = config.diameter; animation = config.animation; shape = config.shape || "circle";
        shortcut = config.shortcut || "SUPER + ALT + O"; desktopRightClick = config.desktopRightClick === true;
        mouseOpen = config.mouseOpen === true; mouseButtonText = String(config.mouseButton || 277);
        actions = JSON.parse(JSON.stringify(config.actions)); choices = catalog;
        actionOrigins = actions.map(function(a, i) { return i; });
        childOrigins = actions.map(function(a) { return a.children ? a.children.map(function(c, i) { return i; }) : []; });
        shortcutHistory = [];
        tab = 0; selectedSlot = 0; editingSlot = -1; body.contentY = 0;
        browsingActions = false; actionBrowser.reset(); clearAssignment();
        openingHeight = 0;
        Qt.callLater(function() { slotNavigation.forceActiveFocus(); });
    }
    function draft() { return Object.assign(touchOptions.draft(), { diameter: diameter, animation: animation, shape: shape, actions: actions,
        shortcut: shortcutCheck.error ? shortcut : shortcutCheck.value, desktopRightClick: desktopRightClick,
        mouseOpen: mouseOpen, mouseButton: mouseCheck.error ? mouseButtonText : mouseCheck.value,
        actionOrigins: actionOrigins, childOrigins: childOrigins }); }
    function appIcon(action) {
        if (!action.desktopId) return "";
        for (var i = 0; i < choices.length; i++)
            if (choices[i].action.desktopId === action.desktopId) return choices[i].iconSource || "";
        return "";
    }
    function selectTab(index) {
        tab = index; body.contentY = 0;
        Qt.callLater(function() {
            if (index === 0 && browsingActions) actionBrowser.focusSearch();
            else if (index === 0) slotNavigation.forceActiveFocus();
            else if (index === 1) sizeControl.forceActiveFocus();
            else if (index === 2) openingKey.forceActiveFocus();
            else touchOptions.forceActiveFocus();
        });
    }
    function editSlot(index) {
        if (busy) return;
        editingSlot = index; body.contentY = 0;
        actionEditor.begin(actions[index] || null, choices, 0, childOrigins[index] || []);
    }
    function backToSlots() {
        selectedSlot = Math.min(editingSlot, actions.length - 1); editingSlot = -1;
        body.contentY = 0; slotNavigation.forceActiveFocus();
    }
    function addSlot() { if (actions.length < 8) editSlot(actions.length); }
    function setShortcuts(nextActions, nextOrigins, nextChildren, selection) {
        var before = History.snapshot(panel);
        if (JSON.stringify([actions, actionOrigins, childOrigins]) === JSON.stringify([nextActions, nextOrigins, nextChildren])) return;
        shortcutHistory = History.remember(shortcutHistory, before);
        actions = nextActions; actionOrigins = nextOrigins; childOrigins = nextChildren; selectedSlot = selection;
    }
    function undoShortcuts() {
        if (busy || editingSlot >= 0 || !shortcutHistory.length) return;
        var previous = shortcutHistory[shortcutHistory.length - 1];
        shortcutHistory = shortcutHistory.slice(0, -1);
        actions = previous.actions; actionOrigins = previous.actionOrigins; childOrigins = previous.childOrigins;
        selectedSlot = previous.selectedSlot; clearAssignment();
        if (browsingActions) preview.forceActiveFocus(); else slotNavigation.forceActiveFocus();
    }
    function removeSlot(index) {
        if (busy || actions.length <= 5 || index < 0 || index >= actions.length) return;
        var copy = actions.slice(), order = actionOrigins.slice(), childOrder = childOrigins.slice();
        copy.splice(index, 1); order.splice(index, 1); childOrder.splice(index, 1);
        setShortcuts(copy, order, childOrder, Math.min(index, copy.length - 1));
        slotNavigation.forceActiveFocus();
    }
    function chooseAction(value, childrenOrder) {
        var copy = actions.slice(), order = actionOrigins.slice(), childOrder = childOrigins.slice();
        if (editingSlot === actions.length) order.push(-1);
        copy[editingSlot] = value; childOrder[editingSlot] = childrenOrder || [];
        setShortcuts(copy, order, childOrder, editingSlot); backToSlots();
    }
    function moveSlot(from, to) {
        if (busy || from < 0 || to < 0 || from >= actions.length || to >= actions.length) return;
        setShortcuts(Model.move(actions, from, to), Model.move(actionOrigins, from, to), Model.move(childOrigins, from, to), to);
        if (browsingActions) actionBrowser.focusSearch(); else slotNavigation.forceActiveFocus();
    }
    function browseActions() {
        browsingActions = !browsingActions; body.contentY = 0; clearAssignment();
        Qt.callLater(function() { if (panel.browsingActions) actionBrowser.focusSearch(); else slotNavigation.forceActiveFocus(); });
    }
    function assignAction(index, value) {
        if (busy || index < 0 || index >= actions.length) return;
        var checked = Model.action(JSON.parse(JSON.stringify(value)), 0);
        if (!checked) return;
        var copy = actions.slice(), childOrder = childOrigins.slice();
        copy[index] = checked; childOrder[index] = checked.children ? checked.children.map(function() { return -1; }) : [];
        setShortcuts(copy, actionOrigins.slice(), childOrder, index);
    }
    function clearAssignment() { draggedAction = null; draggedIconSource = ""; preview.cancelAssignment(); }
    function pickerTitles() { return browsingActions && editingSlot < 0 ? actionBrowser.titles() : editingSlot >= 0 ? actionEditor.pickerTitles() : []; }
    function toggleModifier(modifier) {
        var checked = Model.shortcut(shortcut), mask = checked.error ? 72 : checked.mask;
        mask ^= modifier;
        var tokens = ["SUPER"];
        if (mask & 4) tokens.push("CTRL"); if (mask & 8) tokens.push("ALT"); if (mask & 1) tokens.push("SHIFT");
        tokens.push(openingKey.text.toUpperCase() || "O"); shortcut = tokens.join(" + ");
    }
    function changeKey(value) {
        var tokens = shortcut.split("+"); tokens[tokens.length - 1] = value.toUpperCase().trim(); shortcut = tokens.join(" + ");
    }
    function requestSave() { if (!busy && !shortcutCheck.error && !activationError && editingSlot < 0) saveRequested(); }
    function previewStatus() {
        var p = preview.mapToItem(panel, 0, 0);
        return { x: p.x, y: p.y, diameter: preview.width, shape: preview.shape, dragging: preview.dragging, selected: selectedSlot };
    }
    function layoutStatus() {
        return { bodyX: body.x, bodyY: body.y, bodyWidth: body.width, bodyHeight: body.height,
            contentHeight: body.contentHeight, contentWidth: bodyColumn.width, scroll: body.contentY,
            tabY: header.y + header.height - tabRow.height / 2 };
    }
    function controls() {
        var rows = [];
        function visit(item) {
            if (!item.visible) return;
            if (item.objectName && item.objectName.indexOf("orb-") === 0) {
                var p = item.mapToItem(panel, 0, 0);
                rows.push({ name: item.objectName, x: p.x, y: p.y, width: item.width, height: item.height, enabled: item.enabled });
            }
            for (var i = 0; i < item.children.length; i++) visit(item.children[i]);
        }
        visit(panel); return rows;
    }
    function reveal(item) {
        var p = item.mapToItem(body.contentItem, 0, 0);
        body.contentY = Math.max(0, Math.min(body.contentHeight - body.height,
            p.y < body.contentY ? p.y : p.y + item.height > body.contentY + body.height ? p.y + item.height - body.height : body.contentY));
    }
    Keys.onPressed: event => {
        if (busy) { event.accepted = true; return; }
        if (editingSlot >= 0) return;
        if (event.key === Qt.Key_Escape) { canceled(); event.accepted = true; }
        else if (event.key === Qt.Key_S && (event.modifiers & Qt.ControlModifier)) { requestSave(); event.accepted = true; }
        else if (tab === 0 && event.key === Qt.Key_Z && event.modifiers === Qt.ControlModifier && shortcutHistory.length) { undoShortcuts(); event.accepted = true; }
        else if (tab === 0 && (event.modifiers & Qt.AltModifier) && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
            moveSlot(selectedSlot, (selectedSlot + (event.key === Qt.Key_Right ? 1 : actions.length - 1)) % actions.length); event.accepted = true;
        }
    }
    Rectangle {
        anchors.fill: parent; radius: Commons.Style.cornerRadius
        color: Commons.Color.menu.background
        border.width: 1; border.color: Commons.Util.alpha(Commons.Color.menu.text, 0.25)
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: panel.forceActiveFocus() }
    }
    Column {
        id: header
        x: Commons.Style.space(18); y: x; width: parent.width - x * 2; spacing: Commons.Style.space(10)
        Row {
            width: parent.width; spacing: Commons.Style.space(10)
            EditorLabel { width: parent.width - versionLabel.width - parent.spacing; text: panel.editingSlot >= 0 ? actionEditor.pageTitle : "Orb settings"; font.pixelSize: Commons.Style.space(20); font.weight: Font.DemiBold; elide: Text.ElideRight }
            EditorLabel { id: versionLabel; objectName: "orb-version"; text: panel.version ? "v" + panel.version : ""; opacity: 0.6; anchors.verticalCenter: parent.verticalCenter }
        }
        EditorLabel {
            width: parent.width; wrapMode: Text.WordWrap; opacity: 0.65
            text: panel.editingSlot >= 0 ? (panel.editingSlot === panel.actions.length ? "Add a shortcut to your wheel" : "Slot " + (panel.editingSlot + 1) + " · " + panel.positions[panel.editingSlot])
                : panel.tab === 0 ? "Choose your shortcuts and put them where you want them."
                : panel.tab === 1 ? "Make the wheel feel at home on your desktop." : panel.tab === 2 ? "Choose how you open Orb." : "Set up navigation for your touchscreen."
        }
        Row {
            id: tabRow
            visible: panel.editingSlot < 0; width: parent.width; spacing: Commons.Style.space(6)
            Repeater {
                model: ["Shortcuts", "Appearance", "Opening", "Touch"]
                delegate: EditorButton {
                    required property int index
                    required property string modelData
                    objectName: "orb-tab-" + index
                    width: (header.width - parent.spacing * 3) / 4; text: modelData
                    selected: panel.tab === index; enabled: !panel.busy
                    onClicked: panel.selectTab(index)
                }
            }
        }
    }
    Flickable {
        id: body
        x: header.x; y: header.y + header.height + Commons.Style.space(14)
        width: header.width; height: Math.max(1, footer.y - y - Commons.Style.space(12))
        contentWidth: width; contentHeight: bodyColumn.height
        clip: true; boundsBehavior: Flickable.StopAtBounds
        WheelHandler {
            target: null
            enabled: !panel.busy && body.contentHeight > body.height
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                var delta = event.pixelDelta.y || event.angleDelta.y / 120 * Commons.Style.space(40);
                body.contentY = Math.max(0, Math.min(body.contentHeight - body.height, body.contentY - delta));
                event.accepted = true;
            }
        }
        Controls.ScrollBar.vertical: Controls.ScrollBar {
            id: bodyScrollBar
            objectName: "orb-settings-scrollbar"
            width: Commons.Style.space(10); padding: Commons.Style.space(2)
            policy: body.contentHeight > body.height + 1 ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff
            minimumSize: Math.min(1, Commons.Style.space(28) / Math.max(1, height))
            enabled: !panel.busy
            contentItem: Rectangle {
                objectName: "orb-settings-scroll-thumb"
                implicitWidth: Commons.Style.space(4); implicitHeight: Commons.Style.space(28)
                radius: width / 2; color: Commons.Util.alpha(Commons.Color.menu.text, 0.45)
            }
        }
        Column {
            id: bodyColumn
            x: bodyScrollBar.mirrored ? bodyScrollBar.width + Commons.Style.space(6) : 0
            width: Math.max(0, body.width - bodyScrollBar.width - Commons.Style.space(6)); spacing: Commons.Style.space(10)
            Item {
                id: shortcutsLayout
                visible: panel.editingSlot < 0 && panel.tab === 0
                width: parent.width
                readonly property bool sideBySide: width >= Commons.Style.space(380)
                readonly property real rightHeight: panel.browsingActions ? browserColumn.height : slotColumn.height
                height: sideBySide ? Math.max(previewColumn.height, rightHeight) : previewColumn.height + rightHeight + Commons.Style.space(14)
                Column {
                    id: previewColumn
                    x: shortcutsLayout.sideBySide ? 0 : (parent.width - width) / 2
                    width: Math.min(Commons.Style.space(panel.wide ? 260 : shortcutsLayout.sideBySide ? 170 : 150), parent.width); spacing: Commons.Style.space(10)
                    WheelPreview {
                        id: preview
                        width: parent.width; actions: panel.actions; shape: panel.shape; selected: panel.selectedSlot; busy: panel.busy
                        activeFocusOnTab: panel.browsingActions
                        iconSources: panel.actions.map(function(a) { return panel.appIcon(a); })
                        onPicked: index => { if (panel.browsingActions) { panel.selectedSlot = index; forceActiveFocus(); } else panel.editSlot(index); }
                        onMoved: (from, to) => panel.moveSlot(from, to)
                        onAssigned: (index, action) => panel.assignAction(index, action)
                        Keys.onLeftPressed: panel.selectedSlot = (panel.selectedSlot + panel.actions.length - 1) % panel.actions.length
                        Keys.onRightPressed: panel.selectedSlot = (panel.selectedSlot + 1) % panel.actions.length
                    }
                    EditorLabel { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: preview.caption; wrapMode: Text.WordWrap }
                    EditorLabel { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: panel.browsingActions ? "Drag an action onto a slot" : "Drag to arrange · click to edit"; wrapMode: Text.WordWrap; opacity: 0.65; font.pixelSize: Commons.Style.space(10) }
                    EditorButton { objectName: "orb-browse-actions"; width: parent.width; text: panel.browsingActions ? "Back to shortcuts" : "Browse actions"; selected: panel.browsingActions; enabled: !panel.busy; onClicked: panel.browseActions() }
                    EditorButton { objectName: "orb-undo"; width: parent.width; text: "Undo"; tooltipText: "Undo shortcut edit · Ctrl+Z"; enabled: !panel.busy && panel.shortcutHistory.length > 0; onClicked: panel.undoShortcuts() }
                }
                Column {
                    id: slotColumn
                    visible: !panel.browsingActions
                    x: shortcutsLayout.sideBySide ? previewColumn.width + Commons.Style.space(18) : 0
                    y: shortcutsLayout.sideBySide ? 0 : previewColumn.height + Commons.Style.space(14)
                    width: parent.width - x; spacing: Commons.Style.space(7)
                    Item {
                        id: slotNavigation
                        width: parent.width; height: slotRows.height; focus: true; activeFocusOnTab: true
                        Keys.onPressed: event => {
                            if (event.modifiers & Qt.AltModifier) return;
                            if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                                panel.selectedSlot = (panel.selectedSlot + (event.key === Qt.Key_Down ? 1 : panel.actions.length - 1)) % panel.actions.length;
                                panel.reveal(slotRepeater.itemAt(panel.selectedSlot));
                            }
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) panel.editSlot(panel.selectedSlot);
                            else if (event.key === Qt.Key_Delete) panel.removeSlot(panel.selectedSlot);
                            else return;
                            event.accepted = true;
                        }
                        Column {
                            id: slotRows
                            width: parent.width; spacing: Commons.Style.space(4)
                            Repeater {
                                id: slotRepeater
                                model: panel.actions
                                delegate: EditorButton {
                                    required property int index
                                    required property var modelData
                                    objectName: "orb-slot-" + index
                                    width: slotRows.width; height: Math.max(48, Commons.Style.space(40))
                                    focusable: false; leftAlign: true; leftPadding: Commons.Style.space(40)
                                    text: (index + 1) + " · " + modelData.label
                                    tooltipText: panel.positions[index] || ""; selected: panel.selectedSlot === index; enabled: !panel.busy
                                    ActionIcon { x: Commons.Style.space(10); anchors.verticalCenter: parent.verticalCenter; width: Commons.Style.space(20); height: width; name: modelData.icon; appSource: panel.appIcon(modelData); selected: panel.selectedSlot === index }
                                    onClicked: { panel.selectedSlot = index; panel.editSlot(index); }
                                }
                            }
                        }
                    }
                    Row {
                        width: parent.width; spacing: Commons.Style.space(5)
                        EditorButton { text: "←"; width: Commons.Style.space(38); tooltipText: "Move anticlockwise · Alt+Left"; enabled: !panel.busy; onClicked: panel.moveSlot(panel.selectedSlot, (panel.selectedSlot + panel.actions.length - 1) % panel.actions.length) }
                        EditorButton { text: "→"; width: Commons.Style.space(38); tooltipText: "Move clockwise · Alt+Right"; enabled: !panel.busy; onClicked: panel.moveSlot(panel.selectedSlot, (panel.selectedSlot + 1) % panel.actions.length) }
                        EditorButton { objectName: "orb-remove-slot"; text: "Remove"; enabled: !panel.busy && panel.actions.length > 5; onClicked: panel.removeSlot(panel.selectedSlot) }
                    }
                    EditorButton { objectName: "orb-add-slot"; width: parent.width; text: panel.actions.length < 8 ? "+ Add shortcut · " + panel.actions.length + " / 8" : "8 / 8 shortcuts"; enabled: !panel.busy && panel.actions.length < 8; onClicked: panel.addSlot() }
                    EditorLabel { width: parent.width; wrapMode: Text.WordWrap; text: "↑ ↓ select · Enter edits · Alt+← → moves"; opacity: 0.65; font.pixelSize: Commons.Style.space(10) }
                }
                Column {
                    id: browserColumn
                    visible: panel.browsingActions
                    x: slotColumn.x; y: slotColumn.y; width: slotColumn.width; spacing: Commons.Style.space(8)
                    EditorLabel { width: parent.width; text: "Click to replace slot " + (panel.selectedSlot + 1) + " · drag to any slot"; wrapMode: Text.WordWrap; opacity: 0.65 }
                    ActionPicker {
                        id: actionBrowser
                        width: parent.width; choices: panel.choices; busy: panel.busy; draggable: true; dragSurface: panel
                        listHeight: Commons.Style.space(shortcutsLayout.sideBySide ? 252 : 140)
                        onChosen: action => panel.assignAction(panel.selectedSlot, action)
                        onDragMoved: (action, iconSource, x, y) => {
                            panel.draggedAction = action; panel.draggedIconSource = iconSource; panel.dragPosition = Qt.point(x, y);
                            var point = preview.mapFromItem(panel, x, y);
                            preview.hoverAssignment(action, point.x, point.y);
                        }
                        onDragFinished: (action, x, y) => {
                            var point = preview.mapFromItem(panel, x, y);
                            preview.dropAssignment(action, point.x, point.y); panel.clearAssignment();
                        }
                        onDragCanceled: panel.clearAssignment()
                    }
                }
            }
            Column {
                visible: panel.editingSlot < 0 && panel.tab === 1
                width: parent.width; spacing: Commons.Style.space(14)
                EditorLabel { text: "Wheel shape" }
                Row {
                    width: parent.width; spacing: Commons.Style.space(6)
                    EditorButton { objectName: "orb-shape-circle"; width: (parent.width - parent.spacing) / 2; text: "Circle"; selected: panel.shape === "circle"; enabled: !panel.busy; onClicked: panel.shape = "circle" }
                    EditorButton { objectName: "orb-shape-polygon"; width: (parent.width - parent.spacing) / 2; text: "Polygon · " + panel.actions.length + " sides"; selected: panel.shape === "polygon"; enabled: !panel.busy; onClicked: panel.shape = "polygon" }
                }
                EditorLabel { width: parent.width; text: "Polygon follows your shortcuts. The centre stays circular."; wrapMode: Text.WordWrap; opacity: 0.65 }
                EditorLabel { text: "Wheel size · " + Math.round(Commons.Style.space(panel.diameter)) + " px" }
                Row {
                    width: parent.width; spacing: Commons.Style.space(6)
                    Repeater {
                        model: panel.sizePresets
                        delegate: EditorButton {
                            required property var modelData
                            objectName: "orb-size-" + modelData.name.toLowerCase()
                            width: (parent.width - parent.spacing * 2) / 3; text: modelData.name
                            selected: panel.diameter === modelData.value; enabled: !panel.busy
                            onClicked: panel.diameter = modelData.value
                        }
                    }
                }
                Item {
                    id: sizeControl
                    objectName: "orb-size-slider"
                    width: parent.width; height: Commons.Style.space(34); activeFocusOnTab: true
                    Keys.onLeftPressed: panel.diameter = Math.max(220, panel.diameter - 10)
                    Keys.onRightPressed: panel.diameter = Math.min(600, panel.diameter + 10)
                    Rectangle { anchors.fill: parent; radius: Commons.Style.cornerRadius; color: "transparent"; border.width: sizeControl.activeFocus ? 1 : 0; border.color: Commons.Color.accent }
                    PanelSlider {
                        anchors.fill: parent; enabled: !panel.busy
                        minimum: 220; maximum: 600; step: 10; integer: true; value: panel.diameter
                        trackColor: Commons.Util.alpha(Commons.Color.menu.text, 0.15); fillColor: Commons.Color.accent; knobColor: Commons.Color.accent
                        onMoved: value => { panel.diameter = Math.round(value / 10) * 10; sizeControl.forceActiveFocus(); }
                    }
                }
                EditorButton { text: "Opening animation · " + (panel.animation ? "On" : "Off"); selected: panel.animation; enabled: !panel.busy; onClicked: panel.animation = !panel.animation }
                EditorLabel { width: parent.width; text: "Follows your Omarchy theme and reduced-motion setting."; wrapMode: Text.WordWrap; opacity: 0.65 }
            }
            Column {
                visible: panel.editingSlot < 0 && panel.tab === 2
                width: parent.width; spacing: Commons.Style.space(12)
                EditorLabel { text: "Keyboard shortcut"; font.weight: Font.DemiBold }
                Row {
                    width: parent.width; spacing: Commons.Style.space(6)
                    Repeater {
                        model: [{ label: "Super", bit: 64 }, { label: "Ctrl", bit: 4 }, { label: "Alt", bit: 8 }, { label: "Shift", bit: 1 }]
                        delegate: EditorButton {
                            required property var modelData
                            objectName: "orb-modifier-" + modelData.label
                            text: modelData.label; selected: modelData.bit === 64 || !!((panel.shortcutCheck.mask || 0) & modelData.bit)
                            enabled: !panel.busy && modelData.bit !== 64; onClicked: panel.toggleModifier(modelData.bit)
                        }
                    }
                }
                EditorLabel { text: "Key · letter, number, F1–F12 or Space" }
                TextField {
                    id: openingKey
                    objectName: "orb-opening-key"
                    width: Math.min(parent.width, Commons.Style.space(180)); maximumLength: 5; enabled: !panel.busy
                    text: panel.shortcut.split("+").slice(-1)[0].trim(); placeholderText: "O"
                    onTextEdited: panel.changeKey(text)
                }
                EditorLabel { width: parent.width; wrapMode: Text.WordWrap; text: panel.shortcutCheck.error || panel.shortcutCheck.value; color: panel.shortcutCheck.error ? Commons.Color.urgent : Commons.Color.menu.text }
                EditorLabel { width: parent.width; wrapMode: Text.WordWrap; text: "Orb checks for shortcut conflicts before saving."; opacity: 0.65 }
                EditorButton { objectName: "orb-desktop-click"; text: "Right-click on empty desktop · " + (panel.desktopRightClick ? "On" : "Off"); selected: panel.desktopRightClick; enabled: !panel.busy; onClicked: panel.desktopRightClick = !panel.desktopRightClick }
                EditorLabel { width: parent.width; wrapMode: Text.WordWrap; text: "Applications keep their context menus. On the wallpaper, Orb replaces the right-double-click theme gesture."; opacity: 0.65 }
                EditorButton { objectName: "orb-mouse-button"; text: "Extra mouse button · " + (panel.mouseOpen ? "On" : "Off"); selected: panel.mouseOpen; enabled: !panel.busy; onClicked: panel.mouseOpen = !panel.mouseOpen }
                EditorLabel { width: parent.width; wrapMode: Text.WordWrap; text: "Tap to open Orb, or hold, move and release to launch. The chosen button is used by Orb in other apps too."; opacity: 0.65 }
                EditorLabel { text: "Button code · 275–511" }
                Row {
                    width: parent.width; spacing: Commons.Style.space(6)
                    Repeater {
                        model: [275, 276, 277]
                        delegate: EditorButton {
                            required property int modelData
                            text: "Button " + modelData; selected: panel.mouseButtonText === String(modelData)
                            enabled: !panel.busy; onClicked: panel.mouseButtonText = String(modelData)
                        }
                    }
                }
                TextField {
                    id: mouseCode
                    objectName: "orb-mouse-code"
                    width: Math.min(parent.width, Commons.Style.space(180)); maximumLength: 3; enabled: !panel.busy
                    text: panel.mouseButtonText; placeholderText: "277"
                    onTextEdited: panel.mouseButtonText = text
                }
                EditorLabel { width: parent.width; wrapMode: Text.WordWrap; text: panel.activationError || "Button codes vary by mouse. Use wev to identify yours; left, right and middle click remain available."; color: panel.activationError ? Commons.Color.urgent : Commons.Color.menu.text; opacity: panel.activationError ? 1 : 0.65 }
            }
            TouchOptions {
                id: touchOptions
                visible: panel.editingSlot < 0 && panel.tab === 3
                width: parent.width; busy: panel.busy; status: panel.touchStatus
            }
            ActionEditor {
                id: actionEditor
                visible: panel.editingSlot >= 0; width: parent.width; height: visible ? implicitHeight : 0; busy: panel.busy
                onChosen: (action, origins) => panel.chooseAction(action, origins)
                onCanceled: panel.backToSlots()
            }
        }
    }
    Column {
        id: footer
        x: header.x; y: panel.height - height - Commons.Style.space(18); width: header.width; spacing: Commons.Style.space(8)
        EditorLabel { visible: panel.error !== ""; width: parent.width; text: panel.error; wrapMode: Text.WordWrap; color: Commons.Color.urgent }
        EditorButton { visible: panel.touchFriendly || panel.keyboardShown; text: panel.keyboardShown ? "Hide keyboard" : "Keyboard"; enabled: !panel.busy; onClicked: panel.keyboardToggled() }
        EditorButton { visible: panel.setupFailed; text: "Retry shortcut setup"; enabled: !panel.busy; onClicked: panel.retrySetup() }
        Row {
            visible: panel.editingSlot < 0; width: parent.width; spacing: Commons.Style.space(8)
            EditorButton { objectName: "orb-cancel"; width: (parent.width - parent.spacing) / 2; text: "Cancel"; enabled: !panel.busy; onClicked: panel.canceled() }
            EditorButton { objectName: "orb-save"; width: (parent.width - parent.spacing) / 2; text: panel.busy ? "Saving…" : "Save"; selected: true; enabled: !panel.busy && !panel.shortcutCheck.error && !panel.activationError; onClicked: panel.requestSave() }
        }
    }
    Connections {
        target: panel.Window.window
        enabled: panel.visible && panel.openingHeight === 0
        // Capture the rendered layout, after the columns have been polished.
        function onFrameSwapped() { panel.openingHeight = panel.implicitHeight; }
    }
    Rectangle {
        visible: panel.draggedAction !== null
        x: panel.dragPosition.x + Commons.Style.space(10); y: panel.dragPosition.y + Commons.Style.space(10)
        width: Commons.Style.space(40); height: width; z: 20; radius: Commons.Style.cornerRadius
        color: Commons.Color.menu.selectedBackground
        border.width: 1; border.color: Commons.Color.menu.selectedBorder
        ActionIcon {
            anchors.centerIn: parent; width: Commons.Style.space(26); height: width
            name: panel.draggedAction ? panel.draggedAction.icon : "app"; appSource: panel.draggedIconSource
        }
    }
    Connections {
        target: panel.Window.window
        function onActiveFocusItemChanged() {
            var item = panel.Window.window.activeFocusItem, ancestor = item;
            while (ancestor && ancestor !== body.contentItem) ancestor = ancestor.parent;
            if (!item || !ancestor || item === slotNavigation) return;
            panel.reveal(item);
            if (panel.touchFriendly && typeof item.cursorPosition === "number" && typeof item.text === "string") panel.keyboardRequested();
        }
    }
}
