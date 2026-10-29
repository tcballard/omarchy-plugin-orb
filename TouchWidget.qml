import QtQuick
import Quickshell
import qs.Commons as Commons
import qs.Ui

BarWidget {
    id: widget
    property var shell: null
    property var manifest: null
    property string omarchyPath: ""
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    Button {
        id: button
        text: "Orb"; focusable: true
        tooltipText: "Open Orb touch navigation"
        onClicked: {
            var screen = widget.QsWindow.window ? widget.QsWindow.window.screen : null;
            if (widget.shell) widget.shell.toggle("io.github.tcballard.orb", JSON.stringify({touch:true,output:screen ? screen.name : ""}));
        }
    }
}
