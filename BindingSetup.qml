import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model
import "BindingLifecycle.js" as BindingLifecycle

// Owns registration of Orb's session-only Hyprland bindings through
// scripts/setup, and owner-scoped teardown when the menu unloads.
Item {
    id: setup
    required property string helper
    // Unique per menu instance; stale instances cannot remove newer bindings.
    readonly property string owner: String(Date.now()) + "-" + String(Math.floor(Math.random() * 1000000000)).padStart(9,
                                                                                                                       "0")
    property string signature: ""
    property string error: ""
    property bool pending: false
    property bool ready: false
    signal succeeded
    signal failed

    function request() {
        pending = true;
        delay.restart();
    }
    // Re-register only when the binding-relevant settings change.
    function update(document) {
        var next = JSON.stringify(Model.bindingSignature(document));
        if (next === signature)
            return;
        signature = next;
        request();
    }

    Component.onCompleted: request()
    // The host deletes the checkout after disabling it. Cleanup must be independent
    // of its files, and owner-scoped so an old unload cannot remove new bindings.
    Component.onDestruction: Quickshell.execDetached(["hyprctl", "eval", BindingLifecycle.cleanup(owner)])

    Timer {
        id: delay
        interval: 100
        onTriggered: {
            if (process.running)
                return;
            setup.pending = false;
            process.running = true;
        }
    }
    Process {
        id: process
        command: ["bash", setup.helper, setup.owner]
        stdout: StdioCollector {}
        stderr: StdioCollector {
            id: stderr
        }
        onExited: (exitCode, exitStatus) => {
            setup.ready = exitCode === 0;
            setup.error = exitCode === 0 ? "" : (stderr.text.trim().slice(0, 350)
                                                 || "Orb setup failed. Retry in Orb settings.");
            if (exitCode === 0)
                setup.succeeded();
            else
                setup.failed();
            if (setup.pending)
                delay.restart();
        }
    }
}
