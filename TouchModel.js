function active(mode, status) {
    return mode === "touch" || (mode === "auto" && status && status.ok === true
        && status.tabletEnabled === true && status.hasFoldSensor === true && status.folded === true);
}
function output(preferred, screens) {
    var available = screens.filter(function(s) { return s && s.name && s.width > 0 && s.height > 0; });
    if (preferred) return available.find(function(s) { return s.name === preferred; }) || null;
    var internal = available.filter(function(s) { return /^(eDP|DSI|LVDS)-/.test(s.name); });
    return internal.length === 1 ? internal[0] : available.length === 1 ? available[0] : null;
}
function layout(width, height, count, edge, shape, scale) {
    var size = Math.round(76 * (scale || 1)), gap = 12, points = [], radius;
    if (!count || width <= 0 || height <= 0) return { points: points, size: size, grid: true };
    if (shape === "ring") {
        radius = Math.max(size * 1.35, Math.SQRT2 * (size + gap) / (2 * Math.sin(Math.PI / count)));
        if (radius * 2 + size + gap <= Math.min(width, height)) {
            for (var i = 0; i < count; i++) {
                var angle = -Math.PI / 2 + i * Math.PI * 2 / count;
                points.push({ x: width / 2 + Math.cos(angle) * radius, y: height / 2 + Math.sin(angle) * radius });
            }
            return { points: points, size: size, grid: false, centre: { x: width / 2, y: height / 2 } };
        }
    } else {
        radius = Math.max(size * 1.6, Math.SQRT2 * (size + gap) / (2 * Math.sin(Math.PI / (2 * Math.max(1, count - 1)))));
        if (radius + size + gap <= width && radius * 2 + size + gap <= height) {
            var cx = edge === "left" ? size / 2 + gap : width - size / 2 - gap;
            for (var j = 0; j < count; j++) {
                var a = -Math.PI / 2 + j * Math.PI / Math.max(1, count - 1);
                points.push({ x: cx + (edge === "left" ? 1 : -1) * Math.cos(a) * radius, y: height / 2 + Math.sin(a) * radius });
            }
            return { points: points, size: size, grid: false, centre: { x: cx, y: height / 2 } };
        }
    }
    return { points: [], size: size, grid: true };
}
function hit(x, y, geometry) {
    for (var i = 0; i < geometry.points.length; i++) {
        var p = geometry.points[i];
        if (Math.abs(x - p.x) <= geometry.size / 2 && Math.abs(y - p.y) <= geometry.size / 2) return i;
    }
    return -1;
}
function press(x, y, geometry) {
    return { x: x, y: y, first: hit(x, y, geometry), selected: hit(x, y, geometry), moved: false, held: false };
}
function move(state, x, y, geometry) {
    if (!state) return null;
    return Object.assign({}, state, { selected: hit(x, y, geometry), moved: state.moved || Math.hypot(x - state.x, y - state.y) > 12 });
}
function release(state, x, y, geometry, drag) {
    if (!state || state.held) return -1;
    var end = move(state, x, y, geometry);
    return end.selected >= 0 && ((drag && end.moved) || (!end.moved && end.first === end.selected)) ? end.selected : -1;
}
function windows(rows) {
    if (!Array.isArray(rows) || rows.length > 2048) throw new Error("Invalid window list");
    return rows.filter(function(w) { return w && /^0x[0-9a-fA-F]+$/.test(w.address) && w.mapped !== false; })
        .map(function(w) { return { address: w.address, title: String(w.title || w.class || "Window").slice(0, 240),
            app: String(w.class || "").slice(0, 100), workspace: w.workspace && Number(w.workspace.id) || 0,
            workspaceName: String(w.workspace && w.workspace.name || "").slice(0, 80),
            monitor: Number(w.monitor), hidden: w.hidden === true || (w.workspace && w.workspace.name === "special:minimized"), order: Number(w.focusHistoryID) || 0 }; })
        .sort(function(a, b) { return a.order - b.order; });
}
if (typeof module !== "undefined") module.exports = { active: active, output: output, layout: layout, hit: hit, press: press, move: move, release: release, windows: windows };
