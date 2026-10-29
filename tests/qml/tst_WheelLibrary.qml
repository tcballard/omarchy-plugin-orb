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
    function test_setup_retains_app_order_and_layout() {
        library.setupName = "Work"; library.selectedApps = ["org.test.One","org.test.Two"]; library.workspace = 4; library.layout = "columns";
        library.addSetup(); compare(library.setups.length,1); compare(library.setups[0].workspace,4);
        compare(library.setups[0].apps.join("|"),"org.test.One|org.test.Two"); compare(library.setups[0].layout,"columns"); compare(library.selectedApps.length,0);
    }
}
