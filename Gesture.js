function parse(data, owner) {
    var text = String(data || "");
    var match = /^orb\/([0-9]+-[0-9]+)\/(press|move|release|cancel)\/(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)\/(\d{1,5})$/.exec(text);
    if (!match || match[0] !== text || match[1] !== owner) return null;
    var x = Number(match[3]), y = Number(match[4]);
    if (!isFinite(x) || !isFinite(y) || Math.abs(x) > 1000000 || Math.abs(y) > 1000000) return null;
    var elapsed = Number(match[5]);
    if (elapsed > 6000) return null;
    return { type: match[2], x: x, y: y, elapsed: elapsed };
}
function begin(event) {
    return { x: event.x, y: event.y, currentX: event.x, currentY: event.y,
        moved: false, released: false, elapsed: 0 };
}
function update(state, event) {
    if (!state || state.released || (event.type !== "move" && event.type !== "release")) return state;
    var dx = event.x - state.x, dy = event.y - state.y;
    return { x: state.x, y: state.y, currentX: event.x, currentY: event.y,
        moved: state.moved || dx * dx + dy * dy >= 144,
        released: event.type === "release", elapsed: event.elapsed };
}
function outcome(state) {
    if (!state || !state.released) return "pending";
    if (!state.moved) return state.elapsed <= 250 ? "tap" : "cancel";
    return "select";
}
if (typeof module !== "undefined") module.exports = { parse: parse, begin: begin, update: update, outcome: outcome };
