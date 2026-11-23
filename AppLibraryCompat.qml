import QtQuick
import Quickshell
import Quickshell.Io

// Omarchy 4.0.6 can inject a null appLibrary for a menu because its panel
// model converts manifest.kinds to a QVariantList. Prefer the native service;
// otherwise use the desktop-entry index and the same gtk-launch handoff.
Item {
    id: library
    property var nativeLibrary: null
    property string omarchyPath: ""
    readonly property bool fallback: !nativeLibrary
    readonly property var applications: fallback ? DesktopEntries.applications.values : []
    property var configuredHidden: ({})
    property var desktopHidden: ({})
    signal appsChanged
    onApplicationsChanged: appsChanged()
    onNativeLibraryChanged: appsChanged()

    function hiddenIds(text) {
        var result = {};
        String(text).split(/\n/).forEach(function (line) {
            var id = line.trim().replace(/\.desktop$/, "");
            if (id)
                result[id] = true;
        });
        return result;
    }
    function entryName(entry) {
        return nativeLibrary ? nativeLibrary.entryName(entry) : String(entry.name || entry.id || "");
    }
    function entrySubtext(entry) {
        return nativeLibrary ? nativeLibrary.entrySubtext(entry) : String(entry.genericName || "");
    }
    function sortedEntries(query) {
        if (nativeLibrary)
            return nativeLibrary.sortedEntries(query);
        var filter = String(query || "").toLowerCase(), rows = [];
        for (var i = 0; i < applications.length; i++) {
            var entry = applications[i], id = String(entry.id || "");
            if (entry.noDisplay || configuredHidden[id] || desktopHidden[id])
                continue;
            var name = entryName(entry);
            if (name && (name + " " + entrySubtext(entry) + " " + id).toLowerCase().indexOf(filter) >= 0)
                rows.push({
                              entry: entry,
                              key: name.toLowerCase()
                          });
        }
        rows.sort(function (a, b) {
            return a.key < b.key ? -1 : a.key > b.key ? 1 : 0;
        });
        return rows;
    }
    function iconSource(icon) {
        if (nativeLibrary)
            return nativeLibrary.iconSource(icon);
        var value = String(icon || "");
        if (/^(file|image):\/\//.test(value))
            return value;
        if (value.charAt(0) === "/")
            return "file://" + value.split("/").map(encodeURIComponent).join("/");
        return Quickshell.iconPath(value, true) || Quickshell.iconPath("application-x-executable", true);
    }
    function refreshIcons() {
        if (nativeLibrary)
            nativeLibrary.refreshIcons();
    }
    function launch(desktopId, name) {
        if (nativeLibrary) {
            nativeLibrary.launch(desktopId, name);
            return;
        }
        if (/^[A-Za-z0-9_.@+-]{1,255}$/.test(desktopId))
            Quickshell.execDetached(["setsid", "uwsm-app", "--", "gtk-launch", desktopId + ".desktop"]);
    }
    Connections {
        target: library.nativeLibrary
        function onAppsChanged() {
            library.appsChanged();
        }
    }
    FileView {
        path: library.fallback && library.omarchyPath ? library.omarchyPath + "/default/omarchy/launcher.hides" : ""
        watchChanges: true
        printErrors: false
        onLoaded: {
            library.configuredHidden = library.hiddenIds(text());
            library.appsChanged();
        }
        onFileChanged: reload()
    }
    Process {
        id: hiddenScan
        running: library.fallback && library.omarchyPath !== ""
        command: ["bash", library.omarchyPath + "/shell/services/hidden-entries.sh", [Quickshell.env(
                                                                                          "XDG_CURRENT_DESKTOP"),
                                                                                      Quickshell.env(
                                                                                          "XDG_SESSION_DESKTOP"),
                                                                                      Quickshell.env(
                                                                                          "DESKTOP_SESSION")].filter(
                function (v) {
                    return !!v;
                }).join(":")]
        stdout: StdioCollector {
            onStreamFinished: {
                library.desktopHidden = library.hiddenIds(text);
                library.appsChanged();
            }
        }
    }
    Connections {
        target: DesktopEntries.applications
        enabled: library.fallback
        function onValuesChanged() {
            if (!hiddenScan.running)
                hiddenScan.running = true;
        }
    }
}
