import QtQuick
import QtTest
import "../.." as Orb

TestCase {
    name: "OrbCustomIconEditor"
    visible: true; width: 760; height: 1100; when: windowShown
    Orb.ActionEditor { id: editor; width: 700 }
    readonly property string iconPath: decodeURIComponent(Qt.resolvedUrl("fixtures/custom icon.svg").toString().slice(7))
    SignalSpy { id: chosen; target: editor; signalName: "chosen" }
    function init() {
        failOnWarning(/.*/);
        editor.begin({label:"Custom",icon:"terminal",command:["printf","hello world"]},[],0,[]);
        chosen.clear();
        verify(waitForRendering(editor));
    }
    function test_local_image_path_is_saved_with_literal_arguments() {
        var field = findChild(editor,"orb-action-icon-path"); verify(field);
        mouseClick(field); field.text = iconPath; field.textEdited();
        editor.apply();
        compare(chosen.count,1);
        compare(chosen.signalArguments[0][0].icon,iconPath);
        compare(chosen.signalArguments[0][0].command[1],"hello world");
    }
    function test_remote_image_is_rejected() {
        var field = findChild(editor,"orb-action-icon-path");
        mouseClick(field); field.text = "https://example.com/icon.png"; field.textEdited();
        editor.apply(); compare(chosen.count,0); verify(editor.error.length > 0);
    }
    function test_submenu_image_survives_editing() {
        editor.begin({label:"Tools",icon:iconPath,children:[{label:"Command",icon:"terminal",command:["true"]}]},[],0,[]);
        editor.actionLabel = "My tools"; editor.apply();
        compare(chosen.count,1); compare(chosen.signalArguments[0][0].icon,iconPath);
        compare(chosen.signalArguments[0][0].children.length,1);
    }
}
