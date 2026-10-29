import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import qs.Commons as Commons

Column {
    id: options
    property string inputMode: "desktop"
    property string touchEdge: "right"
    property string touchLayout: "fan"
    property real touchPosition: 0.7
    property real touchScale: 1
    property string touchOutput: ""
    property string touchKeyboard: "auto"
    property bool touchDrag: false
    property bool busy: false
    property var status: ({})
    spacing: 12
    function begin(config) {
        inputMode = config.inputMode || "desktop"; touchEdge = config.touchEdge || "right";
        touchLayout = config.touchLayout || "fan"; touchPosition = config.touchPosition === undefined ? 0.7 : config.touchPosition;
        touchScale = config.touchScale || 1; touchOutput = config.touchOutput || "";
        touchKeyboard = config.touchKeyboard || "auto"; touchDrag = config.touchDrag === true;
    }
    function draft() { return {inputMode: inputMode, touchEdge: touchEdge, touchLayout: touchLayout,
        touchPosition: touchPosition, touchScale: touchScale, touchOutput: touchOutput,
        touchKeyboard: touchKeyboard, touchDrag: touchDrag}; }
    EditorLabel { text: "Interface"; font.pixelSize: 18 }
    Row {
        width: parent.width; spacing: 6
        Repeater {
            model: [{id:"desktop",name:"Desktop"},{id:"touch",name:"Touch"},{id:"auto",name:"Automatic"}]
            delegate: TouchButton { required property var modelData; width: (options.width - 12) / 3; text: modelData.name; selected: options.inputMode === modelData.id; enabled: !options.busy; onClicked: options.inputMode = modelData.id }
        }
    }
    EditorLabel {
        width: parent.width; wrapMode: Text.WordWrap; opacity: 0.7
        text: inputMode === "auto" ? status.tabletEnabled && status.hasFoldSensor ? "Orb follows the reported fold state. Opening your laptop restores Desktop mode." : "Automatic needs an enabled Tablet Mode plugin and a working fold sensor. Use Touch for an iPad or a tablet without a fold switch."
            : inputMode === "touch" ? "Keep the edge button available. Your desktop shortcuts remain available." : "Use the desktop wheel. Touch mode can still be opened from Orb’s bar button."
    }
    EditorLabel { text: "Touch display" }
    Flow {
        width: parent.width; spacing: 6
        TouchButton { text: "Automatic"; selected: options.touchOutput === ""; enabled: !options.busy; onClicked: options.touchOutput = "" }
        Repeater {
            model: Quickshell.screens
            delegate: TouchButton { required property var modelData; text: modelData.name; selected: options.touchOutput === modelData.name; enabled: !options.busy; onClicked: options.touchOutput = modelData.name }
        }
    }
    EditorLabel { width: parent.width; wrapMode: Text.WordWrap; opacity: 0.65; text: "Automatic selects the single internal display, or the only connected display. Choose explicitly when more than one display could be the tablet." }
    Row {
        width: parent.width; spacing: 6
        TouchButton { width: (parent.width - 6) / 2; text: "Left hand"; selected: options.touchEdge === "left"; enabled: !options.busy; onClicked: options.touchEdge = "left" }
        TouchButton { width: (parent.width - 6) / 2; text: "Right hand"; selected: options.touchEdge === "right"; enabled: !options.busy; onClicked: options.touchEdge = "right" }
    }
    Row {
        width: parent.width; spacing: 6
        TouchButton { width: (parent.width - 6) / 2; text: "Edge fan"; selected: options.touchLayout === "fan"; enabled: !options.busy; onClicked: options.touchLayout = "fan" }
        TouchButton { width: (parent.width - 6) / 2; text: "Full wheel"; selected: options.touchLayout === "ring"; enabled: !options.busy; onClicked: options.touchLayout = "ring" }
    }
    EditorLabel { text: "Button height" }
    Controls.Slider { width: parent.width; height: 48; from: 0; to: 1; stepSize: 0.05; value: options.touchPosition; enabled: !options.busy; onMoved: options.touchPosition = value; Accessible.name: "Orb button height" }
    EditorLabel { text: "Touch target size" }
    Controls.Slider { width: parent.width; height: 48; from: 1; to: 1.5; stepSize: 0.1; value: options.touchScale; enabled: !options.busy; onMoved: options.touchScale = value; Accessible.name: "Touch target size" }
    TouchButton { width: parent.width; text: options.touchDrag ? "Drag selection: on" : "Drag selection: off"; selected: options.touchDrag; enabled: !options.busy; onClicked: options.touchDrag = !options.touchDrag }
    EditorLabel { width: parent.width; wrapMode: Text.WordWrap; opacity: 0.65; text: "Tap selects an action. Optional drag selection launches on release over a target; release in empty space to cancel. Hold a favourite to edit it." }
    EditorLabel { text: "On-screen keyboard"; font.pixelSize: 18 }
    Flow {
        width: parent.width; spacing: 6
        Repeater {
            model: [{id:"auto",name:"Automatic"},{id:"omatouch",name:"OmaTouch"},{id:"tablet",name:"Tablet Mode"}]
            delegate: TouchButton { required property var modelData; text: modelData.name; selected: options.touchKeyboard === modelData.id; enabled: !options.busy; onClicked: options.touchKeyboard = modelData.id }
        }
    }
    EditorLabel {
        width: parent.width; wrapMode: Text.WordWrap; opacity: 0.7
        text: status.keyboardReady ? "An enabled keyboard is available. Orb opens it for its own text fields; use Keyboard for other apps."
            : "Enable OmaTouch and install its wtype dependency, or configure a keyboard supported by Tablet Mode. Orb does not install these automatically."
    }
    EditorLabel { width: parent.width; wrapMode: Text.WordWrap; opacity: 0.7; text: "Rotation and hardware input changes stay with Tablet Mode. Secure touch unlock needs lock-screen support. This setting does not make hardware drivers or authentication work on an untested device." }
}
