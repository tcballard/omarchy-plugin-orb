import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model
import "BindingLifecycle.js" as BindingLifecycle
import "Gesture.js" as Gesture
import "TouchModel.js" as TouchModel

Item {
    id: root
    property string omarchyPath: ""
    property var shell: null
    property var manifest: null
    property bool opened: false
    property bool positioned: false
    property bool touchSession: false
    property string touchScreenName: ""
    property bool touchDismissAfter: false
    property var saveOriginal: ({})
    property var saveDraft: ({})
    readonly property bool touchEnabled: TouchModel.active(config.inputMode, touchBackend.capabilities)
    readonly property var touchScreen: TouchModel.output(config.touchOutput || "", Quickshell.screens)
    readonly property var touchReserved: {
        var monitors = Hyprland.monitors.values;
        for (var i = 0; i < monitors.length; i++)
            if (touchScreen && monitors[i].name === touchScreen.name) return monitors[i].lastIpcObject.reserved || [0,0,0,0];
        return [0,0,0,0];
    }
    onTouchEnabledChanged: if (!touchEnabled && touchSession && config.inputMode === "auto") dismiss()
    function openTouch(output) {
        if (shell) shell.summon(pluginId, JSON.stringify({ touch: true, output: output || "" }));
    }
    function saveTouchPosition(value) {
        if (settingsSaving) return;
        saveOriginal = JSON.parse(JSON.stringify(config));
        saveDraft = Object.assign({}, saveOriginal, { touchPosition: value });
        settingsError = ""; settingsSaving = true; saveWatchdog.restart(); reloadForSave();
    }
    function editTouchSlot(index) {
        submenuTitle = ""; agentMenu = false;
        activateHub();
        if (index >= 0) settingsCard.editSlot(index);
    }
    function launchDesktop(entry) {
        if (!entry || !/^[A-Za-z0-9_.@+-]{1,255}$/.test(String(entry.id || ""))) return;
        lastAction = appLibrary.entryName(entry); dismiss();
        pendingDesktopId = String(entry.id); launchDelay.start();
    }
    TouchBackend {
        id: touchBackend
        mode: root.config.inputMode || "desktop"
        viewOpen: root.opened && (root.touchSession || root.settingsOpen)
        keyboardProvider: root.config.touchKeyboard || "auto"
        onCompleted: (kind, success) => {
            if (success && root.touchDismissAfter && kind !== "keyboard") root.dismiss();
            root.touchDismissAfter = false;
        }
    }
    TouchHandle {
        handleEnabled: root.touchEnabled && !root.opened
        targetScreen: root.touchScreen
        edge: root.config.touchEdge || "right"
        position: root.config.touchPosition === undefined ? 0.7 : root.config.touchPosition
        targetScale: root.config.touchScale || 1
        reserved: root.touchReserved
        onSummoned: output => root.openTouch(output)
        onRepositioned: value => root.saveTouchPosition(value)
    }
    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (root.touchSession && root.opened && !Quickshell.screens.some(function(s) { return s.name === root.touchScreenName; })) root.dismiss();
        }
    }
    property var gesture: null
    property bool gestureCentre: false
    property int selected: -1
    property bool keyboardMode: false
    property point pointer: Qt.point(0, 0)
    property var config: ({ actions: [], diameter: 240, animation: true, shape: "circle" })
    property string submenuTitle: ""
    property bool agentMenu: false
    property var submenuRows: []
    property var installedAgents: []
    property string agentError: ""
    property int parentSelection: -1
    readonly property var menuRows: agentMenu ? installedAgents : submenuRows
    property int menuPage: 0
    readonly property int pageCount: submenuTitle ? Math.max(1, Math.ceil(menuRows.length / 6)) : 1
    readonly property var wheelActions: submenuTitle ? menuRows.slice(menuPage * 6, menuPage * 6 + 6) : config.actions
    readonly property int selectionCount: wheelActions.length
    property string configError: ""
    property var pendingCommand: []
    property string pendingDesktopId: ""
    property string lastDispatch: ""
    readonly property var appLibrary: applicationLibrary
    AppLibraryCompat {
        id: applicationLibrary
        nativeLibrary: root.shell ? root.shell.appLibrary : null
        omarchyPath: root.omarchyPath
    }
    property int appRevision: 0
    property string lastAction: ""
    property bool settingsOpen: false
    property bool settingsSaving: false
    property bool settingsReloadPending: false
    property string settingsSaveText: ""
    property string settingsError: ""
    property string shortcut: "SUPER + ALT + O"
    readonly property string bindingOwner: String(Date.now()) + "-" + String(Math.floor(Math.random() * 1000000000)).padStart(9, "0")
    property string bindingSignature: ""
    property string setupError: ""
    property bool setupPending: false
    property bool setupReady: false
    readonly property bool hubActive: gesture ? gestureCentre : keyboardMode ? selected === -2 : wheelMouse.atCentre
    readonly property string pluginId: "io.github.tcballard.orb"
    readonly property string configPath: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omarchy/orb.json"

    function requestSetup() {
        setupPending = true;
        setupDelay.restart();
    }
    function animationDuration(milliseconds) {
        if (!config.animation) return 0;
        // Omarchy 4.0.6 predates Style.duration; newer shells also honour the
        // desktop's reduced-motion setting through this function.
        return typeof Commons.Style.duration === "function" ? Commons.Style.duration(milliseconds) : milliseconds;
    }
    function updateBindings(document) {
        var signature = JSON.stringify(Model.bindingSignature(document));
        if (signature === bindingSignature) return;
        bindingSignature = signature;
        requestSetup();
    }
    Component.onCompleted: requestSetup()
    // The host deletes the checkout after disabling it. Cleanup must be independent
    // of its files, and owner-scoped so an old unload cannot remove new bindings.
    Component.onDestruction: Quickshell.execDetached(["hyprctl", "eval", BindingLifecycle.cleanup(bindingOwner)])
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") root.requestSetup();
            else if (event.name === "custom") root.gestureEvent(event.data);
        }
    }
    Timer {
        id: gestureWatchdog
        interval: 6500
        onTriggered: if (root.gesture) root.dismiss()
    }
    Timer {
        id: setupDelay
        interval: 100
        onTriggered: {
            if (nativeSetup.running) return;
            root.setupPending = false;
            nativeSetup.running = true;
        }
    }
    Process {
        id: nativeSetup
        command: ["bash", decodeURIComponent(Qt.resolvedUrl("scripts/setup").toString().replace(/^file:\/\//, "")), root.bindingOwner]
        stdout: StdioCollector {}
        stderr: StdioCollector { id: setupStderr }
        onExited: (exitCode, exitStatus) => {
            root.setupReady = exitCode === 0;
            root.setupError = exitCode === 0 ? "" : (setupStderr.text.trim().slice(0, 350) || "Orb setup failed. Retry in Orb settings.");
            if (exitCode === 0) userConfig.reload();
            else {
                // Even a conflicting shortcut leaves a reachable in-app error/retry.
                if (root.shell) root.shell.summon(root.pluginId, "{}");
                root.activateHub();
            }
            if (root.setupPending) setupDelay.restart();
        }
    }

    function open(payloadJson) {
        // Payloads deliberately cannot change commands or configuration paths.
        var payload = {};
        try { if (String(payloadJson || "").length <= 4096) payload = JSON.parse(payloadJson || "{}"); } catch (error) {}
        if (!payload || typeof payload !== "object" || Array.isArray(payload)) payload = {};
        touchSession = !gesture && (payload.touch === true || (payload.desktop !== true && touchEnabled));
        var requested = typeof payload.output === "string" ? TouchModel.output(payload.output, Quickshell.screens) : null;
        var target = requested || touchScreen || Quickshell.screens.find(function(s) { return Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name; });
        touchScreenName = touchSession && target ? target.name : "";
        touchHome.reset();
        touchBackend.error = ""; touchDismissAfter = false;
        launchDelay.stop(); pendingCommand = []; pendingDesktopId = "";
        if (settingsReloadPending) settingsSaving = false;
        settingsOpen = false; settingsReloadPending = false;
        selected = -1; keyboardMode = false; positioned = false;
        submenuTitle = ""; agentMenu = false; parentSelection = -1;
        installedAgents = []; agentError = ""; menuPage = 0;
        moveGate.reset();
        if (gesture) {
            pointer = Qt.point(gesture.x, gesture.y); positioned = true;
            cursor.running = false;
        }
        opened = true;
        if (!gesture && !touchSession) { cursor.running = false; cursor.running = true; }
        if (touchSession) positioned = true;
        Qt.callLater(function() { if (root.touchSession) touchHome.forceActiveFocus(); else keys.forceActiveFocus(); });
    }
    function close() {
        opened = false; positioned = false; selected = -1; touchDismissAfter = false;
        gesture = null; gestureCentre = false; gestureWatchdog.stop();
        if (settingsReloadPending) settingsSaving = false;
        settingsOpen = false; settingsReloadPending = false;
        cursor.running = false; launchDelay.stop(); pendingCommand = []; pendingDesktopId = "";
        agents.running = false; submenuTitle = ""; agentMenu = false;
    }
    function dismiss() {
        close();
        if (shell && typeof shell.hide === "function") shell.hide(pluginId);
    }
    function gestureEvent(data) {
        var event = Gesture.parse(data, bindingOwner);
        if (!event || !config.mouseOpen) return;
        if (event.type === "press") {
            if (opened) { dismiss(); return; }
            if (gesture) return;
            gesture = Gesture.begin(event);
            gestureCentre = true; gestureWatchdog.restart();
            if (!shell || typeof shell.summon !== "function" || shell.summon(pluginId, "{}") === false) {
                gesture = null; gestureCentre = false; gestureWatchdog.stop();
            }
        } else if (event.type === "cancel") {
            if (gesture) dismiss();
        } else if (gesture) {
            gesture = Gesture.update(gesture, event);
            updateGestureSelection();
            finishGesture();
        }
    }
    function gesturePoint() {
        if (!gesture || !panel.contentReady || !positioned || !panel.targetMonitor) return null;
        var data = panel.monitorData;
        return wheel.mapFromItem(panel.contentItem, gesture.currentX - (data.x || 0), gesture.currentY - (data.y || 0));
    }
    function updateGestureSelection() {
        var p = gesturePoint();
        if (!p || !gesture) return;
        keyboardMode = false;
        gestureCentre = !gesture.moved || Math.hypot(p.x - wheel.width / 2, p.y - wheel.height / 2) < wheel.width * 0.18;
        selected = gesture.moved ? Model.hit(p.x, p.y, wheel.width, selectionCount, config.shape) : -1;
    }
    function finishGesture() {
        if (!gesture || !gesture.released || !opened || !panel.contentRevealed) return;
        updateGestureSelection();
        var outcome = Gesture.outcome(gesture), index = selected;
        gesture = null; gestureCentre = false; gestureWatchdog.stop(); moveGate.reset();
        if (outcome === "tap") { selected = -1; return; }
        if (outcome !== "select" || index < 0 || index >= selectionCount) { dismiss(); return; }
        activate(index);
    }
    function select(delta) {
        if (!selectionCount) return;
        keyboardMode = true; moveGate.reset();
        selected = selected < 0 ? (delta > 0 ? 0 : selectionCount - 1) : (selected + delta + selectionCount) % selectionCount;
    }
    function turnPage(delta) {
        if (pageCount < 2) return;
        menuPage = (menuPage + delta + pageCount) % pageCount;
        selected = -1; keyboardMode = true; moveGate.reset();
    }
    function back() {
        if (!submenuTitle) { dismiss(); return; }
        agents.running = false; submenuTitle = ""; agentMenu = false;
        selected = parentSelection; keyboardMode = true; moveGate.reset();
    }
    function activate(index) {
        if (opened && index === -2) { activateHub(); return; }
        if (!opened || index < 0 || index >= selectionCount) return;
        var action = wheelActions[index];
        if (action.menu || action.children) {
            parentSelection = index; submenuTitle = action.label;
            agentMenu = action.menu === "agents";
            submenuRows = action.menu === "files" ? Model.fileActions(decodeURIComponent(Qt.resolvedUrl("scripts/files").toString().replace(/^file:\/\//, ""))) : action.children || [];
            selected = -1; menuPage = 0; moveGate.reset();
            if (agentMenu) { agentError = ""; installedAgents = []; agents.running = true; }
            return;
        }
        if (action.desktopId) {
            if (!appLibrary) return;
            lastAction = action.label; dismiss();
            pendingDesktopId = action.desktopId; launchDelay.start();
        } else launchAction(action.command.slice(), action.label);
    }
    function appIconSource(action) {
        var revision = appRevision;
        if (!action.desktopId || !appLibrary) return "";
        var rows = appLibrary.sortedEntries("");
        for (var i = 0; i < rows.length; i++) {
            var entry = rows[i].entry;
            if (entry && String(entry.id) === action.desktopId) return appLibrary.iconSource(String(entry.icon || ""));
        }
        return "";
    }
    function settingsChoices() {
        var choices = [];
        var builtins = Model.parse(defaults.text(), config).config.actions;
        builtins = builtins.concat(builtins[4].children || []);
        builtins.splice(4, 0, { label: "Postcard", icon: "postcard", command: ["omarchy-shell", "shell", "summon", "tahayvr.postcard", "{}"] });
        builtins.push({ label: "Make something cool", icon: "create", children: [
            { label: "New theme", icon: "themes", command: ["omarchy", "agent", "prompt", "Make me a new Omarchy theme. Ask me what look or inspiration I have in mind, then build it following the Omarchy skill's theming guide and switch to it."] },
            { label: "New plugin", icon: "plugins", command: ["omarchy", "agent", "prompt", "Make me a new Omarchy shell plugin. Ask me what I'd like it to do, then build it following the Omarchy skill's plugin guide and enable it."] },
            { label: "New app", icon: "app", command: ["omarchy", "agent", "prompt", "Make me a new app for my Omarchy desktop. Ask me what it should do, then build it following the omarchy-app skill and install it so it shows up in the app launcher."] }
        ] });
        builtins.forEach(function(action) {
            choices.push({ title: action.label, detail: action.menu || action.children ? "Circular submenu" : action.icon === "postcard" ? "Postcard plugin · open editor" : "Omarchy shortcut", action: action });
        });
        if (appLibrary) {
            var rows = appLibrary.sortedEntries("");
            rows.forEach(function(row) {
                var entry = row.entry;
                if (!entry || !/^[A-Za-z0-9_.@+-]{1,255}$/.test(String(entry.id || ""))) return;
                var title = appLibrary.entryName(entry);
                if (!title) return;
                choices.push({ title: title, detail: "App · " + (appLibrary.entrySubtext(entry) || entry.id),
                    iconSource: appLibrary.iconSource(String(entry.icon || "")),
                    action: { label: title.slice(0, 20), icon: "app", desktopId: String(entry.id) } });
            });
        }
        return choices;
    }
    function activateHub() {
        if (!opened) return;
        if (submenuTitle) back();
        else {
            settingsError = "";
            settingsCard.begin(config, settingsChoices());
            settingsOpen = true;
            Qt.callLater(function() { settingsCard.forceActiveFocus(); });
        }
    }
    function cancelSettings() {
        if (settingsReloadPending) settingsSaving = false;
        settingsOpen = false; settingsReloadPending = false;
        selected = -2; keyboardMode = true; moveGate.reset();
        if (touchSession) touchHome.forceActiveFocus(); else keys.forceActiveFocus();
    }
    function saveSettings() {
        if (settingsSaving) return;
        settingsError = "";
        saveOriginal = settingsCard.original;
        saveDraft = settingsCard.draft();
        var checked = Model.parse(JSON.stringify(saveDraft), null);
        if (checked.error) { settingsError = checked.error; return; }
        settingsSaving = true; saveWatchdog.restart();
        if (checked.config.shortcut !== settingsCard.original.shortcut || checked.config.desktopRightClick !== settingsCard.original.desktopRightClick
            || checked.config.mouseOpen !== settingsCard.original.mouseOpen || checked.config.mouseButton !== settingsCard.original.mouseButton)
            bindingCheck.running = true;
        else reloadForSave();
    }
    function reloadForSave() {
        settingsReloadPending = true;
        // Re-read before merging so unrelated and concurrent edits survive.
        userConfig.reload();
    }
    function failSettingsSave(message) {
        settingsSaving = false; settingsReloadPending = false; saveWatchdog.stop(); settingsError = message;
    }
    function finishSettingsSave() {
        if (!settingsSaving) return;
        settingsSaving = false; saveWatchdog.stop();
        config = Model.parse(settingsSaveText, config).config;
        shortcut = config.shortcut; updateBindings(config);
        if (opened && settingsOpen) cancelSettings();
    }
    function launchAction(command, label) {
        lastAction = label;
        dismiss();
        // Let the compositor unmap the exclusive layer before a new UI or screenshot.
        pendingCommand = command; launchDelay.start();
    }
    function status() {
        return JSON.stringify({ opened: opened, positioned: positioned, selected: selected,
            inputMode: config.inputMode, touchEnabled: touchEnabled, touchSession: touchSession,
            touchScreen: touchScreenName, touchPage: touchHome.page,
            touchReady: touchPanel.contentReady, touchError: touchBackend.error,
            touchCapabilities: touchBackend.capabilities, keyboardSpace: touchBackend.keyboardSpace,
            keyboard: keyboardMode, x: wheel.x, y: wheel.y, diameter: wheel.width,
            iconsOnly: true, selectionCaption: hint.text,
            captionFontSize: hint.font.pixelSize, footerHeight: panel.placement.footer,
            hubActive: hubActive,
            settingsOpen: settingsOpen, settingsSaving: settingsSaving, settingsError: settingsError,
            version: settingsCard.version, undoCount: settingsCard.shortcutHistory.length,
            draftActionOrigins: settingsCard.actionOrigins, draftChildOrigins: settingsCard.childOrigins,
            setupReady: setupReady, setupError: setupError,
            settingsX: settingsCard.x, settingsY: settingsCard.y, settingsWidth: settingsCard.width, settingsHeight: settingsCard.height,
            shape: root.config.shape, draftShape: settingsCard.shape,
            draftDiameter: settingsCard.diameter, draftAnimation: settingsCard.animation,
            draftShortcut: settingsCard.shortcut, draftDesktopRightClick: settingsCard.desktopRightClick,
            draftMouseOpen: settingsCard.mouseOpen, draftMouseButton: settingsCard.mouseCheck.value,
            gestureActive: !!gesture, gestureReleased: gesture ? gesture.released : false,
            preview: settingsCard.previewStatus(), selectedSlot: settingsCard.selectedSlot,
            settingsLayout: settingsCard.layoutStatus(),
            settingsControls: root.settingsOpen ? settingsCard.controls() : [],
            editorMode: settingsCard.editor.mode, editingChild: settingsCard.editor.editingChild,
            editorError: settingsCard.editor.error,
            editorLabel: settingsCard.editor.actionLabel, editorProgram: settingsCard.editor.program,
            editorIcon: settingsCard.editor.actionIcon, editorDepth: settingsCard.editor.depth,
            editorArguments: settingsCard.editor.commandArguments, editorChildren: settingsCard.editor.submenuActions,
            draftActions: settingsCard.actions, settingsTab: settingsCard.tab, editingSlot: settingsCard.editingSlot,
            pickerItems: settingsCard.pickerTitles(), browsingActions: settingsCard.browsingActions,
            appLibraryFallback: applicationLibrary.fallback, catalogAppCount: settingsCard.choices.filter(function(c) { return !!c.action.desktopId; }).length,
            screen: panel.targetScreen ? panel.targetScreen.name : "", error: configError,
            foreground: String(Commons.Color.menu.text), background: String(Commons.Color.menu.background),
            lastAction: lastAction, lastDispatch: lastDispatch, pendingDesktopId: pendingDesktopId, launchPending: launchDelay.running,
            ready: panel.contentReady, revealed: panel.contentRevealed,
            opacity: wheel.opacity, visible: wheel.visible, windowWidth: panel.width, windowHeight: panel.height,
            scale: panel.devicePixelRatio, monitorScale: panel.targetMonitor ? panel.targetMonitor.scale : 0,
            submenu: submenuTitle, items: menuRows.map(function(a) { return a.label; }), loading: agents.running,
            menuX: wheel.x, menuY: wheel.y, menuWidth: wheel.width, menuHeight: wheel.height,
            page: menuPage, pages: pageCount, visibleItems: wheelActions.map(function(a) { return a.label; }), agentError: agentError });
    }
    FileView {
        id: defaults
        path: Qt.resolvedUrl("config.example.json")
        onLoaded: {
            root.config = Model.parse(text(), root.config).config;
            userConfig.reload();
        }
    }
    FileView {
        id: userConfig
        path: root.configPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            var parsed = Model.parse(text(), root.config);
            root.config = parsed.config; root.configError = parsed.error;
            if (!parsed.error) {
                var current = JSON.parse(text());
                root.shortcut = parsed.config.shortcut;
                root.updateBindings(current);
            }
            if (root.settingsReloadPending) {
                root.settingsReloadPending = false;
                if (parsed.error) {
                    root.failSettingsSave("Could not read your settings. Nothing was saved.");
                    return;
                }
                var document = JSON.parse(text());
                var merged = Model.mergeSettings(document, root.saveOriginal, root.saveDraft);
                if (merged.error) {
                    root.failSettingsSave(merged.error); return;
                }
                root.settingsSaveText = JSON.stringify(merged.document, null, 2) + "\n";
                // FileView skips identical text without emitting saved().
                if (root.settingsSaveText === text()) root.finishSettingsSave();
                else Qt.callLater(function() { userConfig.setText(root.settingsSaveText); });
            }
        }
        onLoadFailed: {
            if (root.settingsReloadPending) {
                root.failSettingsSave("Could not read your settings. Nothing was saved.");
            }
        }
        atomicWrites: true
        onSaved: root.finishSettingsSave()
        onSaveFailed: {
            if (root.settingsSaving) root.failSettingsSave("Could not save. Your changes are still here.");
        }
    }
    Timer {
        id: saveWatchdog
        interval: 5000
        onTriggered: if (root.settingsSaving) root.failSettingsSave("Could not save. Your changes are still here.")
    }
    Process {
        id: bindingCheck
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector { id: existingBindings }
        onExited: (code, status) => {
            if (!root.settingsSaving) return;
            var error = "Could not check existing shortcuts. Try saving again.";
            if (code === 0) try {
                var opening = settingsCard.draft();
                error = Model.bindingConflict(JSON.parse(existingBindings.text), opening.shortcut, opening.desktopRightClick, opening.mouseOpen, opening.mouseButton);
            } catch (failure) {}
            if (error) root.failSettingsSave(error);
            else root.reloadForSave();
        }
    }
    Process {
        id: cursor
        command: ["hyprctl", "-j", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.opened) return;
                try {
                    var p = JSON.parse(text);
                    if (!isFinite(p.x) || !isFinite(p.y)) throw new Error("Invalid pointer");
                    root.pointer = Qt.point(p.x, p.y);
                } catch (error) {
                    var s = panel.targetScreen;
                    root.pointer = Qt.point(s ? s.x + s.width / 2 : 0, s ? s.y + s.height / 2 : 0);
                }
                root.positioned = true;
            }
        }
        onExited: {
            if (root.opened && !root.positioned) {
                var s = panel.targetScreen;
                root.pointer = Qt.point(s ? s.x + s.width / 2 : 0, s ? s.y + s.height / 2 : 0);
                root.positioned = true;
            }
        }
    }
    Timer {
        id: launchDelay
        interval: 120
        onTriggered: {
            if (root.pendingDesktopId) {
                var desktopId = root.pendingDesktopId; root.pendingDesktopId = "";
                root.lastDispatch = "app:" + desktopId;
                if (root.appLibrary) root.appLibrary.launch(desktopId, root.lastAction);
                return;
            }
            var args = [Qt.resolvedUrl("scripts/launch").toString().replace(/^file:\/\//, ""), root.lastAction].concat(root.pendingCommand);
            root.lastDispatch = "command:" + root.lastAction;
            root.pendingCommand = [];
            Quickshell.execDetached(args);
        }
    }
    Connections {
        target: root.appLibrary
        function onAppsChanged() {
            root.appRevision++;
            if (root.settingsOpen) settingsCard.choices = root.settingsChoices();
            touchHome.refreshApps();
        }
    }
    Connections {
        target: panel
        function onContentReadyChanged() { if (panel.contentReady) root.updateGestureSelection(); }
        function onContentRevealedChanged() {
            if (panel.contentRevealed) {
                root.updateGestureSelection(); root.finishGesture();
                if (root.settingsOpen) Qt.callLater(touchBackend.raiseKeyboard);
            }
        }
    }
    Process {
        id: agents
        command: [Qt.resolvedUrl("scripts/agents").toString().replace(/^file:\/\//, "")]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.opened || !root.agentMenu) return;
                try {
                    var rows = JSON.parse(text);
                    if (!Array.isArray(rows) || rows.length > 24) throw new Error("Invalid catalog");
                    var checked = rows.map(function(a) { return Model.action(a, 1); });
                    if (checked.some(function(a) { return !a; })) throw new Error("Invalid action");
                    root.installedAgents = checked;
                } catch (error) { root.agentError = "Could not read installed agents"; }
            }
        }
        onExited: (code, status) => {
            if (root.opened && root.agentMenu && code !== 0) root.agentError = "Could not read installed agents";
        }
    }
    IpcHandler {
        target: root.pluginId
        function status(): string { return root.status(); }
    }
    OrbOverlay {
        id: touchPanel
        shown: root.opened && root.touchSession && !root.settingsOpen
        requestedScreen: root.touchScreenName
        respectReserved: true
        shownKeyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "omarchy-orb-touch"
        onContentRevealedChanged: if (contentRevealed) Qt.callLater(touchBackend.raiseKeyboard)
        TouchHome {
            id: touchHome
            x: Math.max(8, (parent.width - width) / 2); y: 8
            width: Math.min(900, Math.max(1, parent.width - 16))
            height: Math.max(1, parent.height - 16 - (touchBackend.keyboardSpace ? Math.min(330, parent.height * 0.42) : 0))
            controller: root; backend: touchBackend; screenName: root.touchScreenName
            onDismissed: root.dismiss()
            onSettingsRequested: slot => root.editTouchSlot(slot)
        }
    }
    OrbOverlay {
        id: panel
        shown: root.opened && (!root.touchSession || root.settingsOpen)
        requestedScreen: root.touchSession ? root.touchScreenName : ""
        respectReserved: root.settingsOpen
        preferPointerScreen: !!root.gesture
        openingPointer: root.pointer
        shownKeyboardFocus: root.settingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "omarchy-plugin-orb"
        readonly property var monitorData: targetMonitor ? targetMonitor.lastIpcObject : ({})
        readonly property var placement: Model.placement(
            root.pointer.x - (monitorData.x || 0), root.pointer.y - (monitorData.y || 0),
            width, height, monitorData.reserved || [0,0,0,0], Commons.Style.space(root.config.diameter))

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: root.dismiss()
        }
        Item {
            id: keys
            anchors.fill: parent
            focus: root.opened
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape || event.key === Qt.Key_Backspace || (root.submenuTitle && event.key === Qt.Key_Left)) root.back();
                else if (event.key === Qt.Key_Home) { root.keyboardMode = true; root.selected = -2; moveGate.reset(); }
                else if (event.key === Qt.Key_PageDown) root.turnPage(1);
                else if (event.key === Qt.Key_PageUp) root.turnPage(-1);
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.activate(root.selected);
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) root.select(1);
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || event.key === Qt.Key_Tab) root.select(-1);
                else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9 && event.key - Qt.Key_1 < root.selectionCount) {
                    root.keyboardMode = true; moveGate.reset(); root.selected = event.key - Qt.Key_1;
                } else return;
                event.accepted = true;
            }
        }
        Item {
            id: wheel
            x: panel.placement.x
            y: panel.placement.y
            width: panel.placement.size
            height: width
            readonly property real captionScale: panel.placement.captionScale
            visible: root.positioned && !root.settingsOpen
            opacity: root.opened && root.positioned && panel.contentRevealed ? 1 : 0
            scale: opacity > 0 ? 1 : 0.92
            Behavior on opacity { NumberAnimation { duration: root.animationDuration(150) } }
            Behavior on scale { NumberAnimation { duration: root.animationDuration(190); easing.type: Easing.OutCubic } }

            WheelSurface {
                id: ring
                anchors.fill: parent
                shape: root.config.shape || "circle"
                count: root.selectionCount
                selection: root.selected
            }
            Repeater {
                model: root.wheelActions
                delegate: Item {
                    required property int index
                    required property var modelData
                    readonly property real angle: (index * 360 / root.selectionCount - 90) * Math.PI / 180
                    readonly property bool chosen: root.selected === index
                    width: wheel.width * (root.selectionCount > 6 ? 0.24 : 0.28)
                    height: Math.max(24, wheel.width * 0.09)
                    x: wheel.width/2 + Math.cos(angle) * wheel.width * 0.33 - width/2
                    y: wheel.height/2 + Math.sin(angle) * wheel.width * 0.33 - height/2
                    ActionIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 0; width: parent.height; height: width
                        name: modelData.icon
                        appSource: root.appIconSource(modelData)
                        selected: parent.chosen
                        ink: Commons.Color.menu.text
                    }
                }
            }
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.32; height: width; radius: width / 2
                color: root.hubActive ? Commons.Color.menu.selectedBackground : Commons.Color.menu.background
                border.width: 1
                border.color: root.hubActive ? Commons.Color.menu.selectedBorder : Commons.Util.alpha(Commons.Color.menu.text, 0.18)
                Behavior on color { ColorAnimation { duration: root.animationDuration(140) } }
                Behavior on border.color { ColorAnimation { duration: root.animationDuration(140) } }
                Image {
                    id: omarchyMark
                    anchors.centerIn: parent
                    width: parent.width * 0.42; height: width
                    source: Qt.resolvedUrl("assets/omarchy-logo.svg")
                    sourceSize.width: Math.ceil(width * 2)
                    sourceSize.height: Math.ceil(height * 2)
                    fillMode: Image.PreserveAspectFit
                    visible: false
                    layer.enabled: true
                }
                MultiEffect {
                    anchors.fill: omarchyMark
                    source: omarchyMark
                    visible: !root.submenuTitle
                    colorization: 1.0
                    colorizationColor: root.hubActive ? "#ffffff" : Commons.Color.menu.text
                    brightness: root.hubActive ? 1.0 : 0.0
                    shadowEnabled: true
                    shadowColor: Commons.Color.menu.selectedBorder
                    shadowBlur: 0.65
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                    shadowOpacity: root.hubActive ? 0.85 : 0
                    Behavior on shadowOpacity { NumberAnimation { duration: root.animationDuration(140) } }
                }
                LineIcon {
                    visible: !!root.submenuTitle
                    anchors.centerIn: parent
                    width: parent.width * 0.42; height: width
                    name: "arrow-undo"
                    ink: root.hubActive ? "#ffffff" : Commons.Color.menu.text
                }
            }
            PointerMoveGate { id: moveGate; referenceItem: wheel }
            MouseArea {
                id: wheelMouse
                readonly property bool atCentre: containsMouse && Math.hypot(mouseX - width/2, mouseY - height/2) < width * 0.18
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.AllButtons
                cursorShape: (root.selected >= 0 && !root.keyboardMode) || atCentre ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPositionChanged: mouse => {
                    if (root.gesture) return;
                    if (!moveGate.moved(this, mouse)) return;
                    root.keyboardMode = false;
                    root.selected = Model.hit(mouse.x, mouse.y, width, root.selectionCount, root.config.shape);
                }
                onExited: if (!root.gesture && !root.keyboardMode) root.selected = -1
                onClicked: mouse => {
                    var i = Model.hit(mouse.x, mouse.y, width, root.selectionCount, root.config.shape);
                    if (mouse.button === Qt.LeftButton && i >= 0) root.activate(i);
                    else if (mouse.button === Qt.LeftButton && atCentre) root.activateHub();
                    else root.dismiss();
                }
                onWheel: event => { root.turnPage(event.angleDelta.y < 0 ? 1 : -1); event.accepted = true; }
            }
            Rectangle {
                anchors.top: parent.bottom; anchors.topMargin: 8 * wheel.captionScale
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(wheel.width, hint.implicitWidth + (root.pageCount > 1 ? 72 : 24) * wheel.captionScale)
                height: 28 * wheel.captionScale; radius: height / 2
                color: Commons.Color.menu.background
                border.width: 1; border.color: Commons.Util.alpha(Commons.Color.menu.text, 0.16)
                Text {
                    id: hint; anchors.centerIn: parent
                    width: parent.width - (root.pageCount > 1 ? 64 : 20) * wheel.captionScale
                    horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                    text: root.configError ? "Config error · using last valid actions"
                        : root.gesture && root.selected < 0 ? "Release to cancel · tap to open"
                        : root.selected >= 0 && root.selected < root.selectionCount ? root.wheelActions[root.selected].label
                        : !root.submenuTitle && root.hubActive ? "Orb settings · click to open"
                        : root.submenuTitle && root.hubActive ? "Back to main wheel"
                        : root.submenuTitle && !root.selectionCount ? (agents.running ? "Finding installed agents…" : root.agentError || "No supported agents installed")
                        : root.pageCount > 1 ? "Page " + (root.menuPage + 1) + " / " + root.pageCount
                        : root.submenuTitle ? "Centre to go back · Enter to launch" : "Select · click or Enter"
                    textFormat: Text.PlainText
                    font.family: Commons.Style.font.menuFamily; font.pixelSize: Math.round(11 * wheel.captionScale)
                    color: root.configError ? Commons.Color.urgent : root.selected >= 0 ? Commons.Color.menu.text : Commons.Util.alpha(Commons.Color.menu.text, 0.7)
                }
                Repeater {
                    model: root.pageCount > 1 ? 2 : 0
                    delegate: Item {
                        required property int index
                        x: index === 0 ? 0 : parent.width - width
                        width: 32 * wheel.captionScale; height: parent.height
                        Text { anchors.centerIn: parent; text: index === 0 ? "‹" : "›"; font.pixelSize: Math.round(22 * wheel.captionScale); color: Commons.Color.menu.text }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.turnPage(index === 0 ? -1 : 1) }
                    }
                }
            }
        }
        SettingsPanel {
            id: settingsCard
            version: root.manifest ? String(root.manifest.version || "") : ""
            visible: root.opened && root.positioned && root.settingsOpen
            readonly property var reserved: panel.respectReserved ? [0, 0, 0, 0] : panel.monitorData.reserved || [0, 0, 0, 0]
            readonly property rect availableArea: Qt.rect(reserved[0] + 12, reserved[1] + 12,
                Math.max(1, panel.width - reserved[0] - reserved[2] - 24),
                Math.max(1, panel.height - reserved[1] - reserved[3] - 24 - (touchBackend.keyboardSpace ? Math.min(330, panel.height * 0.42) : 0)))
            width: Math.min(Commons.Style.space(680), availableArea.width)
            maximumHeight: availableArea.height
            x: Math.round(availableArea.x + (availableArea.width - width) / 2)
            y: Math.round(availableArea.y + (availableArea.height - height) / 2)
            appLibrary: root.appLibrary
            busy: root.settingsSaving
            error: root.settingsError || root.setupError || touchBackend.error
            setupFailed: root.setupError !== ""
            touchFriendly: root.touchSession
            touchStatus: touchBackend.capabilities
            keyboardShown: touchBackend.keyboardSpace
            onKeyboardRequested: touchBackend.keyboard(true)
            onKeyboardToggled: touchBackend.keyboard(!touchBackend.keyboardSpace)
            onRetrySetup: root.requestSetup()
            onSaveRequested: root.saveSettings()
            onCanceled: root.cancelSettings()
        }
    }
}
