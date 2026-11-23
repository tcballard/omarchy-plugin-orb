import QtQuick
import QtTest
import Quickshell
import "../.." as Orb

TestCase {
    id: tests
    name: "OrbActionIcon"
    visible: true
    width: 100; height: 100
    when: windowShown
    Component {
        id: iconComponent
        Orb.ActionIcon { width: 32; height: 32 }
    }
    function initTestCase() {
        var root = Qt.resolvedUrl("fixtures/omarchy").toString().replace(/^file:\/\//, "");
        Quickshell.environment = { OMARCHY_PATH: decodeURIComponent(root) };
    }
    function mark(icon) {
        for (var i = 0; i < icon.children.length; i++)
            if (icon.children[i].sourceSize !== undefined) return icon.children[i];
        return null;
    }
    function create(name) {
        return createTemporaryObject(iconComponent, tests, { name: name });
    }

    function test_installed_omarchy_mark_is_used_for_new_agents() {
        var image = mark(create("qwen"));
        tryCompare(image, "status", Image.Ready);
        verify(image.source.toString().indexOf("fixtures/omarchy/shell/plugins/agents/assets/qwen.svg") >= 0);
        compare(image.visible, true);
    }
    function test_missing_mark_falls_back_to_bundled_copy() {
        var image = mark(create("claude"));
        tryCompare(image, "status", Image.Ready);
        verify(image.source.toString().indexOf("assets/agents/claude.svg") >= 0);
        verify(image.source.toString().indexOf("fixtures") < 0);
    }
    function test_agent_without_any_mark_uses_the_generic_icon() {
        var icon = create("opencode"), image = mark(icon);
        tryVerify(function () { return icon.markIndex === icon.markSources.length; });
        compare(image.visible, false);
    }
    function test_unknown_names_are_not_treated_as_agent_marks() {
        var icon = create("pi");
        compare(icon.branded, false);
        compare(icon.markSources.length, 0);
    }
}
