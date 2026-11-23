import QtQuick
import QtTest
import Quickshell
import "../.." as Orb

TestCase {
    id: tests
    name: "OrbBindingSetup"
    when: windowShown
    Component {
        id: setupComponent
        Orb.BindingSetup { helper: "/opt/My plugins/orb/scripts/setup" }
    }
    SignalSpy { id: succeeded; signalName: "succeeded" }
    SignalSpy { id: failed; signalName: "failed" }

    function create() {
        var setup = createTemporaryObject(setupComponent, tests);
        succeeded.target = setup; failed.target = setup;
        succeeded.clear(); failed.clear();
        return setup;
    }
    function processOf(setup) {
        for (var i = 0; i < setup.data.length; i++)
            if (setup.data[i].command !== undefined) return setup.data[i];
        return null;
    }

    function test_registers_once_with_owner_and_reports_success() {
        var setup = create(), process = processOf(setup);
        verify(/^\d+-\d{9}$/.test(setup.owner));
        tryCompare(process, "running", true);
        compare(process.command, ["bash", "/opt/My plugins/orb/scripts/setup", setup.owner]);
        process.running = false; process.exited(0, 0);
        compare(setup.ready, true); compare(setup.error, ""); compare(succeeded.count, 1);
    }
    function test_failure_surfaces_bounded_error_and_retry() {
        var setup = create(), process = processOf(setup);
        tryCompare(process, "running", true);
        process.stderr.text = "Shortcut SUPER + ALT + O conflicts";
        process.running = false; process.exited(1, 0);
        compare(setup.ready, false); compare(failed.count, 1);
        compare(setup.error, "Shortcut SUPER + ALT + O conflicts");
        process.stderr.text = "";
        setup.request(); tryCompare(process, "running", true);
        process.running = false; process.exited(1, 0);
        compare(setup.error, "Orb setup failed. Retry in Orb settings.");
    }
    function test_unchanged_binding_settings_do_not_reregister() {
        var setup = create(), process = processOf(setup);
        tryCompare(process, "running", true); process.running = false; process.exited(0, 0);
        var document = {shortcut: "SUPER + ALT + O", actions: []};
        setup.update(document); compare(setup.pending, true);
        tryCompare(process, "running", true); process.running = false; process.exited(0, 0);
        setup.update(document); compare(setup.pending, false);
    }
    function test_request_during_run_queues_one_rerun() {
        var setup = create(), process = processOf(setup);
        tryCompare(process, "running", true);
        setup.request(); wait(150);
        compare(setup.pending, true);
        process.running = false; process.exited(0, 0);
        tryCompare(process, "running", true); compare(setup.pending, false);
    }
    function test_disable_tears_down_and_enable_registers_a_new_owner() {
        var setup = create(), process = processOf(setup);
        tryCompare(process, "running", true); process.running = false; process.exited(0, 0);
        var first = setup.owner, before = Quickshell.detached.length;
        setup.active = false;
        compare(setup.ready, false);
        compare(Quickshell.detached.length, before + 1);
        verify(Quickshell.detached[before][2].indexOf(first) >= 0);
        setup.request(); wait(150);
        compare(process.running, false); compare(setup.pending, false);
        setup.active = true;
        verify(setup.owner !== first);
        tryCompare(process, "running", true);
        compare(process.command[2], setup.owner);
        process.running = false; process.exited(0, 0);
        compare(setup.ready, true);
    }
    function test_run_finishing_after_disable_reports_nothing() {
        var setup = create(), process = processOf(setup);
        tryCompare(process, "running", true);
        setup.active = false;
        process.running = false; process.exited(1, 0);
        compare(failed.count, 0); compare(setup.error, ""); compare(setup.ready, false);
    }
    function test_unload_tears_down_owned_bindings() {
        var setup = create(), owner = setup.owner, before = Quickshell.detached.length;
        setup.destroy(); wait(0);
        compare(Quickshell.detached.length, before + 1);
        var command = Quickshell.detached[before];
        compare(command[0], "hyprctl"); compare(command[1], "eval");
        verify(command[2].indexOf(owner) >= 0);
    }
}
