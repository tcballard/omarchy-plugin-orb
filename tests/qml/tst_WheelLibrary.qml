import QtQuick
import QtTest
import "../.." as Orb
TestCase {
    name: "OrbWheelLibrary"
    visible: true; width: 800; height: 1200; when: windowShown
    Orb.WheelLibrary { id: library; width: 700 }
    function init() {
        failOnWarning(/.*/);
        var actions = [0,1,2,3,4].map(function(i) { return {label:"App " + i,icon:"terminal",command:["true"]}; });
        library.begin({actions:actions,activeWheel:"everyday",wheels:[{id:"everyday",name:"Everyday",actions:actions}],setups:[]});
        library.currentActions = actions;
    }
    function test_duplicate_and_rename_are_drafts() {
        library.newName = "Code"; library.addWheel(); compare(library.wheels.length,2);
        compare(library.activeWheel,"everyday"); compare(library.wheels[1].name,"Code");
        library.rename(1,"Travel"); compare(library.wheels[1].name,"Travel"); compare(library.wheels[0].name,"Everyday");
    }
    function test_rename_keeps_focus_until_commit() {
        var field = findChild(library,"orb-wheel-name-everyday"); verify(field);
        mouseClick(field); field.selectAll(); keyClick(Qt.Key_C); verify(field.activeFocus);
        keyClick(Qt.Key_O); verify(field.activeFocus); compare(field.text.toLowerCase(),"co");
        compare(library.wheels[0].name,"Everyday"); library.forceActiveFocus();
        tryCompare(library,"activeFocus",true); compare(library.wheels[0].name.toLowerCase(),"co");
    }
    function test_setup_retains_app_order_and_layout() {
        library.setupName = "Work"; library.selectedApps = ["org.test.One","org.test.Two"]; library.workspace = 4; library.layout = "columns";
        library.addSetup(); compare(library.setups.length,1); compare(library.setups[0].workspace,4);
        compare(library.setups[0].apps.join("|"),"org.test.One|org.test.Two"); compare(library.setups[0].layout,"columns"); compare(library.selectedApps.length,0);
    }
    function test_rename_then_use_another_wheel() {
        library.newName = "Media"; library.addWheel();
        verify(waitForRendering(library));
        var field = findChild(library,"orb-wheel-name-everyday"); verify(field);
        mouseClick(field); field.selectAll(); keyClick(Qt.Key_C); keyClick(Qt.Key_O);
        var row = findChild(library,"orb-wheel-name-" + library.wheels[1].id).parent;
        mouseClick(row.children[0]);
        compare(library.activeWheel,library.wheels[1].id);
    }
    function test_removing_a_wheel_retains_the_next_wheels_identity() {
        library.newName = "Media"; library.addWheel();
        library.newName = "Travel"; library.addWheel();
        verify(waitForRendering(library));
        var media = library.wheels[1].id, travel = library.wheels[2].id;
        var mediaRow = findChild(library,"orb-wheel-name-" + media).parent.parent;
        mouseClick(mediaRow.children[1].children[1]);
        compare(library.wheels.length,2); verify(waitForRendering(library));
        var travelName = findChild(library,"orb-wheel-name-" + travel); verify(travelName);
        compare(travelName.text,"Travel"); mouseClick(travelName.parent.children[0]);
        compare(library.activeWheel,travel);
    }
}
