import QtQuick
import QtTest
import "../.." as Orb

TestCase {
    name: "OrbSettingsPanel"
    visible: true; width: 800; height: 900; when: windowShown
    property var savedDraft: null
    Orb.SettingsPanel {
        id: panel
        width: 744; maximumHeight: 850
        onSaveRequested: savedDraft = draft()
    }
    SignalSpy { id: saved; target: panel; signalName: "saveRequested" }
    function init() {
        failOnWarning(/.*/);
        var actions = [0,1,2,3,4].map(function(i) { return {label:"App " + i,icon:"terminal",command:["true"]}; });
        panel.begin({diameter:240,animation:true,actions:actions,activeWheel:"everyday",wheels:[{id:"everyday",name:"Everyday",actions:actions}]},[]);
        savedDraft = null; saved.clear();
        verify(waitForRendering(panel));
        panel.selectTab(4);
        verify(waitForRendering(panel));
    }
    function test_ctrl_s_commits_focused_wheel_name() {
        var field = findChild(panel,"orb-wheel-name-everyday"); verify(field);
        mouseClick(field); field.selectAll();
        keyClick(Qt.Key_C); keyClick(Qt.Key_O); keyClick(Qt.Key_D); keyClick(Qt.Key_E);
        verify(field.activeFocus); compare(field.text.toLowerCase(),"code");
        keyClick(Qt.Key_S,Qt.ControlModifier);
        compare(saved.count,1);
        compare(savedDraft.wheels[0].name.toLowerCase(),"code");
    }
}
