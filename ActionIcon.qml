import QtQuick
import Quickshell
import qs.Commons as Commons
import "Model.js" as Model

Item {
    id: icon
    property string name: "browser"
    property url appSource: ""
    property color ink: Commons.Color.menu.text
    property bool selected: false
    readonly property bool branded: Model.agentMarks.indexOf(name) >= 0
    // Agent marks come from the installed Omarchy's Agents panel, so new agents
    // follow Omarchy; Orb's bundled Codex/Claude/Grok copies cover older shells.
    // Like that panel, light surfaces try the <id>-light.svg twin first.
    readonly property var markSources: {
        if (!branded)
            return [];
        var names = lightSurface ? [name + "-light", name] : [name];
        var sources = [];
        var omarchy = Quickshell.env("OMARCHY_PATH") || "";
        if (omarchy.charAt(0) === "/")
            names.forEach(function (n) {
                var url = Model.iconUrl(omarchy + "/shell/plugins/agents/assets/" + n + ".svg");
                if (url)
                    sources.push(url);
            });
        if (name === "codex" || name === "claude" || name === "grok")
            names.forEach(function (n) {
                sources.push(Qt.resolvedUrl("assets/agents/" + n + ".svg"));
            });
        return sources;
    }
    property int markIndex: 0
    onMarkSourcesChanged: markIndex = 0
    // Native glyphs from Omarchy's Agents panel and Postcard's bar widget.
    readonly property string nativeGlyph: name === "themes" ? "󰏘" : name === "plugins" ? "󰐱" : name === "app" ? "󰣆" :
                                                                                                                name === "postcard"
                                                                                                                ? "󰆟" : ""
    readonly property color surface: Commons.Color.menu.background
    function linear(channel) {
        return channel <= 0.04045 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4);
    }
    readonly property bool lightSurface: 0.2126 * linear(surface.r) + 0.7152 * linear(surface.g) + 0.0722 * linear(
                                             surface.b) > 0.179

    Image {
        id: mark
        anchors.fill: parent
        visible: (icon.branded || icon.appSource.toString() !== "" || Model.iconUrl(icon.name) !== "") && status
                 === Image.Ready
        source: icon.appSource.toString() !== "" ? icon.appSource : Model.iconUrl(icon.name) !== "" ? Model.iconUrl(
                                                                                                          icon.name) :
                                                                                                      icon.markIndex
                                                                                                      < icon.markSources.length
                                                                                                      ? icon.markSources[icon.markIndex] :
                                                                                                        ""
        // A missing mark falls through to the next source, then the generic icon.
        onStatusChanged: if (status === Image.Error && icon.branded && icon.markIndex < icon.markSources.length)
                             icon.markIndex++
        sourceSize.width: Math.ceil(width * 2)
        sourceSize.height: Math.ceil(height * 2)
        fillMode: Image.PreserveAspectFit
    }
    Text {
        anchors.fill: parent
        visible: !mark.visible && icon.nativeGlyph !== ""
        text: icon.nativeGlyph
        textFormat: Text.PlainText
        font.family: Commons.Style.font.family
        font.pixelSize: height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: icon.selected ? "#ffffff" : icon.ink
    }
    LineIcon {
        anchors.fill: parent
        visible: !mark.visible && icon.nativeGlyph === ""
        name: icon.branded ? "agents" : icon.name
        ink: icon.selected ? "#ffffff" : icon.ink
    }
}
