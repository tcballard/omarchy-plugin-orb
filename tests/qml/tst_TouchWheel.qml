import QtQuick
import QtTest
import "../.." as Orb

TestCase {
    id: testCase
    name: "OrbTouchWheel"
    width: 800; height: 800
    when: windowShown
    Orb.TouchWheel {
        id: wheel
        width: 744; height: 744; shape: "ring"
        actions: [0,1,2,3,4,5].map(function(i) { return {label:"Action " + i,icon:"terminal"}; })
    }
    SignalSpy { id: launched; target: wheel; signalName: "activated" }
    SignalSpy { id: edited; target: wheel; signalName: "edited" }
    function init() {
        wheel.width = 744; wheel.height = 744; wheel.shape = "ring"; wheel.dragSelection = false;
        wheel.cancel(); launched.clear(); edited.clear(); waitForRendering(wheel);
    }
    function test_pointer_tap() {
        var p = wheel.geometry.points[2];
        mouseClick(wheel, p.x, p.y);
        compare(launched.count, 1); compare(launched.signalArguments[0][0], 2);
    }
    function test_raw_touch_tap_once() {
        var p = wheel.geometry.points[1];
        touchEvent(wheel).press(0, wheel, p.x, p.y).commit();
        touchEvent(wheel).release(0, wheel, p.x, p.y).commit();
        compare(launched.count, 1); compare(launched.signalArguments[0][0], 1);
    }
    function test_drag_requires_opt_in_and_can_cancel() {
        var a = wheel.geometry.points[0], b = wheel.geometry.points[3];
        mousePress(wheel, a.x, a.y); mouseMove(wheel, b.x, b.y); mouseRelease(wheel, b.x, b.y);
        compare(launched.count, 0);
        wheel.dragSelection = true;
        mousePress(wheel, a.x, a.y); mouseMove(wheel, b.x, b.y); mouseRelease(wheel, b.x, b.y);
        compare(launched.count, 1); compare(launched.signalArguments[0][0], 3);
        launched.clear();
        mousePress(wheel, a.x, a.y); mouseMove(wheel, 0, 0); mouseRelease(wheel, 0, 0);
        compare(launched.count, 0);
    }
    function test_long_press_edits_without_launching() {
        var p = wheel.geometry.points[0];
        mousePress(wheel, p.x, p.y); wait(650); mouseRelease(wheel, p.x, p.y);
        compare(edited.count, 1); compare(launched.count, 0);
    }
    function test_short_viewport_keeps_scrollable_touch_targets() {
        wheel.width = 320; wheel.height = 220; waitForRendering(wheel);
        verify(wheel.geometry.grid); compare(wheel.geometry.size, 76);
        mouseClick(wheel, 52, 52);
        compare(launched.count, 1); compare(launched.signalArguments[0][0], 0);
    }
    function test_rotation_cancels_in_progress_touch() {
        var p = wheel.geometry.points[0];
        mousePress(wheel, p.x, p.y); wheel.width = 500; mouseRelease(wheel, p.x, p.y);
        compare(launched.count, 0);
    }
}
