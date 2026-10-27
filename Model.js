// Pure geometry and validation, shared by the hosted QML and Node tests.
var icons = ["browser", "terminal", "files", "screenshot", "themes", "plugins", "agents", "settings", "codex", "claude", "grok", "postcard", "app", "create",
    "home", "recent", "starred", "downloads", "documents", "pictures", "music", "videos", "trash",
    "search", "link", "code", "calendar", "clock", "mail", "lock", "power", "cloud", "bookmark"];
function validIcon(value) {
    return typeof value === "string" && (icons.indexOf(value) >= 0 ||
        (value.length <= 4096 && /^\/[^\x00-\x1f]*\.(svg|png|jpe?g|webp)$/i.test(value)));
}
function iconUrl(value) {
    return validIcon(value) && value.charAt(0) === "/"
        ? "file://" + value.split("/").map(encodeURIComponent).join("/") : "";
}
function fileActions(helper) {
    return ["Home", "Recent", "Starred", "Downloads", "Documents", "Pictures", "Music", "Videos", "Trash"].map(function(label) {
        var id = label.toLowerCase();
        return { label: label, icon: id, command: ["bash", helper, id] };
    });
}
function shortcut(value) {
    if (value === undefined) value = "SUPER + ALT + O";
    if (typeof value !== "string") return { error: "Choose a Super shortcut with one key." };
    var parts = value.toUpperCase().split("+"), mask = 0, key = "";
    var bits = { SUPER: 64, CTRL: 4, ALT: 8, SHIFT: 1 };
    for (var i = 0; i < parts.length; i++) {
        var token = parts[i].replace(/\s/g, "");
        if (key) return { error: "Put the key after the shortcut modifiers." };
        if (bits[token]) {
            if (mask & bits[token]) return { error: "Use each shortcut modifier once." };
            mask |= bits[token];
        } else if (/^([A-Z0-9]|F[1-9]|F1[0-2]|SPACE)$/.test(token)) key = token;
        else return { error: "Use a letter, number, F1–F12 or Space as the key." };
    }
    if (!(mask & 64) || !key) return { error: "Choose a Super shortcut with one key." };
    var canonical = ["SUPER", "CTRL", "ALT", "SHIFT"].filter(function(p) { return mask & bits[p]; });
    canonical.push(key);
    return { value: canonical.join(" + "), key: key, mask: mask, error: "" };
}
function mouseButton(value) {
    if (value === undefined || value === null) return { value: 277, error: "" };
    if (typeof value === "string") {
        if (!/^\d{3}$/.test(value)) return { error: "Use an extra mouse button code from 275 to 511.", value: 277 };
        value = Number(value);
    }
    if (!Number.isInteger(value) || value < 275 || value > 511)
        return { error: "Use an extra mouse button code from 275 to 511.", value: 277 };
    return { value: value, error: "" };
}
function bindingSignature(document) {
    document = document || {};
    var mouseOpen = document.mouseOpen === true;
    var mouse = mouseButton(document.mouseButton);
    return [document.shortcut || "SUPER + ALT + O", document.desktopRightClick === true, mouseOpen, mouseOpen ? (mouse.error ? 0 : mouse.value) : 0];
}
function activationConflict(desktopRightClick, mouseOpen, mouseCode) {
    var mouse = mouseButton(mouseCode);
    if (mouse.error) return mouse.error;
    if (mouseOpen && desktopRightClick && mouse.value === 273)
        return "Mouse code 273 is the desktop right-click. Turn one of them off or choose another code.";
    return "";
}
function bindingConflict(binds, value, desktopRightClick, mouseOpen, mouseCode) {
    var checked = shortcut(value);
    if (checked.error) return checked.error;
    var clash = mouseOpen ? activationConflict(desktopRightClick, true, mouseCode) : "";
    if (clash) return clash;
    if (!Array.isArray(binds)) return "Could not check existing shortcuts. Try saving again.";
    var mouse = mouseOpen ? mouseButton(mouseCode).value : 0;
    for (var i = 0; i < binds.length; i++) {
        var b = binds[i], description = String(b.description || "");
        var ownMouse = description.indexOf("Orb mouse button [orb:") === 0;
        var ownDesktop = description.indexOf("Orb on empty desktop [orb:") === 0;
        if (String(b.key).toUpperCase() === checked.key && b.modmask === checked.mask
            && description.indexOf("Orb shortcut wheel [orb:") !== 0)
            return checked.value + " is already in use. Choose another shortcut.";
        // The other Orb bind is removed in this same save, so it is not a conflict.
        // Any other bind on the mouse key is a conflict: remove() clears the whole key.
        if (desktopRightClick && b.key === "mouse:273" && b.modmask === 0 && !ownDesktop
            && !(ownMouse && (!mouseOpen || mouse !== 273)))
            return "Desktop right-click is already in use. Turn it off or change the existing binding.";
        if (mouseOpen && b.key === "mouse:" + mouse && !ownMouse && !(ownDesktop && !desktopRightClick))
            return "Mouse code " + mouse + " is already in use. Choose another code or turn the mouse button off.";
    }
    return "";
}
function move(items, from, to) {
    var copy = items.slice();
    if (from < 0 || to < 0 || from >= copy.length || to >= copy.length) return copy;
    copy.splice(to, 0, copy.splice(from, 1)[0]);
    return copy;
}
function action(a, depth) {
    if (!a || typeof a.label !== "string" || !a.label.trim() || a.label.length > 20 || !validIcon(a.icon)) return null;
    var out = { label: a.label.trim(), icon: a.icon };
    if (a.desktopId !== undefined) {
        if (typeof a.desktopId !== "string" || !/^[A-Za-z0-9_.@+-]{1,255}$/.test(a.desktopId) || a.command || a.menu || a.children) return null;
        out.desktopId = a.desktopId; return out;
    }
    // Upgrade only the original top-level Files shortcut. Custom paths, app
    // entries and commands inside user submenus keep their existing behaviour.
    if (depth === 0 && a.label === "Files" && a.icon === "files" && !a.menu && !a.children
        && JSON.stringify(a.command) === '["omarchy","launch","nautilus"]') {
        out.menu = "files"; return out;
    }
    if ((a.menu === "agents" || a.menu === "files") && depth === 0 && !a.command && !a.children) { out.menu = a.menu; return out; }
    if (Array.isArray(a.children) && depth === 0 && !a.command && !a.menu && a.children.length > 0 && a.children.length <= 12) {
        out.children = a.children.map(function(c) { return action(c, 1); });
        return out.children.every(function(c) { return c !== null; }) ? out : null;
    }
    if (a.children || a.menu || !Array.isArray(a.command) || a.command.length < 1 || a.command.length > 32
        || a.command.some(function(s) { return typeof s !== "string" || s.length > 4096 || s.indexOf("\u0000") >= 0; }) || !a.command[0]) return null;
    out.command = a.command.slice(); return out;
}
// Merge only edited fields/slots into the latest document. Preserve custom fields
// and concurrent edits elsewhere; refuse to overwrite a conflicting slot.
function mergeAction(document, original, draft, childOrigins) {
    // Keep user metadata when an action moves or its editable fields change.
    var result = JSON.parse(JSON.stringify(document || {}));
    ["label", "icon", "command", "desktopId", "menu", "children"].forEach(function(k) { delete result[k]; });
    Object.keys(draft).forEach(function(k) { result[k] = draft[k]; });
    if (draft.children && original && original.children && document.children) {
        var used = [];
        result.children = draft.children.map(function(child, i) {
            var origin = childOrigins ? childOrigins[i] : -1;
            if (!childOrigins) for (var j = 0; j < original.children.length; j++) {
                if (!used[j] && JSON.stringify(child) === JSON.stringify(original.children[j])) { origin = j; break; }
            }
            if (origin < 0 || origin >= original.children.length) return child;
            used[origin] = true;
            return mergeAction(document.children[origin], original.children[origin], child);
        });
    }
    return result;
}
function mergeSettings(document, original, draft) {
    var result = JSON.parse(JSON.stringify(document));
    var current = parse(JSON.stringify(document), null);
    if (current.error) return { error: current.error };
    if (draft.actionOrigins) {
        var order = draft.actionOrigins;
        if (order.length !== draft.actions.length || order.some(function(n, i) {
            return !Number.isInteger(n) || n < -1 || n >= original.actions.length || (n >= 0 && order.indexOf(n) !== i);
        })) return { error: "Invalid shortcut arrangement. Reopen settings." };
        var structural = order.length !== original.actions.length || order.some(function(n, i) { return n !== i; });
        if (structural && JSON.stringify(current.config.actions) !== JSON.stringify(original.actions))
            return { error: "Slots changed elsewhere. Reopen settings before rearranging them." };
        for (var slot = 0; slot < draft.actions.length; slot++) {
            var origin = order[slot], edited = origin < 0 || JSON.stringify(original.actions[origin]) !== JSON.stringify(draft.actions[slot]);
            if (!structural && edited && (current.config.actions.length !== original.actions.length
                || (JSON.stringify(current.config.actions[origin]) !== JSON.stringify(original.actions[origin])
                && JSON.stringify(current.config.actions[origin]) !== JSON.stringify(draft.actions[slot]))))
                return { error: "Slot " + (slot + 1) + " changed elsewhere. Reopen settings to load it." };
        }
        if (structural) result.actions = [];
        draft.actions.forEach(function(a, i) {
            var origin = order[i];
            if (!structural && JSON.stringify(a) === JSON.stringify(original.actions[i])) return;
            result.actions[i] = origin < 0 ? a : mergeAction(document.actions[origin], original.actions[origin], a, (draft.childOrigins || [])[i]);
        });
    } else if (draft.actions.length !== original.actions.length) {
        if (JSON.stringify(current.config.actions) !== JSON.stringify(original.actions))
            return { error: "Slots changed elsewhere. Reopen settings before adding or removing slots." };
        var used = [];
        result.actions = draft.actions.map(function(a) {
            for (var index = 0; index < original.actions.length; index++) {
                if (!used[index] && JSON.stringify(a) === JSON.stringify(original.actions[index])) {
                    used[index] = true; return document.actions[index];
                }
            }
            return a;
        });
    } else for (var i = 0; i < original.actions.length; i++) {
        if (JSON.stringify(original.actions[i]) === JSON.stringify(draft.actions[i])) continue;
        if (current.config.actions.length !== original.actions.length)
            return { error: "Slots changed elsewhere. Reopen settings to load them." };
        if (JSON.stringify(current.config.actions[i]) !== JSON.stringify(original.actions[i]) && JSON.stringify(current.config.actions[i]) !== JSON.stringify(draft.actions[i]))
            return { error: "Slot " + (i + 1) + " changed elsewhere. Reopen settings to load it." };
        result.actions[i] = draft.actions[i];
    }
    var fields = ["diameter", "animation", "shape", "shortcut", "desktopRightClick", "mouseOpen", "mouseButton"];
    for (var field = 0; field < fields.length; field++) {
        var name = fields[field];
        if (draft[name] === undefined || original[name] === draft[name]) continue;
        if (current.config[name] !== original[name] && current.config[name] !== draft[name])
            return { error: "The " + name + " setting changed elsewhere. Reopen settings to load it." };
        result[name] = draft[name];
    }
    var checked = parse(JSON.stringify(result), null);
    return checked.error ? { error: checked.error } : { document: result, error: "" };
}
function parse(raw, fallback) {
    var value;
    try { value = JSON.parse(raw); } catch (error) { return { config: fallback, error: "Invalid JSON; using the last valid configuration." }; }
    if (!value || typeof value !== "object" || !Array.isArray(value.actions) || value.actions.length < 5 || value.actions.length > 8)
        return { config: fallback, error: "Orb supports five to eight top-level actions." };
    var actions = [];
    for (var i = 0; i < value.actions.length; i++) {
        var a = action(value.actions[i], 0);
        if (!a)
            return { config: fallback, error: "Invalid action " + (i + 1) + "; using the last valid configuration." };
        actions.push(a);
    }
    var activation = shortcut(value.shortcut);
    if (activation.error) return { config: fallback, error: activation.error };
    if (value.desktopRightClick !== undefined && typeof value.desktopRightClick !== "boolean")
        return { config: fallback, error: "Desktop right-click must be on or off." };
    if (value.mouseOpen !== undefined && typeof value.mouseOpen !== "boolean")
        return { config: fallback, error: "Mouse button must be on or off." };
    var mouse = mouseButton(value.mouseButton);
    if (mouse.error) return { config: fallback, error: mouse.error };
    var mouseOpen = value.mouseOpen === true;
    var clash = activationConflict(value.desktopRightClick === true, mouseOpen, mouse.value);
    if (clash) return { config: fallback, error: clash };
    if (value.shape !== undefined && value.shape !== "circle" && value.shape !== "polygon")
        return { config: fallback, error: "Choose a circle or polygon wheel." };
    return { config: { actions: actions, diameter: Math.max(220, Math.min(600, Number(value.diameter) || 240)), animation: value.animation !== false,
        shape: value.shape || "circle", shortcut: activation.value, desktopRightClick: value.desktopRightClick === true,
        mouseOpen: mouseOpen, mouseButton: mouse.value }, error: "" };
}
// Vertices align with actions; sector boundaries meet the middle of each edge.
// One/two-entry submenu pages retain a circle because no polygon exists there.
function edgeRadius(angle, diameter, count, shape, radius) {
    var outer = diameter * (radius === undefined ? 0.48 : radius);
    if (shape !== "polygon" || count < 3) return outer;
    var step = Math.PI * 2 / count;
    var offset = ((angle + Math.PI / 2) % step + step) % step - step / 2;
    return outer * Math.cos(step / 2) / Math.cos(offset);
}
function hit(x, y, diameter, count, shape) {
    if (count === undefined) count = 6;
    if (count < 1) return -1;
    var dx = x - diameter / 2, dy = y - diameter / 2;
    var r = Math.sqrt(dx * dx + dy * dy) / diameter;
    if (r < 0.18 || Math.sqrt(dx * dx + dy * dy) > edgeRadius(Math.atan2(dy, dx), diameter, count, shape) + 0.000001) return -1;
    var step = 360 / count;
    var angle = (Math.atan2(dy, dx) * 180 / Math.PI + 90 + step / 2 + 360) % 360;
    return Math.floor(angle / step) % count;
}
function placement(px, py, width, height, reserved, preferred) {
    var r = reserved || [0, 0, 0, 0], pad = 12, footer = 38;
    var left = r[0] + pad, top = r[1] + pad;
    var availableW = Math.max(1, width - r[0] - r[2] - pad * 2);
    var availableH = Math.max(1, height - r[1] - r[3] - pad * 2);
    var size = Math.max(1, Math.min(preferred, availableW, availableH - footer));
    if (size > 280) size = Math.min(size, availableH / (1 + footer / 280));
    var captionScale = Math.max(1, size / 280);
    footer *= captionScale;
    return { size: size, captionScale: captionScale, footer: footer,
        x: Math.max(left, Math.min(px - size / 2, left + availableW - size)),
        y: Math.max(top, Math.min(py - size / 2, top + availableH - size - footer)) };
}
if (typeof module !== "undefined") module.exports = { parse: parse, action: action, icons: icons, validIcon: validIcon, iconUrl: iconUrl, fileActions: fileActions, shortcut: shortcut, mouseButton: mouseButton, bindingSignature: bindingSignature, bindingConflict: bindingConflict, edgeRadius: edgeRadius,
    move: move, hit: hit, placement: placement, mergeSettings: mergeSettings };
