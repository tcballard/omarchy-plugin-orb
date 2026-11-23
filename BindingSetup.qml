import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model
import "BindingLifecycle.js" as BindingLifecycle

// Owns registration of Orb's session-only Hyprland bindings through
// scripts/setup, and owner-scoped teardown when the menu unloads or the plugin
// is disabled while its instance stays loaded.
Item {
    id: setup
    required property string helper
    // False while the plugin is disabled: bindings are torn down and requests ignored.
    property bool active: true
    // Unique per registration lifetime; stale owners cannot remove newer bindings.
    // Teardown tombstones an owner, so reactivation always takes a new one.
    property string owner: newOwner()
    property string signature: ""
    property string error: ""
    property bool pending: false
    property bool ready: false
    signal succeeded
    signal failed

    function newOwner() {
        return String(Date.now()) + "-" + String(Math.floor(Math.random() * 1000000000)).padStart(9, "0");
    }
    function teardown() {
        Quickshell.execDetached(["hyprctl", "eval", BindingLifecycle.cleanup(owner)]);
    }
    function request() {
        if (!active)
            return;
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

    onActiveChanged: {
        if (active) {
            owner = newOwner();
            request();
            return;
        }
        delay.stop();
        pending = false;
        ready = false;
        error = "";
        teardown();
    }

    Component.onCompleted: request()
    // The host deletes the checkout after disabling it. Cleanup must be independent
    // of its files, and owner-scoped so an old unload cannot remove new bindings.
    Component.onDestruction: teardown()

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
            // A run that finishes after deactivation was tombstoned; report nothing.
            if (!setup.active)
                return;
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
