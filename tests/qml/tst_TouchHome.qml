import QtQuick
import QtTest
import "../.." as Orb

TestCase {
    id: tests
    name: "OrbTouchHome"
    visible: true
    width: 800; height: 800
    when: windowShown
    QtObject {
        id: mockController
        property var config: ({touchEdge:"right",touchLayout:"ring",touchScale:1})
        property var wheelActions: [0,1,2,3,4,5].map(function(i) { return {label:"Action " + i,icon:"terminal"}; })
        property string submenuTitle: ""
        property int pageCount: 1
        property bool touchDismissAfter: false
        property string launched: ""
        property QtObject appLibrary: QtObject {
            function sortedEntries(query) { return ["Browser","Files"].filter(function(s) { return s.toLowerCase().indexOf(query.toLowerCase()) >= 0; }).map(function(s) { return {entry:{id:s,name:s,icon:""}}; }); }
            function entryName(entry) { return entry.name; }
            function iconSource(icon) { return ""; }
        }
        function appIconSource(action) { return ""; }
        function launchDesktop(entry) { launched = entry.id; }
        function activate(index) { launched = String(index); }
        function back() { submenuTitle = ""; }
        function turnPage(delta) {}
    }
    QtObject {
        id: mockBackend
        property bool busy: false
        property bool keyboardSpace: false
        property string error: ""
        property var last: []
        property var capabilities: ({audio:true,media:true,network:true,brightness:true,tabletEnabled:true})
        property var workspaces: [{id:1,name:"1"}]
        property var windows: [{address:"0xabc",title:"A real window",app:"Test",workspaceName:"1",hidden:false}]
        function run(args) { if (busy) return false; last = args; return true; }
        function keyboard(show) { keyboardSpace = show; }
        function refresh() {}
        function refreshWindows() {}
    }
    Orb.TouchHome { id: home; width: 744; height: 744; controller: mockController; backend: mockBackend; screenName: "eDP-1" }
    SignalSpy { id: dismissed; target: home; signalName: "dismissed" }
    function button(text, parent) {
        parent = parent || home;
        if (!parent.visible) return null;
        if (parent.text === text && typeof parent.clicked === "function") return parent;
        for (var i = 0; i < parent.children.length; i++) { var found = button(text, parent.children[i]); if (found) return found; }
        return null;
    }
    function tap(text) { var item = button(text); verify(item, "Missing button: " + text); mouseClick(item); }
    function init() {
        failOnWarning(/.*/);
        home.width = 744; home.height = 744;
        mockBackend.last = []; mockBackend.busy = false; mockBackend.keyboardSpace = false; mockBackend.error = "";
        mockController.touchDismissAfter = false; mockController.launched = ""; mockController.submenuTitle = "";
        dismissed.clear(); home.reset(); verify(waitForRendering(home));
    }
    function test_navigation_and_search() {
        tap("Apps"); compare(home.page,"apps"); compare(home.appRows.length,2);
        var search = findChild(home,"orb-touch-search"); verify(search); verify(search.height >= 48);
        mouseClick(search); tryCompare(mockBackend,"keyboardSpace",true);
        [Qt.Key_F,Qt.Key_I,Qt.Key_L,Qt.Key_E,Qt.Key_S].forEach(function(key) { keyClick(key); }); compare(home.appRows.length,1);
        compare(home.appRows[0].entry.id,"Files");
        tap("Back"); compare(home.page,"home"); tap("Close"); compare(dismissed.count,1);
    }
    function test_close_requires_confirmation() {
        tap("Windows");
        var close = findChild(home,"orb-touch-close-0xabc"); verify(close);
        mouseClick(close); compare(mockBackend.last.length,0); compare(home.pendingClose,"0xabc");
        tap("Confirm close"); compare(mockBackend.last.join("|"),"window|close|0xabc");
        compare(home.pendingClose,"");
    }
    function test_window_focus_and_busy_action() {
        tap("Windows"); tap("A real window");
        compare(mockBackend.last.join("|"),"window|focus|0xabc|eDP-1"); verify(mockController.touchDismissAfter);
        mockController.touchDismissAfter = false; mockBackend.busy = true;
        tap("A real window"); verify(!mockController.touchDismissAfter);
    }
    function test_small_view_keeps_navigation_and_keyboard() {
        home.width = 320; home.height = 440; verify(waitForRendering(home));
        tap("Controls"); compare(home.page,"controls");
        tap("Keyboard"); verify(mockBackend.keyboardSpace); tap("Hide keys"); verify(!mockBackend.keyboardSpace);
        tap("Back"); compare(home.page,"home");
    }
}
