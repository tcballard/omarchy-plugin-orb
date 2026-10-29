import QtQuick
import Quickshell
import Quickshell.Io
import "TouchModel.js" as TouchModel

Item {
    id: backend
    property string mode: "desktop"
    property bool viewOpen: false
    property var capabilities: ({ ok: false })
    property var windows: []
    property var workspaces: []
    property string error: ""
    property bool keyboardSpace: false
    property string keyboardProvider: "auto"
    property int generation: 0
    property int requestGeneration: 0
    property string requestKind: ""
    property var current: []
    property bool actionPending: false
    property string pendingKeyboard: ""
    readonly property bool busy: actionPending
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("scripts/touch").toString().replace(/^file:\/\//, ""))
    signal completed(string kind, bool success)

    function refresh() {
        if (statusProcess.running) return;
        statusProcess.running = true;
    }
    function refreshWindows() {
        if (viewOpen && !windowProcess.running) { windowProcess.ticket = generation; windowProcess.running = true; }
    }
    function cancelView() {
        generation++;
        pendingKeyboard = "";
        windowProcess.running = false;
        action.running = false;
    }
    function run(args) {
        if (actionPending) return false;
        error = ""; current = args; requestKind = String(args[0]); requestGeneration = generation;
        action.command = ["bash", helper].concat(args);
        action.timedOut = false; actionPending = true;
        action.running = true;
        return true;
    }
    function keyboard(show, raise) {
        if (show && keyboardSpace && !raise) return;
        if (busy) { pendingKeyboard = show ? "show" : "hide"; return; }
        run(["keyboard", keyboardProvider, show ? "show" : "hide"]);
    }
    function raiseKeyboard() { if (viewOpen && keyboardSpace) keyboard(true, true); }
    onModeChanged: { capabilities = { ok: false }; if (mode === "auto") refresh(); }
    onViewOpenChanged: {
        if (viewOpen) { refresh(); refreshWindows(); }
        else cancelView();
    }
    Component.onCompleted: if (mode === "auto") refresh()
    Timer { interval: 5000; repeat: true; running: backend.mode === "auto"; onTriggered: backend.refresh() }
    Timer { interval: 3000; repeat: true; running: backend.viewOpen; onTriggered: backend.refreshWindows() }
    FileView {
        path: backend.mode === "auto" ? (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omarchy/tablet-mode/folded" : ""
        watchChanges: true; printErrors: false
        onFileChanged: backend.refresh()
    }
    Process {
        id: statusProcess
        command: ["bash", backend.helper, "status"]
        stdout: StdioCollector { id: statusOutput }
        onExited: (code, status) => {
            try {
                var result = JSON.parse(statusOutput.text);
                backend.capabilities = code === 0 && result.ok === true ? result : { ok: false };
                if (backend.viewOpen && !result.ok) backend.error = String(result.error || "Touch integrations are unavailable.").slice(0, 250);
            } catch (e) {
                backend.capabilities = { ok: false };
                if (backend.viewOpen) backend.error = "Could not read touch integrations.";
            }
        }
    }
    Process {
        id: windowProcess
        property int ticket: 0
        command: ["bash", backend.helper, "windows"]
        stdout: StdioCollector { id: windowOutput }
        onExited: (code, status) => {
            if (!backend.viewOpen || ticket !== backend.generation) return;
            try {
                var result = JSON.parse(windowOutput.text);
                if (code !== 0 || !result.ok || !Array.isArray(result.workspaces)) throw new Error(result.error || "Could not read windows.");
                backend.windows = TouchModel.windows(result.windows);
                backend.workspaces = result.workspaces.slice(0, 100);
            } catch (e) { backend.error = String(e.message).slice(0, 250); }
        }
    }
    Process {
        id: action
        property bool timedOut: false
        stdout: StdioCollector { id: actionOutput }
        onExited: (code, status) => {
            backend.actionPending = false;
            var ok = false, message = "The action did not complete.";
            try {
                var result = JSON.parse(actionOutput.text);
                ok = code === 0 && result.ok === true;
                message = String(result.error || message).slice(0, 250);
            } catch (e) {}
            if (timedOut) { ok = false; message = "The action timed out. Retry when the service responds."; }
            if (backend.requestGeneration === backend.generation) {
                if (!ok) backend.error = message;
                if (ok && backend.requestKind === "keyboard") backend.keyboardSpace = backend.current[2] === "show";
                backend.completed(backend.requestKind, ok);
                if (ok) { backend.refresh(); backend.refreshWindows(); }
            }
            if (backend.pendingKeyboard && backend.viewOpen) {
                var show = backend.pendingKeyboard === "show", ticket = backend.generation;
                backend.pendingKeyboard = "";
                Qt.callLater(function() { if (backend.viewOpen && backend.generation === ticket) backend.keyboard(show, true); });
            }
        }
    }
    Timer {
        interval: 15000; running: action.running
        onTriggered: { action.timedOut = true; backend.error = "The action timed out. Retry when the service responds."; action.running = false; }
    }
    Timer { interval: 15000; running: statusProcess.running; onTriggered: { backend.capabilities = { ok: false }; statusProcess.running = false; } }
    Timer { interval: 10000; running: windowProcess.running; onTriggered: { backend.error = "Window discovery timed out."; windowProcess.running = false; } }
}
